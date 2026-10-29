# IRON CROSSING — art direction and acceptance reference

Design before acceptance of model integration. Reference: `concepts/iron-crossing-design.png`, drawn in this session using an AI-assisted concept workflow after the user's design-first correction. Earlier mesh experiments are drafts, not accepted final art. The concept is not a runtime screenshot and its orthographic drawings are visual guides, not certified engineering plans.

## One coordinated target

A readable woodland-road battle in warm late-afternoon light: muted olive armor, sand camouflage, dark tracks/gunmetal, teal optics, pale identification marks; cool shadows, rough terrain, layered pine foliage and an unmistakable muddy road crossing. Avoid toy blocks, neon materials, full-screen debug panels and competing UI colors. The exact graphical finish must be judged in the engine at tactical and close camera distances; concept quality does not establish runtime quality.

| Role | Model reference and silhouette | Required articulation/details |
|---|---|---|
| Kestrel / scout | Six exposed all-terrain wheels; short hull and compact turret | Rotating turret, short autocannon, recoil, optics, antenna; six readable wheels. |
| Warden / tank | Low faceted turret, sloped hull, recessed roadwheels and side skirts | Independent turret/gun, recoil, continuous belt and tread shoes, engine louvres, hatch, armor cheek panels. |
| Bastion / artillery | Taller rear casemate and distinctly projecting barrel | Muzzle brake, gun recoil, tracked hull, ammunition locker; visibly different from Warden. |

Runtime hull footprints must remain compatible with the current formation clearance. Full-size combat statistics and existing team/blueprint distinctions are preserved; these are display names for the existing three roles, not three additional unit types.

Battlefield prop reference: pine with irregular branch foliage; grey rock outcrops; reinforced concrete command post; radio relay/dish; sandbag sections; worn asphalt, dirt trails and dark rutted mud. Cover/mud rendering must coincide with simulation rules, and decoration must leave usable travel lanes. Gentle elevation is visual: no new height-based combat advantage is implied.

## Gates

1. Draw the asset reference and establish silhouettes/material palette.
2. Build original Blender sources with named chassis/turret/recoil groups; merge static detail instead of exporting every bolt as a draw call. Retain asset provenance.
3. Validate Godot import, scale, animation and bounds; inspect an actual render against this sheet. No claim that a few bevels or a generated GLB constitute finished art.
4. Capture the running battle with commands, AI, damage and an outcome; screenshot and recording must come from Godot, never from the concept board.
5. Measure rendered host cost and APK packaging separately from representative-phone frame time/memory/thermals. Record unmet gates as blockers.

AI-assisted reference/foliage was generated originally for this project without input from proprietary game artwork. Procedural model geometry is authored in `scripts/build_battle_assets.py`. The user owns the generated outputs; no third-party pack, BAR art or GPL gameplay code is embedded. The existing formation MIT notice remains required.
