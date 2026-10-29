# Android and art toolchain

Prepared and tested 2026-10-29 on Linux x86_64. Binaries/downloads stay outside Git in `.tools/`. Keep installed tools' notices with their distributions.

## Reproduce

```bash
python3 scripts/setup-android.py
source .tools/android-env.sh
bash scripts/bootstrap.sh --templates
bash scripts/verify.sh
bash scripts/verify-art.sh
bash scripts/android-build.sh
```

The setup script uses pinned official archives in `scripts/toolchain-lock.json`, checks archive sizes and official checksums (Google SDK SHA-1 metadata; Adoptium SHA-256), and installs only into `.tools`. It makes no system package or shell-profile changes and does not auto-accept `sdkmanager --licenses`; review SDK terms using that command when needed. Python requires `hashlib.file_digest` and tar extraction filters (Python 3.12+ recommended). Network access to Google, GitHub and Adoptium is required. Limit retries per AGENTS.md; investigate concrete errors instead of looping downloads.

| Component | Installed version / location | Validation |
|---|---|---|
| Godot | 4.7.2.stable.official.ed1daf0bf / `.tools/godot` | Official SHA-512 checks; all game suites and export. |
| Export templates | Official 4.7.2 stable, Android debug/release and Linux debug/release | Archive SHA-512; signed non-Gradle Android export. |
| OpenJDK | Eclipse Temurin 17.0.21+9 / `.tools/jdk-17` | `java -version`, `javac -version`, keytool and APK signing. |
| Android command-line tools | 19.0 / `.tools/android-sdk/cmdline-tools/19.0` | `sdkmanager --version`. Latest redesigned CLI was initially downloaded but replaced in the lock by compatible version 19.0. |
| Android platform / build-tools | Android 35 revision 2 / 35.0.1 | `aapt`, `apksigner`, `zipalign` used in export. Godot's official template targets SDK 36; it successfully uses build-tools 35.0.1 with a fallback notice. No Gradle build or Play Store submission claimed. |
| Android platform-tools | 37.0.1 / `.tools/android-sdk/platform-tools` | `adb version`, `adb devices -l`; no phone attached. |
| Blender | Debian 4.3.2 / `/usr/bin/blender` | Three original GLBs and editable `.blend` sources generated; 18 Godot handoff checks. |
| Inkscape | Debian 1.4 / `/usr/bin/inkscape` | Original icon sheet/app icon exported to PNG; command sheet visually inspected. |
| GIMP | Debian 3.0.4 / `/usr/bin/gimp` | Version check only; GUI authoring untested. |

Blender/Inkscape/GIMP were already installed on this host; the old crashing Blender 5.2.3 archive was not retried. For another Debian host install compatible distro packages through its package manager, then run the same art validation. JDK retains its GPLv2/ClassPath exception and other notices under `legal/`; authoring programs retain distro notices under `/usr/share/doc/{blender,inkscape,gimp}/copyright`. Android archives retain their NOTICE/license files. Tool licenses are separate from licenses for original game source/art; no tool source was copied into the game.

The minimal non-Gradle export does not need Android Studio, an emulator, NDK, CMake or Gradle downloads. Add those only when a concrete native plugin or custom Gradle build requires them. This avoids installing unrelated systems that cannot improve the current slice.

## Current deliverables

- `dist/FRONTLINE_ZERO-debug.apk`: installable **debug-signed APK**, ARM64 and ARMv7, package `com.frontlinezero.game`, Android minimum API 24, target API 36. APK v2/v3 signature, ZIP integrity and packaged formation MIT notice checked. Development signing only; not a production/store release.
- `dist/FRONTLINE_ZERO-art-kit.zip`: original vehicle GLBs, editable Blender sources, manifest, SVG command sheet/app icon and art notices. GLBs are designer handoff assets; current battle models are preserved.
- `art/ui/command-icons.svg`: editable original command concepts; `godot/icon.svg`: actual application icon.
- `docs/evidence/toolchain-verification.log`: concise versions, suite/export result and artifact hashes. Additional art evidence is in `art-pipeline-tests.log`.

Unlike earlier PCK files, the APK includes the Android runtime and manifest. **Export/signature checks do not prove a phone can boot it or sustain a battle.** No device is attached. Next: install with `adb install -r dist/FRONTLINE_ZERO-debug.apk` on a connected Android device; check cold start, touch commands, pause/resume, save/relaunch, a 15-minute session, memory, thermal and frame times. Do not publish a debug keystore or change production signing/billing settings.

## Retained provenance

The prior toolchain record pinned the Godot Linux archive SHA-512 to
`9aa00f7a605200940bce3027a567b782f49bd8e940dd06ae9e987bd65aee1b1467edd56ed84fcdcbdd44354bf613bdbb4e5d2913e925850368e150c59ed54c65`
at https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip.
The previously blocked Blender 5.2.3 archive SHA-256 was
`78486c018b4443efe5e75ab54c290ed8c15abafd249b862c2c9ce2530a918eec`
at https://download.blender.org/release/Blender5.2/blender-5.2.3-linux-x64.tar.xz.
That binary was not retried; the compatible installed Debian Blender was used instead. Godot's original scene generator remains the battle asset fallback, with existing AnimationPlayer recoil tracks and original GDScript mechanics. Blender remains optional for the game build.

Original game code has no public redistribution license granted at this stage; public repository visibility alone is not a license. The original art's CC0 dedication and third-party tool/component notices do not change that status.
