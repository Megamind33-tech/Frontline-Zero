# FRONTLINE ZERO

Offline fictional-nations Android RTS prototype in **Godot 4.7.2**. No paid dependencies, accounts, multiplayer, politics or full research tree.

Open `godot/project.godot` with Godot. Deploy a force; tap a friendly unit, then ground or an enemy. WASD/arrows or the directional pad directly drive one selected unit. Weapons fire automatically. Capture wooded supply relays or destroy enemy HQ. Siege is verified; territory strategy balancing remains open.

```
bash scripts/bootstrap.sh
bash scripts/verify.sh
# Requires Android SDK + OpenJDK 17:
bash scripts/bootstrap.sh --templates
bash scripts/android-build.sh
```

The GitHub Actions workflow verifies the model, generates reusable vehicle assets and attempts a signed debug APK export. Download build output from the workflow artifacts after a successful run. Debug APK is for sideload testing, not store release.

`npm run verify` tests and builds the experimental offline web reference in `dist/FRONTLINE_ZERO.html`; the Godot project is the canonical game.

Read [current status](docs/STATUS.md), [toolchain](docs/TOOLCHAIN.md) and [Android validation](docs/ANDROID_VALIDATION.md) before claiming device readiness.
