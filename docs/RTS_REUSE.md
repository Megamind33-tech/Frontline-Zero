# RTS reuse decision — 2026-10-29

Foundation: **Godot 4.7.2 / fully 3D Node3D scenes / Compatibility renderer**, with a horizontal ground simulation. Existing combat, blueprints, capture, local outcomes, direct unit control and siege regression remain. The browser reference is not the engine. Main baseline: `dfcff12deadfdec5182efed1f51a96490d264c58`; improvement branch: `reuse/formation-slots`.

Highest-value small gap: group commands used fixed 2.2 m offsets for vehicles up to 3.5 m long, with no travel-facing formation or slot assignment. Import only the standalone MIT formation helper, rather than adopting a starter project or changing engines. Command queues and obstacle-aware routing remain separate gaps.

Costs below are engineering judgments: Low = isolated adapter; Medium = several existing interfaces; High = architecture/backend/engine work. No phone benchmark is inferred from desktop performance.

| System | Existing implementation | Reuse candidate | License | Integration cost | Recommendation |
|---|---|---|---|---|---|
| Selection / command queues | Tap/select-all, move/focus/hold; one active order | Lite selection/orders; BAR architecture | Lite MIT; BAR GPL-2.0-or-later code | Medium | Keep selection; add queue semantics separately after movement. No BAR source import. |
| Formation movement / pathfinding | Fixed offsets, straight-line movement | Lite `RTSFormation`; Godot AStar3D or Lite grid navigation | MIT | **Low for formation**, Medium for routes | **Integrate only formation helper now**; routing needs obstacle/clearance tests. |
| Enemy tactical AI | Scripted attack/capture policy | Beehave behavior trees; BAR tactical architecture | Beehave MIT; BAR GPL | Medium / High | Retain current AI; evaluate Beehave when unit goals require trees. Not a drop-in RTS commander. |
| Fog / reconnaissance | None | Godot image/texture APIs + original visibility grid; study BAR concepts | Godot MIT; original game logic; BAR GPL if copied | Medium | Implement independent LOS/exploration rules later; Lite has no fog system. |
| Land / air / naval combat | Three ground roles, range/cooldown/cover | BAR/Recoil architecture; existing Godot engine APIs | GPL-2.0-or-later / Godot MIT | High for direct Recoil, Medium per native layer | Keep ground combat. Independently add altitude, water movement and weapon domains; no engine switch. |
| Construction / production | Deployment budget only | Lite production queue (not construction) | MIT | Medium | Reuse isolated queue after payment/spawn/rally adapters; construction still needs footprint rules. |
| Logistics / resources | Deployment credits, relay score | Lite economy/resource nodes | MIT | Medium | Credits/income useful later; transport, supply and ammunition remain original systems. |
| Multiplayer synchronization | None | Godot MultiplayerAPI/ENet; Recoil lockstep architecture | Godot MIT plus bundled third-party notices; Recoil GPL | High | Native server-authoritative validation needs protocol and desync tests; ENet alone supplies no RTS determinism. Defer. |
| Persistent territorial warfare | Atomic local outcomes, ownership/history | Existing FileAccess plus original authoritative campaign service | Godot MIT; service license undecided | High for online authority | Preserve local saves; no evaluated library supplies persistent national warfare. Defer server work. |

## Candidate verification

| Candidate | Actual source / obligations | Engine, dependencies, Android and maintenance |
|---|---|---|
| BAR gameplay | `license_general.txt` distinguishes code from assets; `CONTRIBUTING.md` specifies GPL v2-or-later. Distribution of GPL-derived code requires GPL-compliant licensing and corresponding source; GPL permits commerce, but is not a permissive proprietary-code import. Models/art/audio have separate licenses, including NC/ND restrictions; **none imported**. | Lua 5.1 and Spring/Recoil APIs; no Godot adapter. Active, not archived, pushed 2026-10-29. Direct port and Android performance unverified; high adaptation cost exceeds independent small systems. |
| Recoil | Actual `LICENSE`: GPL v2-or-later, with additional third-party BSD-style notices. Same source/distribution obligations apply to derived integrations. **No code imported.** | Separate C++ RTS engine, CMake/SDL2 and bundled toolchain/dependencies. Inspected official build instructions target Windows/Linux, amd64/arm64, not an Android export. ARM64 is not proof of Android support. Active, pushed 2026-10-29. No verified Android build or Godot binding; engine replacement violates scope. |
| Godot RTS Advanced Lite | Actual pinned `LICENSE`: MIT, copyright Huginhelm 2026. Preserve full copyright, permission and disclaimer when redistributing source or binaries. Only one unchanged source file imported with full license. Free Lite differs from paid Pro EULA; **no Pro material imported**. | README targets Godot 4.7/4.7.2, GDScript, Compatibility. Imported helper depends only on RefCounted, vectors, arrays and math; no editor plugin/native library/assets. Repository created 2026-10-15, pushed 2026-10-17, not archived: **recent, not established production proof**. Upstream claims 114 checks; we did not rerun its whole project. Our 22 integration checks pass. Android-target PCK tested on host, not an APK/device result. |
| Beehave | Actual `LICENSE`: MIT, copyright bitbrain 2023; retain notice/disclaimer if imported. Not imported this task. | Godot node-based behavior trees; 4.5+ compatibility listed for 2.10+. Requires addon and project-specific tasks/blackboard wiring, not a game-engine port. Repository dates to 2022, pushed 2026-09-20, not archived. No Android device/performance evidence collected; future profiling required. |
| Godot built-ins | Actual engine `LICENSE.txt`: MIT; retain Godot copyright/license and bundled third-party notices in releases. No new external runtime added. | Existing engine dependency. AStar3D supplies graph search, not automatic obstacle baking; MultiplayerAPI supplies transport/replication facilities, not campaign authority. Android target already configured; device/SDK/CI blockers remain in STATUS.md. |

## Integrated slice

`RTSFormation.box`, `.line` and `.assign` are vendored unchanged from commit `81e757ba2f144c10c18bc21daa06a6b0593661d3`. Our adapter converts horizontal simulation positions to/from XZ, reserves 3.8 m spacing and translates a whole formation at map edges so slots do not collapse. Greedy assignment reduces unnecessary travel but does **not** guarantee noncrossing routes, obstacle avoidance, collision separation, or formation preservation while moving. One touch button chooses Box/Line. Existing order replacement, focus fire and single-unit control remain.

The adapter covers current forces (at most 12 deployed units), not large armies. Work occurs per order, not per physics tick. Host benchmark: about 0.03 ms per 12-unit group command across 1,000 calls; no Android frame-time claim. MIT notice is explicitly included in both export presets and verified inside an Android-target resource pack. Full provenance: `godot/third_party/rts_advanced/ORIGIN.md`.

Identity remains: 3D military battles, player-designed vehicles/uniforms, universal research, meaningful command, persistent consequences, Android accessibility and fair competition. Aircraft, vessels, uniforms, ranks, research and national online warfare are future systems, not claims of existing implementation. No faction restrictions or monetization added.

## Primary sources checked

- [BAR license](https://github.com/beyond-all-reason/Beyond-All-Reason/blob/master/license_general.txt), [code licensing](https://github.com/beyond-all-reason/Beyond-All-Reason/blob/master/CONTRIBUTING.md)
- [Recoil license](https://github.com/beyond-all-reason/RecoilEngine/blob/master/LICENSE), [official build instructions](https://github.com/beyond-all-reason/RecoilEngine/blob/master/docker-build-v2/README.md), [CMake](https://github.com/beyond-all-reason/RecoilEngine/blob/master/CMakeLists.txt)
- [Pinned Lite license](https://github.com/openclawaimac/godot-rts-advanced-lite/blob/81e757ba2f144c10c18bc21daa06a6b0593661d3/LICENSE), [formation source](https://github.com/openclawaimac/godot-rts-advanced-lite/blob/81e757ba2f144c10c18bc21daa06a6b0593661d3/addons/rts_advanced/rts_formation.gd), [README](https://github.com/openclawaimac/godot-rts-advanced-lite/blob/81e757ba2f144c10c18bc21daa06a6b0593661d3/README.md)
- [Beehave license](https://github.com/bitbrain/beehave/blob/godot-4.x/LICENSE), [compatibility](https://github.com/bitbrain/beehave/blob/godot-4.x/README.md)
- [Godot 4.7.2 license](https://github.com/godotengine/godot/blob/4.7.2-stable/LICENSE.txt), [AStar3D](https://docs.godotengine.org/en/stable/classes/class_astar3d.html), [multiplayer](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html)
- Public repository metadata checked through GitHub API for archived/created/pushed status. Maintenance activity does not establish mobile performance or release quality.
