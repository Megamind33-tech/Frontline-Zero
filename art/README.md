# FRONTLINE ZERO art workshop

Original sources for our existing Godot 4.7.2 fully 3D game. Art of War 3 is a gameplay reference; no Gear Games artwork, branding or source is included.

## Installed workflow

- **Blender 4.3.2**: model, UV, rig and animate vehicles/buildings/terrain; save editable `.blend` sources. `BLENDER_BIN` can select another compatible Blender. The previously crashing 5.2.3 binary is not used.
- **GIMP 3.0.4**: edit texture atlases and paint/export PNGs. Only its installed version was checked; interactive painting is not tested in this headless session.
- **Inkscape 1.4**: edit SVG command icons, emblems and UI concepts; export PNG atlases. Actual PNG export was checked.
- **Godot 4.7.2**: import GLB, review scale/animation, make materials and Control-based UI; retain Compatibility renderer.

Run `bash scripts/verify-art.sh` from the repository root after setting `GODOT_BIN` if necessary. It runs Blender in factory-startup/background mode, writes three original vehicle GLBs plus editable sources under `.tools/art-generated/sources/`, then executes 18 Godot checks for parseability, geometry, meter scale/Y-up and retained recoil animation. Current original meshes: scout 292 triangles; tank/artillery 556 triangles each. These are prototype assets, not finished production art or a measured phone graphics budget.

The existing battle still uses its verified `godot/assets/*.tscn` vehicles. Generated GLBs are a designer handoff, not silently substituted battle assets. Open a generated `.blend` in Blender, edit, and export glTF Binary with +Y Up and animation enabled; repeat Godot validation before integration. Native `.blend` files stay outside the Godot project to avoid implicit Blender imports on build machines.

`ui/command-icons.svg` contains original editable Move/Queue/Hold/Direct/Focus concepts with labels and shape cues. It is a workshop sheet, not yet wired into command buttons. `godot/icon.svg` is the original application icon used by the Android build. Inkscape export may emit GTK/Pango warnings on this headless host; the PNG was produced and visually inspected.

For a portable kit, run verification and package `.tools/art-generated/{scout,tank,artillery}.glb`, `sources/*.blend`, `manifest.json`, this directory, the application icon and their CC0 notices. `dist/FRONTLINE_ZERO-art-kit.zip` is the current generated handoff. Dependencies themselves remain in `.tools` or the system; never commit SDK/JDK archives, signing keys or huge tool binaries.

## Licensing

The original generated geometry/recoil, command icon sheet and application icon are CC0-1.0; see `LICENSE.txt`. Keep the existing RTS formation MIT notice untouched. Blender, Inkscape and GIMP are GPL development tools; using them to author our own artwork does not import their program source into the game. Their program distributions and bundled components keep their own copyright/license notices. No BAR/GPL gameplay source, Pro-only addon, downloaded third-party model, or Art of War 3 asset is included.
