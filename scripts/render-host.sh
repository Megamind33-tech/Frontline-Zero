#!/usr/bin/env bash
# Actual OpenGL rendering under Xvfb/llvmpipe when a desktop display is unavailable.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p dist
FZ_XVFB="${XVFB_BIN:-$PWD/.tools/render-host/usr/bin/Xvfb}"
FZ_GODOT="${GODOT_BIN:-$PWD/.tools/godot}"
"$FZ_XVFB" -displayfd 3 -screen 0 1280x720x24 -ac -nolisten tcp 3>dist/display-id.txt >dist/xvfb.log 2>&1 &
FZ_DISPLAY_PID=$!
trap 'kill "$FZ_DISPLAY_PID" 2>/dev/null || true' EXIT
export LIBGL_ALWAYS_SOFTWARE=1
python3 - <<'PY'
from pathlib import Path
import time
for attempt in range(80):
 if Path('dist/display-id.txt').read_text().strip():break
 time.sleep(.05)
else:raise SystemExit('Xvfb did not allocate a display; inspect dist/xvfb.log')
PY
export DISPLAY=":$(cat dist/display-id.txt)"
"$FZ_GODOT" --path godot --rendering-method gl_compatibility --audio-driver Dummy --resolution 1280x720 "$@"
