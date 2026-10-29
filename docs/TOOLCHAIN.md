# Pinned tools and assets

| Component | Version/source | Status |
|---|---|---|
| Godot standard Linux x86_64 | 4.7.2, official godotengine/godot-builds release | Downloaded, SHA512 verified, executable |
| Blender asset builder | 5.2.3 Linux x64, download.blender.org/release/Blender5.2 | Downloaded, SHA256 verified, startup crash; blocked |
| Asset builder fallback | godot/tests/build_assets.gd | Executed, three reusable vehicle scenes |
| Animation system | Godot AnimationPlayer, original recoil tracks | Included in each generated scene |
| Gameplay/AI/persistence | Original GDScript, Godot built-in APIs | Headless tests executed |
| Android export templates | Matching Godot 4.7.2 | Two download timeouts; CI must fetch |
| Android SDK / Java | API 35, build-tools 35.0.1 / OpenJDK 17 | CI setup; absent locally |

Godot archive SHA512:
`9aa00f7a605200940bce3027a567b782f49bd8e940dd06ae9e987bd65aee1b1467edd56ed84fcdcbdd44354bf613bdbb4e5d2913e925850368e150c59ed54c65`

Blender archive SHA256:
`78486c018b4443efe5e75ab54c290ed8c15abafd249b862c2c9ce2530a918eec`

Official archive URLs:
- https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip
- https://download.blender.org/release/Blender5.2/blender-5.2.3-linux-x64.tar.xz

Godot is MIT, Blender GPL; these tools do not transfer their licenses to original game assets. Generated prototype geometry/recoil is original and CC0-1.0. No Art of War assets, paid packs or unreviewed addons imported. Original game code has no public redistribution license granted at this stage; the repository is publicly visible.

No additional AI/animation addons are required for the slice. Godot's built-in systems and the included original mechanics keep dependencies small. Blender is optional; do not block gameplay on it.
