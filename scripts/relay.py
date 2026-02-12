#!/usr/bin/env python3
"""
Relay server for Claude Code hook sound events.

Reads user config (~/.claude/sound-fx.local.json) and plays sounds from
theme manifest.json files — no hardcoded theme mappings.

Usage:
  python3 relay.py          # foreground
  python3 relay.py &        # background
  python3 relay.py --kill   # stop running server
  python3 relay.py --status # show running status

Remote sessions send: curl http://127.0.0.1:19876/<event>

Environment:
  CLAUDE_SOUND_PORT    - server port (default: 19876)
  CLAUDE_SOUND_VOLUME  - volume 0-100 (default: 60)
"""
import http.server
import json
import os
import random
import re
import shutil
import signal
import socketserver
import subprocess
import sys
import time

PORT = int(os.environ.get("CLAUDE_SOUND_PORT", 19876))
VOLUME = int(os.environ.get("CLAUDE_SOUND_VOLUME", 60))
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
ASSETS_DIR = os.path.join(BASE_DIR, "..", "assets")
PID_FILE = os.path.join(BASE_DIR, ".relay.pid")
CONFIG_FILE = os.path.join(os.path.expanduser("~"), ".claude", "sound-fx.local.json")

VALID_EVENT = re.compile(r"^[a-zA-Z0-9_]+$")
MINIMAL_EVENTS = {"start", "complete", "error", "notification"}


# ---------------------------------------------------------------------------
# User config
# ---------------------------------------------------------------------------

def load_config():
    """Load user config from ~/.claude/sound-fx.local.json"""
    config = {"theme": "mix", "mode": "full", "enabled": True}
    try:
        with open(CONFIG_FILE) as f:
            user = json.load(f)
        config.update(user)
    except (FileNotFoundError, json.JSONDecodeError, IOError):
        pass
    return config


# ---------------------------------------------------------------------------
# Manifest-driven event map
# ---------------------------------------------------------------------------

def load_event_map(theme):
    """Build event→[filepath] map from manifest.json files.

    If theme is "mix", scan all theme directories.
    Otherwise, only load the specified theme.
    """
    event_map = {}
    if not os.path.isdir(ASSETS_DIR):
        return event_map

    for d in sorted(os.listdir(ASSETS_DIR)):
        theme_dir = os.path.join(ASSETS_DIR, d)
        manifest_path = os.path.join(theme_dir, "manifest.json")
        if not os.path.isfile(manifest_path):
            continue
        # Filter by theme: "mix" uses all, otherwise match directory name
        if theme != "mix" and d != theme:
            continue
        try:
            with open(manifest_path) as f:
                manifest = json.load(f)
            for key, files in manifest.items():
                if not isinstance(files, list):
                    continue
                for fname in files:
                    fpath = os.path.join(theme_dir, fname)
                    if os.path.exists(fpath):
                        event_map.setdefault(key, []).append(fpath)
        except (json.JSONDecodeError, IOError):
            continue
    return event_map


# ---------------------------------------------------------------------------
# Cross-platform audio player detection
# ---------------------------------------------------------------------------

def is_wsl():
    """Check if running inside WSL."""
    try:
        with open("/proc/version") as f:
            return "microsoft" in f.read().lower()
    except (FileNotFoundError, IOError):
        return False


def wsl_path(filepath):
    """Convert Linux path to Windows path inside WSL."""
    try:
        result = subprocess.check_output(
            ["wslpath", "-w", filepath], stderr=subprocess.DEVNULL
        )
        return result.decode().strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return filepath


def detect_player():
    """Auto-detect available audio player command."""
    if sys.platform == "darwin":
        return "afplay"
    # WSL: prefer Windows-side players for direct audio
    if is_wsl():
        for cmd in ["ffplay.exe", "powershell.exe"]:
            if shutil.which(cmd):
                return cmd
    # Linux native players (also works if WSL has PulseAudio via WSLg)
    for cmd in ["paplay", "ffplay", "aplay"]:
        if shutil.which(cmd):
            return cmd
    # Native Windows
    if sys.platform == "win32":
        return "powershell"
    return None


def build_play_cmd(player, filepath, volume):
    """Build the subprocess command list for the detected player."""
    vol = volume / 100.0
    if player == "afplay":
        return ["afplay", "-v", f"{vol:.2f}", filepath]
    if player == "paplay":
        # paplay uses linear volume 0-65536
        pa_vol = int(vol * 65536)
        return ["paplay", f"--volume={pa_vol}", filepath]
    if player == "ffplay":
        return ["ffplay", "-nodisp", "-autoexit", "-loglevel", "quiet",
                "-volume", str(int(vol * 100)), filepath]
    if player == "ffplay.exe":
        # WSL: convert path and call Windows ffplay
        win_path = wsl_path(filepath)
        return ["ffplay.exe", "-nodisp", "-autoexit", "-loglevel", "quiet",
                "-volume", str(volume), win_path]
    if player == "powershell.exe":
        # WSL: use WMPlayer.OCX COM object (supports mp3)
        win_path = wsl_path(filepath)
        ps_cmd = (
            f"$w=New-Object -ComObject WMPlayer.OCX;"
            f"$w.settings.volume={volume};"
            f"$w.URL='{win_path}';"
            f"Start-Sleep 4;$w.close()"
        )
        return ["powershell.exe", "-NoProfile", "-Command", ps_cmd]
    if player == "aplay":
        # aplay has no volume flag; play at system volume
        return ["aplay", "-q", filepath]
    if player == "powershell":
        # Native Windows: use WMPlayer.OCX
        ps_cmd = (
            f"$w=New-Object -ComObject WMPlayer.OCX;"
            f"$w.settings.volume={volume};"
            f"$w.URL='{filepath}';"
            f"Start-Sleep 4;$w.close()"
        )
        return ["powershell", "-NoProfile", "-Command", ps_cmd]
    return None


# ---------------------------------------------------------------------------
# Sound playback
# ---------------------------------------------------------------------------

# Detected once at startup
PLAYER = detect_player()
CONFIG = load_config()
EVENT_MAP = load_event_map(CONFIG.get("theme", "mix"))


def play_sound(event):
    """Play a random sound file for the given event."""
    if not VALID_EVENT.match(event):
        return
    if not CONFIG.get("enabled", True):
        return
    # Minimal mode filtering
    if CONFIG.get("mode") == "minimal" and event not in MINIMAL_EVENTS:
        return

    candidates = EVENT_MAP.get(event, [])
    if not candidates:
        return
    if PLAYER is None:
        return

    filepath = random.choice(candidates)
    cmd = build_play_cmd(PLAYER, filepath, VOLUME)
    if cmd:
        subprocess.Popen(
            cmd,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )


# ---------------------------------------------------------------------------
# HTTP server
# ---------------------------------------------------------------------------

class SoundHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        event = self.path.strip("/")
        if event:
            play_sound(event)
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"ok")

    def log_message(self, format, *args):
        pass


class ReusableTCPServer(socketserver.TCPServer):
    allow_reuse_address = True


# ---------------------------------------------------------------------------
# Process management
# ---------------------------------------------------------------------------

def kill_existing():
    """Stop a previously running relay process."""
    if not os.path.exists(PID_FILE):
        return
    try:
        with open(PID_FILE) as f:
            pid = int(f.read().strip())
        os.kill(pid, signal.SIGTERM)
        for _ in range(20):
            try:
                os.kill(pid, 0)
                time.sleep(0.1)
            except ProcessLookupError:
                break
        print(f"Stopped relay (PID {pid})")
    except (ProcessLookupError, ValueError):
        pass
    try:
        os.remove(PID_FILE)
    except FileNotFoundError:
        pass


def show_status():
    """Print current relay config and status."""
    print(f"Config file: {CONFIG_FILE}")
    print(f"  theme:   {CONFIG.get('theme', 'mix')}")
    print(f"  mode:    {CONFIG.get('mode', 'full')}")
    print(f"  enabled: {CONFIG.get('enabled', True)}")
    print(f"Player:    {PLAYER or 'none detected'}")
    print(f"Assets:    {ASSETS_DIR}")
    themes = [d for d in sorted(os.listdir(ASSETS_DIR))
              if os.path.isfile(os.path.join(ASSETS_DIR, d, "manifest.json"))]
    print(f"Themes:    {', '.join(themes)}")
    print(f"Events:    {', '.join(sorted(EVENT_MAP.keys()))}")
    total = sum(len(v) for v in EVENT_MAP.values())
    print(f"Sound files loaded: {total}")

    if os.path.exists(PID_FILE):
        try:
            with open(PID_FILE) as f:
                pid = int(f.read().strip())
            os.kill(pid, 0)
            print(f"Relay running: PID {pid} on port {PORT}")
        except (ProcessLookupError, ValueError):
            print("Relay not running (stale PID file)")
    else:
        print("Relay not running")


def main():
    if "--kill" in sys.argv:
        kill_existing()
        return

    if "--status" in sys.argv:
        show_status()
        return

    kill_existing()

    with open(PID_FILE, "w") as f:
        f.write(str(os.getpid()))

    theme = CONFIG.get("theme", "mix")
    mode = CONFIG.get("mode", "full")
    total = sum(len(v) for v in EVENT_MAP.values())
    print(f"Relay listening on 127.0.0.1:{PORT}")
    print(f"PID: {os.getpid()}, Volume: {VOLUME}, Player: {PLAYER}")
    print(f"Theme: {theme}, Mode: {mode}, Sound files: {total}")

    server = ReusableTCPServer(("127.0.0.1", PORT), SoundHandler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
        try:
            os.remove(PID_FILE)
        except FileNotFoundError:
            pass


if __name__ == "__main__":
    main()
