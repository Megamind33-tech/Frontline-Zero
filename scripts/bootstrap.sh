#!/usr/bin/env bash
set -euo pipefail
# Pinned official engine. Binaries stay outside Git.
FZ_VERSION=4.7.2
FZ_TOOLS="${FZ_TOOLS:-$PWD/.tools}"
FZ_BASE="https://github.com/godotengine/godot-builds/releases/download/${FZ_VERSION}-stable"
mkdir -p "$FZ_TOOLS"
cd "$FZ_TOOLS"
fetch() { test -f "$1" || curl -fsSL --connect-timeout 20 --max-time 240 "$FZ_BASE/$1" -o "$1"; }
fetch SHA512-SUMS.txt
FZ_ZIP="Godot_v${FZ_VERSION}-stable_linux.x86_64.zip"
fetch "$FZ_ZIP"
rg --fixed-strings "$FZ_ZIP" SHA512-SUMS.txt | sha512sum --check
unzip -qo "$FZ_ZIP"
chmod +x "Godot_v${FZ_VERSION}-stable_linux.x86_64"
ln -sf "Godot_v${FZ_VERSION}-stable_linux.x86_64" godot
if [[ "${1:-}" == "--templates" ]]; then
 FZ_TPZ="Godot_v${FZ_VERSION}-stable_export_templates.tpz"
 fetch "$FZ_TPZ"
 rg --fixed-strings " $FZ_TPZ" SHA512-SUMS.txt | sha512sum --check
 FZ_TARGET="${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/$FZ_VERSION.stable"
 mkdir -p "$FZ_TARGET"
 unzip -qo "$FZ_TPZ" 'templates/android_debug.apk' 'templates/android_release.apk' 'templates/linux_debug.x86_64' 'templates/linux_release.x86_64' -d "$FZ_TOOLS/unpacked"
 cp "$FZ_TOOLS"/unpacked/templates/* "$FZ_TARGET/"
fi
./godot --version
