#!/usr/bin/env bash
# Device-side evidence only. Requires one connected Android device and a debuggable build.
set -euo pipefail
cd "$(dirname "$0")/.."
FZ_ADB="${ANDROID_HOME:?Source .tools/android-env.sh}/platform-tools/adb"
FZ_SECONDS="${1:-900}"
FZ_OUT="$PWD/dist/phone-profile"
if [[ ! "$FZ_SECONDS" =~ ^[0-9]+$ ]]; then echo 'Duration must be integer seconds' >&2; exit 1; fi
FZ_COUNT="$($FZ_ADB devices | awk 'NR>1 && $2=="device" {n++} END {print n+0}')"
if [[ "$FZ_COUNT" != 1 ]]; then echo 'BLOCKED: connect exactly one authorized Android device; no phone performance claim.' >&2; exit 1; fi
mkdir -p "$FZ_OUT"
"$FZ_ADB" shell getprop >"$FZ_OUT/device-properties.txt"
"$FZ_ADB" shell dumpsys thermalservice >"$FZ_OUT/thermal-before.txt"
"$FZ_ADB" shell dumpsys battery >"$FZ_OUT/battery-before.txt"
"$FZ_ADB" shell dumpsys gfxinfo com.frontlinezero.game reset >"$FZ_OUT/gfx-reset.txt"
echo "Play a real battle for $FZ_SECONDS seconds. Collecting once per 30 seconds."
FZ_ELAPSED=0
while (( FZ_ELAPSED < FZ_SECONDS )); do
 "$FZ_ADB" shell dumpsys meminfo com.frontlinezero.game >>"$FZ_OUT/memory.txt"
 "$FZ_ADB" shell dumpsys thermalservice >>"$FZ_OUT/thermal-timeline.txt"
 "$FZ_ADB" shell dumpsys battery >>"$FZ_OUT/battery-timeline.txt"
 sleep 30
 FZ_ELAPSED=$((FZ_ELAPSED + 30))
done
"$FZ_ADB" shell dumpsys gfxinfo com.frontlinezero.game framestats >"$FZ_OUT/gfx-framestats.txt"
"$FZ_ADB" shell dumpsys thermalservice >"$FZ_OUT/thermal-after.txt"
echo 'Raw device evidence collected. SurfaceView/OpenGL frame timing can be absent in gfxinfo; use Perfetto/Godot telemetry before concluding frame-time acceptance.'
