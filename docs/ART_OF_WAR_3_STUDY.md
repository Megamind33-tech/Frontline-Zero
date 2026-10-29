# Art of War 3 reference and FRONTLINE ZERO improvements

Reviewed 2026-10-29 from the [official Gear Games overview](https://aow3.geargames.org/) and [developer's Google Play listing](https://play.google.com/store/apps/details?id=com.geargames.aow&hl=en). This is a source-based product study, not a claim that we played, benchmarked or reverse-engineered the game. The listing advertises the systems below; it is not executable evidence of their quality. No source, assets, names, interface layout or network protocol were copied.

Our foundation stays **Godot 4.7.2 / fully 3D / Compatibility / Android**, including verified combat, custom vehicle blueprints, queues, formations, direct drive and local outcomes.

| Reference system advertised by Art of War 3 | FRONTLINE ZERO now | Improvement we can build and verify |
|---|---|---|
| Direct unit control and mobile RTS commands | Tap selection, move/focus, Hold, touch/keyboard drive; new bounded queues and formations | Make routes and queue state readable; add unit-clearance-aware obstacle routing with tests before larger maps. |
| Detailed 3D units and tactical variety | Three original animated vehicle roles; cover, mud and artillery minimum range | Keep distinct silhouettes and readable effects at phone camera scale; profile art on actual low-end hardware. New editable art pipeline enables this work. |
| Base building, infantry training and vehicle production | Pre-battle deployment budget; no construction/economy/production | Add one HQ producer, resource ledger, timed production queue, valid spawn placement and rally orders; then construction footprints and builder behavior. Test costs, cancellation/refunds, blocked spawning and save transitions. |
| Unit/building upgrades and faction-specific units | Modular chassis/weapon/armor with capacity/cost/stat validation | Extend universal research and meaningful tradeoffs; retain player-designed forces and fair competition as our design goals. Do not claim an existing research tree. |
| Infantry, armor, aircraft and warships | Ground scout/tank/artillery only | Add ground reconnaissance/anti-armor roles first, with fog/LOS and counterplay; later implement air/water movement and weapon domains with dedicated tests and original assets. |
| PvP, co-op, clans, ongoing World War | Offline AI battle and atomic local outcome history | Keep offline battles playable; later build authoritative match services and campaign ownership. Local saves are not multiplayer territorial warfare. |
| Campaigns for two factions | One offline battlefield, two original armies | Build objective variety and authored maps after navigation/production work, retaining Aster and Veyr identities. |

## Improvement order and acceptance gates

1. **Deliverable this session:** install/check Android and art tools, export and verify a signed debug APK, enable Android texture import, add an original app icon, save editable Blender sources, validate GLBs and supply an original SVG command sheet. This improves our build/art workflow; it does not add the reference game's missing gameplay systems.
2. **Next independently testable gameplay feature:** ground obstacle routing integrated with existing waypoint queues and formation destination slots. Tests must cover clearance, impassable destinations, unreachable routes, map edges, queue replacement, Hold/direct cancellation and the siege regression. Retain straight-line behavior on open ground. Review rendered results before claiming visual quality.
3. **Then the defining RTS loop:** resource income, one producer and timed unit production, followed by construction. Do not mix economy, fog, networking and new combat layers into one unreviewable change.
4. **Then reconnaissance and combined arms:** visibility/last-seen information, terrain-aware scouting and explicit counters, followed by original maps and offline campaign objectives.
5. **Online expansion last:** server authority, authentication, disconnect/reconnect, cheating/desync tests and campaign conflict resolution. Existing Godot transport APIs alone do not provide these systems.

Our intended advantages are dependable queued control, player-designed vehicles, understandable tactical tradeoffs, offline access, clear research and fair competition. These are design targets, not evidence that FRONTLINE ZERO already surpasses Art of War 3. Compare through playable builds, repeatable scenarios and phone frame-time/input tests.

## Reuse decisions

- **Godot built-ins (MIT):** keep the existing engine for 3D rendering, UI, navigation primitives, resources and transport. Prefer built-ins before adding runtime dependencies.
- **Existing RTS Advanced formation helper (MIT):** retain the pinned unchanged helper and notice. Do not replace verified formations with a starter project.
- **Blender / Inkscape / GIMP:** installed open-source authoring tools, not permissive gameplay code. GPL tool licenses remain with the programs; our original output has its own CC0 notice.
- **Beehave (MIT):** previously evaluated in `RTS_REUSE.md`; possible future AI tool, not needed for the current scripted AI or Android export. No unused addon imported.
- **Kenney:** optional asset candidate only. The Nature Kit page returned HTTP 403 on this host, so its package/license was not fetched or verified and no pack was imported. Use original generated art now; inspect the actual pack license before any future import.
- **BAR / Recoil:** no assets or GPL gameplay source imported. No engine switch. Android SDK/JDK remain external development tools under their own notices, not re-licensed game content.
