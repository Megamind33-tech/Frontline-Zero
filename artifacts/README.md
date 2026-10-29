# Verified resource pack

`FRONTLINE_ZERO-formation-android.pck` is an Android-target **Godot data pack**, not an APK or standalone executable. Exported with Godot 4.7.2. No Android SDK/device run is claimed.

Use matching Godot to inspect on desktop:

```
godot --main-pack artifacts/FRONTLINE_ZERO-formation-android.pck
```

Headless packaging test (including packed MIT notice and scene control):

```
godot --headless --main-pack artifacts/FRONTLINE_ZERO-formation-android.pck --script godot/tests/packed_suite.gd
```

Rebuild from repository root:

```
godot --headless --path godot --editor --import --quit
godot --headless --path godot --export-pack Android "$PWD/artifacts/FRONTLINE_ZERO-formation-android.pck"
```

This pack excludes test sources and includes the vendored MIT license. See docs/STATUS.md for APK/device blockers.
