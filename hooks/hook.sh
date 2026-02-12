#!/bin/bash
# Claude Code hook event handler.
# Usage: hook.sh <event_type>
#
# Reads user config from ~/.claude/sound-fx.local.json:
#   theme:   "mix" | "jarvis" | "glados" | ... (default: mix)
#   mode:    "full" | "minimal"                (default: full)
#   enabled: true | false                      (default: true)
#
# Each theme directory under assets/ contains a manifest.json
# that maps event names to sound files. Adding a new theme =
# adding a new directory with manifest.json + wav files.
#
# Environment: CLAUDE_SOUND_VOLUME (0-100, default 60)

# Resolve plugin root
if [ -n "$CLAUDE_PLUGIN_ROOT" ]; then
  PLUGIN_ROOT="$CLAUDE_PLUGIN_ROOT"
else
  PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fi

ASSETS_DIR="$PLUGIN_ROOT/assets"
CONFIG_FILE="$HOME/.claude/sound-fx.local.json"
SOUND_VOLUME=${CLAUDE_SOUND_VOLUME:-60}
SOUND_PORT=${CLAUDE_SOUND_PORT:-19876}

EVENT="$1"
[ -z "$EVENT" ] && exit 0

# Sanitize event name
EVENT=$(echo "$EVENT" | tr -cd 'a-zA-Z0-9_')
[ -z "$EVENT" ] && exit 0

# Read user config
THEME="mix"
MODE="full"
ENABLED="True"
if [ -f "$CONFIG_FILE" ]; then
  THEME=$(python3 -c "
import json
c = json.load(open('$CONFIG_FILE'))
print(c.get('theme', 'mix'))
" 2>/dev/null || echo "mix")
  MODE=$(python3 -c "
import json
c = json.load(open('$CONFIG_FILE'))
print(c.get('mode', 'full'))
" 2>/dev/null || echo "full")
  ENABLED=$(python3 -c "
import json
c = json.load(open('$CONFIG_FILE'))
print(c.get('enabled', True))
" 2>/dev/null || echo "True")
fi

# Disabled mode: exit silently
[ "$ENABLED" = "False" ] && exit 0

# Minimal mode: only essential events
if [ "$MODE" = "minimal" ]; then
  case "$EVENT" in
    start|complete|error|notification) ;;
    *) exit 0 ;;
  esac
fi

# Detect audio player: local player if available, otherwise relay
PLAYER=""
IS_WSL=false
if [ "$(uname)" = "Darwin" ]; then
  PLAYER="afplay"
else
  # Check for WSL — try Windows-side players first
  if grep -qi microsoft /proc/version 2>/dev/null; then
    IS_WSL=true
    if command -v ffplay.exe >/dev/null 2>&1; then
      PLAYER="ffplay.exe"
    elif command -v powershell.exe >/dev/null 2>&1; then
      PLAYER="powershell.exe"
    fi
  fi
  # Linux native players (also works if WSL has PulseAudio via WSLg)
  if [ -z "$PLAYER" ]; then
    for cmd in paplay ffplay aplay; do
      if command -v "$cmd" >/dev/null 2>&1; then
        PLAYER="$cmd"
        break
      fi
    done
  fi
fi

# No local player found — forward to relay (remote SSH / headless)
if [ -z "$PLAYER" ]; then
  curl -s --connect-timeout 1 "http://127.0.0.1:${SOUND_PORT}/${EVENT}" &>/dev/null &
  exit 0
fi

# Collect candidates from manifest.json files
# If theme=mix, scan all directories; otherwise only the matching one
CANDIDATES=$(python3 -c "
import json, os, sys

assets_dir = '$ASSETS_DIR'
theme = '$THEME'
event = '$EVENT'

candidates = []
for d in sorted(os.listdir(assets_dir)):
    theme_dir = os.path.join(assets_dir, d)
    manifest = os.path.join(theme_dir, 'manifest.json')
    if not os.path.isfile(manifest):
        continue
    # Filter by theme: 'mix' uses all, otherwise match directory name
    if theme != 'mix' and d != theme:
        continue
    try:
        m = json.load(open(manifest))
        for f in m.get(event, []):
            path = os.path.join(theme_dir, f)
            if os.path.exists(path):
                candidates.append(path)
    except (json.JSONDecodeError, IOError):
        continue

for c in candidates:
    print(c)
" 2>/dev/null)

[ -z "$CANDIDATES" ] && exit 0

# Pick random candidate (compatible with bash 3.x on macOS)
IFS=$'\n' read -r -d '' -a FILES <<< "$CANDIDATES" || true
COUNT=${#FILES[@]}
[ "$COUNT" -eq 0 ] && exit 0
FILE="${FILES[$((RANDOM % COUNT))]}"

[ -z "$FILE" ] && exit 0

# Convert path for WSL players that need Windows paths
PLAY_FILE="$FILE"
if [ "$IS_WSL" = true ] && [ "$PLAYER" = "ffplay.exe" -o "$PLAYER" = "powershell.exe" ]; then
  PLAY_FILE=$(wslpath -w "$FILE" 2>/dev/null || echo "$FILE")
fi

# Play with volume control (cross-platform)
case "$PLAYER" in
  afplay)
    VOL=$(printf '%.2f' "$(echo "$SOUND_VOLUME / 100" | bc -l)")
    afplay -v "$VOL" "$FILE" &
    ;;
  paplay)
    PA_VOL=$((SOUND_VOLUME * 65536 / 100))
    paplay --volume="$PA_VOL" "$FILE" &
    ;;
  ffplay)
    ffplay -nodisp -autoexit -loglevel quiet -volume "$SOUND_VOLUME" "$FILE" &
    ;;
  ffplay.exe)
    ffplay.exe -nodisp -autoexit -loglevel quiet -volume "$SOUND_VOLUME" "$PLAY_FILE" &>/dev/null &
    ;;
  powershell.exe)
    powershell.exe -NoProfile -Command "\$w=New-Object -ComObject WMPlayer.OCX;\$w.settings.volume=$SOUND_VOLUME;\$w.URL='${PLAY_FILE}';\$null=\$w.controls;Start-Sleep 4;\$w.close()" &>/dev/null &
    ;;
  aplay)
    aplay -q "$FILE" &
    ;;
esac
exit 0
