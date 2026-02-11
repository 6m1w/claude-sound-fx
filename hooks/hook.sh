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
    start|complete|error) ;;
    *) exit 0 ;;
  esac
fi

# Remote mode: forward to local relay
if [ "$(uname)" != "Darwin" ]; then
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

# Play with volume control
VOL=$(printf '%.2f' "$(echo "$SOUND_VOLUME / 100" | bc -l)")
afplay -v "$VOL" "$FILE" &
exit 0
