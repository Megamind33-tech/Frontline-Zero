#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
FZ_GODOT="${GODOT_BIN:-$PWD/.tools/godot}"
: "${ANDROID_HOME:?Android SDK missing; set ANDROID_HOME}"
: "${JAVA_HOME:?OpenJDK 17 missing; set JAVA_HOME}"
test -x "$ANDROID_HOME/build-tools/35.0.1/apksigner"
mkdir -p dist .tools/android
FZ_KEY="$PWD/.tools/android/debug.keystore"
if [[ ! -f "$FZ_KEY" ]]; then
 "$JAVA_HOME/bin/keytool" -genkeypair -keystore "$FZ_KEY" -alias androiddebugkey -storepass android -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname 'CN=Android Debug,O=Frontline Zero,C=US'
fi
# Godot loads this editor settings resource for command-line exports.
FZ_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/godot"
mkdir -p "$FZ_CONFIG"
python3 scripts/android-settings.py "$FZ_CONFIG/editor_settings-4.7.tres" "$ANDROID_HOME" "$JAVA_HOME" "$FZ_KEY"
"$FZ_GODOT" --headless --path godot --export-debug Android "$PWD/dist/FRONTLINE_ZERO-debug.apk" >dist/android-export.log 2>&1
cat dist/android-export.log
if rg -q 'SCRIPT ERROR:|^ERROR:' dist/android-export.log; then exit 1; fi
"$ANDROID_HOME/build-tools/35.0.1/apksigner" verify --verbose dist/FRONTLINE_ZERO-debug.apk
unzip -t dist/FRONTLINE_ZERO-debug.apk
python3 scripts/verify-apk.py dist/FRONTLINE_ZERO-debug.apk
