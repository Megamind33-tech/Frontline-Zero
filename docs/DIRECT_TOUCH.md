# Direct touch command system

Scope: the existing Godot 4.7.2 battle, units, combat/AI, formations, queues and local results. No new combat class, production/research subsystem, art redesign or engine change is introduced here.

## Player interaction

- Tap a friendly to select. Double-tap it to select living same-class units within 25 m. Class selectors/All remain optional alternatives.
- Tap empty operational terrain to move. Tap a hostile unit or Veyr HQ to attack. No Move/Attack button is required.
- Explicit living targets take firing priority when in legal range. Otherwise existing automatic fire uses the nearest hostile unit, then the hostile HQ. Attack orders follow the live target, stop in the weapon's range band, and back artillery out of its minimum range. Hostile target death advances queued orders; Hold/direct control discard them as before.
- Friendly HQ taps open its actual integrity/campaign/workshop/briefing management panel. This does not issue orders or pretend that production/research already exists.
- Drag the battlefield to pan; pinch to zoom; rotate two fingers to turn the camera. Wheel/right-drag and Q/E remain desktop alternatives. Minimap taps recenter the view. Permanent directional camera controls were removed.
- Hold a selected unit for 500 ms to open advanced orders. Queue orders, Box/Line, Hold, additive selection, save group and single-unit direct drive live here. More is an accessible alternative to the long press. Directions appear only inside contextual direct drive, never as a permanent camera/movement list.
- Save groups 1–3 in advanced orders; recall their main-HUD chips or desktop 1–3. Ctrl+1–3 assigns groups. Assignments persist atomically to a local file and filter dead/enemy/different-blueprint units when recalled after selection changes/relaunch/redeployment.

## Input and command safeguards

The shared pointer classifier covers physical mouse and native screen-touch lifecycles. Pointer-down captures a target but issues no order. A 12-pixel movement threshold distinguishes a tap from a camera drag. Two-pointer gestures suppress all tap results; long presses and menu-dismissal taps do likewise. Moving targets retain the pressed identity. A target destroyed before release is rejected, never converted to a ground command.

HUD-started gestures never turn into battlefield gestures. World gestures ending on the HUD cannot issue orders or activate controls accidentally. Touch-to-mouse emulation stays enabled for Godot Buttons; emulated mouse events are ignored by world commands, preventing duplicate taps while preserving actual touchscreen menus. The viewport event tests exercise this path as well as ordinary mouse/Shift fixtures.

Immediate expanding move rings, attack crosses and rejection feedback are separate from persistent waypoint paths and explicit-target reticles. A queue indicator stays in the selection summary when append mode is enabled. Invalid commands preserve the active order and queue. The existing cap of 16 active/pending orders remains atomic for selected groups. Friendly objects cannot be explicitly attacked. Nonfinite/off-map destinations, invalid/dead/friendly targets and unsupported movement domains are rejected.

## Honest movement/domain boundaries

The baseline contains ground units and two HQ structures only. These are the supported/tested targets. Aircraft/naval units and other hostile building types are not added; unknown domains are rejected instead of receiving inappropriate ground commands. The existing movement is straight-line with formation destination assignment, not an obstacle-aware pathfinder. This change preserves it; no unreachable-around-obstacles, collision/separation or formation-preserving-travel claim is made. Off-map/unusable targets fail gracefully. Obstacle routing remains a separate recorded acceptance gap, rather than an unrelated new system hidden inside input work.

## Verification and evidence

`bash scripts/verify.sh` now includes `tests/touch_suite.gd`. Its 38 checks execute single/multi-unit movement/focus, hostile HQ damage and priority, moving/dead target handling, range/minimum-range behavior, queue continuation, friendly building management, gesture/HUD boundaries, live selection, long/double press, touch/mouse emulation, persistent groups and domain rejection. Engine viewport events are actual Godot input dispatch; they are not physical phone tests. A first harness attempt using `Input.parse_input_event` did not route through a focused headless window; a diagnostic confirmed `Viewport.push_input` dispatches the engine callbacks and GUI correctly, and the corrected harness passes.

`tests/touch_benchmark.gd` measures 1,000 engine-dispatched tap pairs for a five-unit group on the host, including command/HUD updates, without raster/display/device-input latency. `scripts/capture-battle.py` records actual engine gameplay and separately measures rendered host behavior. Captured gestures are automated native event/HUD inputs, not a human phone playtest. The capture demonstrates a queued hostile-unit→HQ attack, friendly building panel, long-press queue menu, movement waypoints, double-tap class selection, pinch/rotation and saved-group recall; battle results remain genuine and persisted.

Android APK export/signature/package checks are separate from phone evidence. `adb devices` reports no attached device, so Android touch latency, sustained frame times, RAM and thermals remain blocked. `scripts/profile-android.sh` intentionally stops rather than generating placeholder hardware results. The earlier visual pass and two-attempt strategic-defense blocker remain in STATUS; enemy AI is unchanged in this direct-touch work.
