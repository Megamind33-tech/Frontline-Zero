#!/usr/bin/env python3
"""Check the actual Android artifact; signature verification stays in android-build.sh."""
import pathlib
import sys
import zipfile

path = pathlib.Path(sys.argv[1])
with zipfile.ZipFile(path) as apk:
    if apk.testzip() is not None:
        raise SystemExit('FAIL: corrupt APK member')
    required = [
        'AndroidManifest.xml', 'assets/project.binary',
        'lib/arm64-v8a/libgodot_android.so',
        'lib/armeabi-v7a/libgodot_android.so',
        'assets/third_party/rts_advanced/LICENSE.txt',
    ]
    missing = [name for name in required if name not in apk.namelist()]
    if missing:
        raise SystemExit('FAIL: APK missing ' + ', '.join(missing))
    notice = apk.read(required[-1]).decode('utf-8')
    if 'Copyright (c) 2026 Huginhelm' not in notice or 'MIT License' not in notice:
        raise SystemExit('FAIL: formation copyright/permission notice missing')
print('PASS: APK integrity, Android manifest, Godot data, ARM64/ARMv7 runtimes and MIT notice')
