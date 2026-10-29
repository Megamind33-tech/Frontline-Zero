# Targeted battle audit — 2026-10-29

Source baseline: `964e458`, continued on `battle/convincing-vertical-slice`. Scope: `main.gd`, `simulation.gd`, existing formation/queue tests, asset builders and build/capture scripts. No engine migration or repository-wide scan.

## Retain

- `simulation.gd`: fixed 30 Hz horizontal ground model, three roles and validated blueprints, combat/range/cooldown/cover/mud, capture/HQ/elimination/time outcomes.
- Existing selection/direct input, pinned MIT formation destinations and bounded unit queues, plus persistence's atomic/idempotent result writes.
- Existing 12 baseline, 22 formation and 22 queue checks, siege plan and performance instrumentation; preserve the standalone web reference without presenting it as the product.
- Godot 4.7.2 fully 3D scene, Compatibility renderer, installed Android toolchain and development signing.

## Evidence and gaps

Rendered the actual baseline under Xvfb/Mesa llvmpipe at 1280×720 (`dist/audit-baseline.png`). The default scene is a flat slab with box trees, simple vehicles, no camera controls, bright uniform materials, line-only tracers and a permanent workshop/debug sidebar. The old UI hides important commands below a scroll area. AI uses fixed attack/capture destinations and does not deliberately defend HQ/respond to threats. Terrain rules exist, but their presentation is inadequate. Prior headless checks do not establish visual quality or phone performance.

## Technology and asset reuse decision

Use the existing Godot engine systems: GLTF import/automatic mesh LODs, AnimationPlayer, shared materials, MultiMesh vegetation, ImmediateMesh for bounded visual shell trails, Control/Theme for touch UI and Camera3D for projection/gestures. These are proven compatible engine facilities already present in the runtime, unlike importing a whole RTS starter. Original Blender automation supplies modelled geometry with merged static detail and named articulation. AI-assisted drawings establish art direction and foliage rather than masquerading as runtime screenshots.

The previously inspected primary sources and actual license obligations in `RTS_REUSE.md` remain applicable: BAR/Recoil gameplay code is GPL, media has separate restrictions, and a direct port would replace our engine. Architectural lessons worth retaining are a separate deterministic battle state, bounded transient effects, shared geometry/material batches and distinct player input/presentation. No BAR/Recoil code or assets are imported. Beehave is a compatible MIT candidate for later tactical AI complexity; adapting a behavior-tree addon for a few current policies costs more than extending this tested AI. Keep the pinned MIT formation integration; do not replace it with an unverified framework.

## Acceptance target

One playable IRON CROSSING battle, using the three existing roles and objectives. The new art reference is `art/concepts/iron-crossing-design.png`; the user explicitly required drawing assets before further model acceptance. Target independent turrets/recoil, clear tracked/wheeled silhouettes, elevation/road/woods/structures aligned with tactical rules, visible shells/impacts/wrecks, camera pan/zoom/rotation, tactical map, contextual commands/health indicators and diagnostics hidden by default. Retain customization in a modal workshop. A live scripted-input capture must show actual command/movement/combat, not a camera flythrough over a staged still.

Work in verified commits against this common target. Any remaining visual shortcomings must be stated. A signed APK is an export result; representative Android frame-time, memory and thermal acceptance requires a real attached device. No device was attached in the previous session; check again before claiming device results.

## Bounded AI blocker

Two defensive-AI attempts failed the unchanged baseline check `heavy armor siege is viable against AI` (11/12 checks passed each time). Attempt 1 added HQ/local threat response, standoff/retreat and a reserve guard. Attempt 2 restricted response to one reserve tank plus short-range artillery disengagement. The siege assertion still failed. Stop AI changes this session; restore the verified original attack/capture policy, do not weaken the regression or silently claim a new defensive policy. Next action: use battle replay/state evidence to design a balanced response policy in a separate task. Combat automatic targeting still responds to enemies in weapon range, but strategic HQ defense remains an unmet acceptance item.
