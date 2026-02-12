import { type Plugin } from "@opencode-ai/plugin"
import { readFileSync, existsSync, readdirSync } from "fs"
import { join, resolve } from "path"
import { platform } from "os"
import { execSync } from "child_process"
import { spawn } from "child_process"

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface SoundConfig {
  theme: string
  mode: string
  enabled: boolean
}

type EventMap = Record<string, string[]>

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const ASSETS_DIR = resolve(__dirname, "..", "..", "assets")
const CONFIG_PATHS = [
  join(process.env.HOME || "~", ".claude", "sound-fx.local.json"),
  join(
    process.env.HOME || "~",
    ".config",
    "opencode",
    "sound-fx.json",
  ),
]
const MINIMAL_EVENTS = new Set(["start", "complete", "error", "notification"])
const DEFAULT_VOLUME = parseInt(process.env.CLAUDE_SOUND_VOLUME || "60", 10)

// ---------------------------------------------------------------------------
// Config + manifest loading
// ---------------------------------------------------------------------------

function loadConfig(): SoundConfig {
  const defaults: SoundConfig = { theme: "mix", mode: "full", enabled: true }
  for (const configPath of CONFIG_PATHS) {
    try {
      if (existsSync(configPath)) {
        const raw = JSON.parse(readFileSync(configPath, "utf-8"))
        return { ...defaults, ...raw }
      }
    } catch {
      // ignore malformed config
    }
  }
  return defaults
}

function loadEventMap(theme: string): EventMap {
  const eventMap: EventMap = {}
  if (!existsSync(ASSETS_DIR)) return eventMap

  for (const dir of readdirSync(ASSETS_DIR).sort()) {
    const themeDir = join(ASSETS_DIR, dir)
    const manifestPath = join(themeDir, "manifest.json")
    if (!existsSync(manifestPath)) continue
    if (theme !== "mix" && dir !== theme) continue

    try {
      const manifest = JSON.parse(readFileSync(manifestPath, "utf-8"))
      for (const [key, files] of Object.entries(manifest)) {
        if (!Array.isArray(files)) continue
        for (const fname of files) {
          const fpath = join(themeDir, fname as string)
          if (existsSync(fpath)) {
            if (!eventMap[key]) eventMap[key] = []
            eventMap[key].push(fpath)
          }
        }
      }
    } catch {
      continue
    }
  }
  return eventMap
}

// ---------------------------------------------------------------------------
// Cross-platform audio player
// ---------------------------------------------------------------------------

function isWSL(): boolean {
  try {
    const version = readFileSync("/proc/version", "utf-8")
    return version.toLowerCase().includes("microsoft")
  } catch {
    return false
  }
}

function wslPath(filepath: string): string {
  try {
    return execSync(`wslpath -w "${filepath}"`, { stdio: ["pipe", "pipe", "ignore"] })
      .toString()
      .trim()
  } catch {
    return filepath
  }
}

function detectPlayer(): string | null {
  const os = platform()
  if (os === "darwin") return "afplay"

  // WSL: prefer Windows-side players for direct audio output
  if (isWSL()) {
    for (const cmd of ["ffplay.exe", "powershell.exe"]) {
      try {
        execSync(`which ${cmd}`, { stdio: "ignore" })
        return cmd
      } catch {
        // not found
      }
    }
  }

  // Linux native players (also works if WSL has PulseAudio via WSLg)
  for (const cmd of ["paplay", "ffplay", "aplay"]) {
    try {
      execSync(`which ${cmd}`, { stdio: "ignore" })
      return cmd
    } catch {
      // not found
    }
  }

  if (os === "win32") return "powershell"
  return null
}

function buildPlayCmd(
  player: string,
  filepath: string,
  volume: number,
): string[] | null {
  const vol = volume / 100
  switch (player) {
    case "afplay":
      return ["afplay", "-v", vol.toFixed(2), filepath]
    case "paplay":
      return ["paplay", `--volume=${Math.round(vol * 65536)}`, filepath]
    case "ffplay":
      return [
        "ffplay", "-nodisp", "-autoexit", "-loglevel", "quiet",
        "-volume", String(Math.round(vol * 100)), filepath,
      ]
    case "ffplay.exe": {
      const winPath = wslPath(filepath)
      return [
        "ffplay.exe", "-nodisp", "-autoexit", "-loglevel", "quiet",
        "-volume", String(volume), winPath,
      ]
    }
    case "powershell.exe": {
      const winPath = wslPath(filepath)
      const psCmd =
        `$w=New-Object -ComObject WMPlayer.OCX;` +
        `$w.settings.volume=${volume};` +
        `$w.URL='${winPath}';` +
        `Start-Sleep 4;$w.close()`
      return ["powershell.exe", "-NoProfile", "-Command", psCmd]
    }
    case "aplay":
      return ["aplay", "-q", filepath]
    case "powershell": {
      const psCmd =
        `$w=New-Object -ComObject WMPlayer.OCX;` +
        `$w.settings.volume=${volume};` +
        `$w.URL='${filepath}';` +
        `Start-Sleep 4;$w.close()`
      return ["powershell", "-NoProfile", "-Command", psCmd]
    }
    default:
      return null
  }
}

// ---------------------------------------------------------------------------
// Sound playback
// ---------------------------------------------------------------------------

function playSound(
  event: string,
  eventMap: EventMap,
  player: string | null,
  config: SoundConfig,
): void {
  if (!config.enabled) return
  if (config.mode === "minimal" && !MINIMAL_EVENTS.has(event)) return

  const candidates = eventMap[event]
  if (!candidates?.length || !player) return

  const filepath = candidates[Math.floor(Math.random() * candidates.length)]
  const cmd = buildPlayCmd(player, filepath, DEFAULT_VOLUME)
  if (!cmd) return

  // Fire and forget — don't block the event loop
  const proc = spawn(cmd[0], cmd.slice(1), {
    stdio: "ignore",
    detached: true,
  })
  proc.unref()
}

// ---------------------------------------------------------------------------
// Opencode hook → sound event mapping
// ---------------------------------------------------------------------------

const HOOK_MAP: Record<string, string> = {
  "session.created": "start",
  "session.deleted": "session_end",
  "session.error": "error",
  "session.compacted": "precompact",
}

// ---------------------------------------------------------------------------
// Plugin export
// ---------------------------------------------------------------------------

export const SoundFXPlugin: Plugin = async (_ctx) => {
  const config = loadConfig()
  const eventMap = loadEventMap(config.theme)
  const player = detectPlayer()

  // Track session busy/idle transitions for "complete" event
  const sessionStates = new Map<string, string>()

  return {
    event: async (event: any) => {
      const eventType: string = event.type

      // Direct event mappings
      const soundEvent = HOOK_MAP[eventType]
      if (soundEvent) {
        playSound(soundEvent, eventMap, player, config)
        return
      }

      // message.updated — detect user submit
      if (eventType === "message.updated") {
        const role = event.properties?.message?.role
        if (role === "user") {
          playSound("submit", eventMap, player, config)
        }
        return
      }

      // session.idle — busy→idle transition = "complete"
      if (eventType === "session.idle") {
        const sessionId = event.properties?.sessionID || "default"
        const prev = sessionStates.get(sessionId)
        if (prev === "busy") {
          playSound("complete", eventMap, player, config)
        }
        sessionStates.set(sessionId, "idle")
        return
      }

      // Track busy state
      if (
        eventType === "session.updated" ||
        eventType === "message.updated"
      ) {
        const sessionId = event.properties?.sessionID || "default"
        sessionStates.set(sessionId, "busy")
      }
    },
  }
}

export default SoundFXPlugin
