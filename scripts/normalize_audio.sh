#!/bin/bash
# Normalize all MP3 files in assets/ to consistent loudness using ffmpeg loudnorm (two-pass).
# Target: -16 LUFS (broadcast standard), true peak -1.5 dB, LRA 11.
#
# Usage: bash scripts/normalize_audio.sh [assets_dir]

ASSETS_DIR="${1:-$(cd "$(dirname "$0")/../assets" && pwd)}"
TARGET_I="-16"
TARGET_TP="-1.5"
TARGET_LRA="11"

if ! command -v ffmpeg &>/dev/null; then
  echo "ERROR: ffmpeg not found. Install with: brew install ffmpeg"
  exit 1
fi

# Collect all mp3 files (bash 3.x compatible)
FILES=()
while IFS= read -r f; do
  FILES+=("$f")
done < <(find "$ASSETS_DIR" -name "*.mp3" -type f | sort)
TOTAL=${#FILES[@]}

if [ "$TOTAL" -eq 0 ]; then
  echo "No MP3 files found in $ASSETS_DIR"
  exit 0
fi

echo "=== Audio Normalization ==="
echo "Target: ${TARGET_I} LUFS, TP ${TARGET_TP} dB, LRA ${TARGET_LRA}"
echo "Files: ${TOTAL}"
echo ""

SUCCESS=0
SKIPPED=0
FAILED=0

for i in "${!FILES[@]}"; do
  FILE="${FILES[$i]}"
  RELPATH="${FILE#$ASSETS_DIR/}"
  NUM=$((i + 1))

  printf "[%3d/%d] %s ... " "$NUM" "$TOTAL" "$RELPATH"

  # Pass 1: analyze loudness — extract JSON block between { and }
  RAW=$(ffmpeg -hide_banner -i "$FILE" \
    -af "loudnorm=I=${TARGET_I}:TP=${TARGET_TP}:LRA=${TARGET_LRA}:print_format=json" \
    -vn -sn -dn -f null /dev/null 2>&1)

  STATS=$(echo "$RAW" | python3 -c "
import sys, json, re
text = sys.stdin.read()
# Find the JSON object in ffmpeg output
m = re.search(r'\{[^}]+\}', text, re.DOTALL)
if m:
    d = json.loads(m.group())
    print(json.dumps(d))
else:
    sys.exit(1)
" 2>/dev/null)

  if [ -z "$STATS" ]; then
    printf "FAILED (analysis)\n"
    FAILED=$((FAILED + 1))
    continue
  fi

  # Extract measured values from parsed JSON
  read -r MEASURED_I MEASURED_TP MEASURED_LRA MEASURED_THRESH OFFSET <<< $(echo "$STATS" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d['input_i'], d['input_tp'], d['input_lra'], d['input_thresh'], d['target_offset'])
" 2>/dev/null)

  if [ -z "$MEASURED_I" ]; then
    printf "FAILED (parse)\n"
    FAILED=$((FAILED + 1))
    continue
  fi

  # Skip if already within 1 LUFS of target
  if python3 -c "exit(0 if abs(float('$MEASURED_I') - float('$TARGET_I')) < 1.0 else 1)" 2>/dev/null; then
    printf "OK (already at %s LUFS)\n" "$MEASURED_I"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  # Pass 2: normalize with measured values
  TMPFILE="${FILE}.tmp.mp3"
  if ffmpeg -hide_banner -loglevel error -y -i "$FILE" \
    -af "loudnorm=I=${TARGET_I}:TP=${TARGET_TP}:LRA=${TARGET_LRA}:measured_I=${MEASURED_I}:measured_TP=${MEASURED_TP}:measured_LRA=${MEASURED_LRA}:measured_thresh=${MEASURED_THRESH}:offset=${OFFSET}:linear=true" \
    -ar 44100 -ac 1 -b:a 128k \
    "$TMPFILE" 2>/dev/null; then
    mv "$TMPFILE" "$FILE"
    printf "DONE (%s → %s LUFS)\n" "$MEASURED_I" "$TARGET_I"
    SUCCESS=$((SUCCESS + 1))
  else
    rm -f "$TMPFILE"
    printf "FAILED (encode)\n"
    FAILED=$((FAILED + 1))
  fi
done

echo ""
echo "=== Complete ==="
echo "Normalized: $SUCCESS"
echo "Already OK: $SKIPPED"
echo "Failed:     $FAILED"
echo "Total:      $TOTAL"
