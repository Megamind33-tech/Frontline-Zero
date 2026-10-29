"""Original INF-001 rifleman. Blender 5.2: --background --python FILE -- OUTPUT_DIR.
No third-party bodies, clothing or motion-capture libraries.
"""
import bpy, bmesh, json, math, pathlib, random, sys
from mathutils import Vector

argv = sys.argv
out = pathlib.Path(argv[argv.index("--") + 1]).resolve() if "--" in argv else pathlib.Path("godot/assets/infantry")
out.mkdir(parents=True, exist_ok=True)
root = pathlib.Path(__file__).resolve().parents[1]
sheets = root / "art" / "infantry"
sheets.mkdir(parents=True, exist_ok=True)
blend_dir = root / ".tools" / "infantry-sources"
blend_dir.mkdir(parents=True, exist_ok=True)

bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete()
scene = bpy.context.scene
scene.unit_settings.system = "METRIC"
scene.unit_settings.scale_length = 1.0
scene.render.resolution_x = 720
scene.render.resolution_y = 1100
scene.render.film_transparent = False
for engine in ("BLENDER_EEVEE_NEXT", "BLENDER_EEVEE", "CYCLES"):
    try:
        scene.render.engine = engine
        break
    except TypeError:
        continue
if scene.render.engine == "CYCLES":
    scene.cycles.samples = 16
    scene.cycles.use_denoising = False
scene.view_settings.view_transform = "AgX"
world = bpy.data.worlds.new("Field")
scene.world = world
world.use_nodes = True
world.node_tree.nodes["Background"].inputs[0].default_value = (0.62, 0.66, 0.58, 1)

collection = bpy.data.collections.new("INF001")
scene.collection.children.link(collection)

def adopt(ob):
    for col in list(ob.users_collection):
        col.objects.unlink(ob)
    collection.objects.link(ob)
    return ob

def image_tex(name, paint):
    w = h = 256
    img = bpy.data.images.new(name, w, h, alpha=False)
    buf = [0.0] * (w * h * 4)
    rng = random.Random(name)
    for y in range(h):
        for x in range(w):
            u, v = x / w, y / h
            n = rng.random()
            weave = 0.5 + 0.5 * math.sin((x // 2) * 1.7) * math.sin((y // 2) * 1.3)
            r, g, b = paint(u, v, n, weave)
            i = (y * w + x) * 4
            buf[i:i + 4] = (r, g, b, 1)
    img.pixels.foreach_set(buf)
    img.pack()
    return img

def material(name, color, metal=0.0, rough=0.72, image=None, bump=0.15):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    mat.diffuse_color = (*color, 1)
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Metallic"].default_value = metal
    bsdf.inputs["Roughness"].default_value = rough
    if image:
        tex = mat.node_tree.nodes.new("ShaderNodeTexImage")
        tex.image = image
        mat.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
        bump_node = mat.node_tree.nodes.new("ShaderNodeBump")
        bump_node.inputs["Strength"].default_value = bump
        mat.node_tree.links.new(tex.outputs["Color"], bump_node.inputs["Height"])
        mat.node_tree.links.new(bump_node.outputs["Normal"], bsdf.inputs["Normal"])
    else:
        bsdf.inputs["Base Color"].default_value = (*color, 1)
    return mat

skin_img = image_tex("Skin", lambda u, v, n, w: (0.42 + 0.05 * n, 0.30 + 0.04 * w, 0.22 + 0.03 * n))
cloth_img = image_tex("Cloth", lambda u, v, n, w: (0.22 + 0.05 * w, 0.26 + 0.04 * n, 0.16))
vest_img = image_tex("Vest", lambda u, v, n, w: (0.16 + 0.03 * w, 0.18 + 0.02 * n, 0.13))
metal_img = image_tex("Metal", lambda u, v, n, w: (0.16 + 0.04 * n, 0.17, 0.15 + 0.02 * w))
SKIN = material("Skin", (0.45, 0.32, 0.24), 0, 0.52, skin_img, 0.08)
CLOTH = material("Cloth", (0.24, 0.28, 0.18), 0, 0.84, cloth_img, 0.22)
VEST = material("Vest", (0.14, 0.16, 0.12), 0.05, 0.7, vest_img, 0.18)
BOOT = material("Boot", (0.08, 0.07, 0.06), 0.02, 0.62, cloth_img, 0.12)
METAL = material("Metal", (0.18, 0.19, 0.17), 0.82, 0.34, metal_img, 0.05)
POLYMER = material("Polymer", (0.05, 0.05, 0.045), 0.15, 0.48, metal_img, 0.04)
PALE = material("Insignia", (0.78, 0.76, 0.62), 0, 0.55)
EYE = material("Eye", (0.12, 0.16, 0.14), 0.1, 0.18)

def recalc(ob):
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(ob.data)
    bm.free()
    for poly in ob.data.polygons:
        poly.use_smooth = True

def add_loft(name, rings, mat):
    bm = bmesh.new()
    grid = []
    for ring in rings:
        grid.append([bm.verts.new(p) for p in ring])
    sides = len(rings[0])
    for i in range(len(rings) - 1):
        for j in range(sides):
            j2 = (j + 1) % sides
            bm.faces.new((grid[i][j], grid[i][j2], grid[i + 1][j2], grid[i + 1][j]))
    bm.faces.new(tuple(reversed(grid[0])))
    bm.faces.new(tuple(grid[-1]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    ob = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(ob)
    adopt(ob)
    ob.data.materials.append(mat)
    recalc(ob)
    return ob

def basis(direction):
    z = direction.normalized()
    helper = Vector((0, 0, 1)) if abs(z.z) < 0.92 else Vector((0, 1, 0))
    x = z.cross(helper).normalized()
    y = z.cross(x).normalized()
    return x, y, z

def segment_rings(a, b, ra, rb, sides=10, steps=4, bulge=0.0, flatten=1.0):
    x, y, z = basis(b - a)
    rings = []
    for step in range(steps + 1):
        t = step / steps
        center = a.lerp(b, t)
        radius = (ra * (1 - t) + rb * t) * (1 + bulge * math.sin(math.pi * t))
        ring = []
        for i in range(sides):
            ang = 2 * math.pi * i / sides
            ring.append(center + x * (math.cos(ang) * radius) + y * (math.sin(ang) * radius * flatten))
        rings.append(ring)
    return rings

def weight_rings(ob, bone, parent, steps, sides):
    primary = ob.vertex_groups.new(name=bone)
    secondary = ob.vertex_groups.new(name=parent) if parent else None
    for step in range(steps + 1):
        t = step / steps
        indices = list(range(step * sides, (step + 1) * sides))
        primary.add(indices, t, "REPLACE")
        if secondary:
            secondary.add(indices, 1 - t, "REPLACE")

def limb(name, a, b, ra, rb, mat, bone, parent, sides=10, steps=4, bulge=0.12, flatten=0.86):
    ob = add_loft(name, segment_rings(a, b, ra, rb, sides, steps, bulge, flatten), mat)
    weight_rings(ob, bone, parent, steps, sides)
    return ob

def uv_project(ob):
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=1.05, island_margin=0.02)
    bpy.ops.object.mode_set(mode="OBJECT")

def fabric_group():
    group = bpy.data.node_groups.new("INF_FabricFolds", "GeometryNodeTree")
    group.interface.new_socket(name="Geometry", in_out="INPUT", socket_type="NodeSocketGeometry")
    group.interface.new_socket(name="Geometry", in_out="OUTPUT", socket_type="NodeSocketGeometry")
    nodes, links = group.nodes, group.links
    gi = nodes.new("NodeGroupInput")
    go = nodes.new("NodeGroupOutput")
    noise = nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 28.0
    noise.inputs["Detail"].default_value = 3.0
    sub = nodes.new("ShaderNodeMath")
    sub.operation = "SUBTRACT"
    sub.inputs[1].default_value = 0.5
    amp = nodes.new("ShaderNodeMath")
    amp.operation = "MULTIPLY"
    amp.inputs[1].default_value = 0.0025
    normal = nodes.new("GeometryNodeInputNormal")
    scale = nodes.new("ShaderNodeVectorMath")
    scale.operation = "SCALE"
    setpos = nodes.new("GeometryNodeSetPosition")
    links.new(gi.outputs["Geometry"], setpos.inputs["Geometry"])
    links.new(noise.outputs["Fac"], sub.inputs[0])
    links.new(sub.outputs[0], amp.inputs[0])
    links.new(normal.outputs["Normal"], scale.inputs[0])
    links.new(amp.outputs["Value"], scale.inputs["Scale"])
    links.new(scale.outputs["Vector"], setpos.inputs["Offset"])
    links.new(setpos.outputs["Geometry"], go.inputs["Geometry"])
    return group

FOLDS = fabric_group()

def thicken(ob, depth=0.004, folds=True):
    bpy.context.view_layer.objects.active = ob
    if folds:
        mod = ob.modifiers.new("Folds", "NODES")
        mod.node_group = FOLDS
        bpy.ops.object.modifier_apply(modifier=mod.name)
    solid = ob.modifiers.new("Thickness", "SOLIDIFY")
    solid.thickness = depth
    solid.offset = 1
    bpy.ops.object.modifier_apply(modifier=solid.name)
    uv_project(ob)
    return ob

def torso():
    rings = []
    specs = [
        (0.92, 0.13, 0.10, 0.00),
        (1.02, 0.145, 0.11, -0.01),
        (1.16, 0.16, 0.12, -0.015),
        (1.30, 0.175, 0.125, -0.02),
        (1.42, 0.16, 0.11, -0.01),
        (1.50, 0.09, 0.08, 0.0),
    ]
    for z, rx, ry, forward in specs:
        ring = []
        for i in range(12):
            ang = 2 * math.pi * i / 12
            chest = max(0, -math.sin(ang))
            ring.append(Vector((math.cos(ang) * rx * (1 - 0.08 * chest), forward - math.sin(ang) * ry, z)))
        rings.append(ring)
    ob = add_loft("Torso", rings, SKIN)
    weight_rings(ob, "Chest", "Hips", 5, 12)
    uv_project(ob)
    return ob

def head():
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=3, radius=1, location=(0, 0, 0))
    ob = bpy.context.object
    adopt(ob)
    ob.name = "Head"
    for v in ob.data.vertices:
        x, y, z = v.co
        jaw = max(0, -z - 0.05)
        x *= 0.78 - 0.08 * jaw
        y *= 0.9
        z *= 1.08 if z > 0 else 0.9
        if abs(x) < 0.18 and y < -0.05 and -0.15 < z < 0.28:
            y -= 0.22 * (1 - abs(x) / 0.18) * max(0, 1 - abs(z - 0.05) / 0.28)
        if abs(x) < 0.22 and abs(z - 0.05) < 0.08 and y < -0.2:
            y += 0.05
        if 0.18 < abs(x) < 0.42 and abs(z - 0.08) < 0.12 and y < 0:
            y += 0.06
        v.co = Vector((x, y, z))
    ob.scale = (0.075, 0.086, 0.10)
    bpy.ops.object.transform_apply(scale=True)
    ob.location = (0, -0.01, 1.64)
    bpy.ops.object.transform_apply(location=True)
    ob.data.materials.append(SKIN)
    vg = ob.vertex_groups.new(name="Head")
    vg.add(list(range(len(ob.data.vertices))), 1, "REPLACE")
    uv_project(ob)
    for side in (-1, 1):
        bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=0.012, location=(side * 0.028, -0.072, 1.665))
        eye = bpy.context.object
        adopt(eye)
        eye.name = "Eye.%s" % ("L" if side > 0 else "R")
        eye.data.materials.append(EYE)
        eye.vertex_groups.new(name="Head").add(list(range(len(eye.data.vertices))), 1, "REPLACE")
        ear = limb("Ear.%s" % ("L" if side > 0 else "R"), Vector((side * 0.06, 0.0, 1.64)), Vector((side * 0.085, -0.005, 1.63)), 0.02, 0.012, SKIN, "Head", "Head", 8, 2, 0.2, 0.45)
        uv_project(ear)
    hair = add_loft("Hair", segment_rings(Vector((0, 0.01, 1.69)), Vector((0, -0.005, 1.75)), 0.078, 0.07, 10, 2, 0.05, 0.9), material("Hair", (0.08, 0.07, 0.06), 0, 0.7))
    hair.vertex_groups.new(name="Head").add(list(range(len(hair.data.vertices))), 1, "REPLACE")
    return ob

def hands(side, wrist, bone):
    palm = limb("Palm.%s" % side, wrist, wrist + Vector((0.01 * (1 if side == "L" else -1), -0.06, -0.02)), 0.028, 0.022, SKIN, bone, bone, 8, 2, 0.05, 0.55)
    for index, spread in enumerate((-0.018, -0.006, 0.006, 0.016)):
        a = wrist + Vector((spread, -0.055, -0.02))
        b = a + Vector((spread * 0.3, -0.055, -0.012))
        limb("Finger.%s.%d" % (side, index), a, b, 0.009, 0.006, SKIN, "Fingers." + side, bone, 6, 3, 0.15, 0.8)
    thumb_a = wrist + Vector((0.02 if side == "L" else -0.02, -0.03, -0.01))
    limb("Thumb.%s" % side, thumb_a, thumb_a + Vector((0.02 if side == "L" else -0.02, -0.02, 0.005)), 0.01, 0.007, SKIN, "Thumb." + side, bone, 6, 2, 0.1, 0.8)
    return palm

def build_body():
    torso()
    head()
    hip_l, hip_r = Vector((0.09, 0, 0.94)), Vector((-0.09, 0, 0.94))
    knee_l, knee_r = Vector((0.09, 0.015, 0.50)), Vector((-0.09, 0.015, 0.50))
    ankle_l, ankle_r = Vector((0.10, 0.0, 0.08)), Vector((-0.10, 0.0, 0.08))
    limb("Thigh.L", hip_l, knee_l, 0.075, 0.055, SKIN, "Thigh.L", "Hips", 10, 4, 0.08)
    limb("Shin.L", knee_l, ankle_l, 0.05, 0.038, SKIN, "Shin.L", "Thigh.L", 10, 4, 0.06)
    limb("Thigh.R", hip_r, knee_r, 0.075, 0.055, SKIN, "Thigh.R", "Hips")
    limb("Shin.R", knee_r, ankle_r, 0.05, 0.038, SKIN, "Shin.R", "Thigh.R")
    foot_l, foot_r = ankle_l + Vector((0, -0.14, -0.04)), ankle_r + Vector((0, -0.14, -0.04))
    limb("Foot.L", ankle_l, foot_l, 0.038, 0.03, SKIN, "Foot.L", "Shin.L", 8, 3, 0.02, 0.7)
    limb("Foot.R", ankle_r, foot_r, 0.038, 0.03, SKIN, "Foot.R", "Shin.R", 8, 3, 0.02, 0.7)
    shoulder_l, elbow_l, wrist_l = Vector((0.18, -0.02, 1.44)), Vector((0.20, -0.05, 1.18)), Vector((0.12, -0.22, 1.05))
    shoulder_r, elbow_r, wrist_r = Vector((-0.18, -0.02, 1.44)), Vector((-0.16, -0.10, 1.16)), Vector((-0.08, -0.28, 1.08))
    limb("UpperArm.L", shoulder_l, elbow_l, 0.055, 0.048, SKIN, "UpperArm.L", "Chest")
    limb("ForeArm.L", elbow_l, wrist_l, 0.044, 0.034, SKIN, "ForeArm.L", "UpperArm.L")
    limb("UpperArm.R", shoulder_r, elbow_r, 0.055, 0.048, SKIN, "UpperArm.R", "Chest")
    limb("ForeArm.R", elbow_r, wrist_r, 0.044, 0.034, SKIN, "ForeArm.R", "UpperArm.R")
    hands("L", wrist_l, "Hand.L")
    hands("R", wrist_r, "Hand.R")

def clothing():
    hip_l, knee_l, ankle_l = Vector((0.09, 0, 0.96)), Vector((0.09, 0.015, 0.50)), Vector((0.10, 0, 0.09))
    hip_r, knee_r, ankle_r = Vector((-0.09, 0, 0.96)), Vector((-0.09, 0.015, 0.50)), Vector((-0.10, 0, 0.09))
    for side, hip, knee, ankle in (("L", hip_l, knee_l, ankle_l), ("R", hip_r, knee_r, ankle_r)):
        trouser = limb("Trouser." + side, hip, knee, 0.092, 0.07, CLOTH, "Thigh." + side, "Hips", bulge=0.05)
        thicken(trouser, 0.003)
        shin = limb("TrouserShin." + side, knee, ankle, 0.066, 0.05, CLOTH, "Shin." + side, "Thigh." + side)
        thicken(shin, 0.003)
        boot = limb("Boot." + side, ankle, ankle + Vector((0, -0.16, -0.045)), 0.05, 0.038, BOOT, "Foot." + side, "Shin." + side, 8, 3, 0.04, 0.62)
        thicken(boot, 0.004, False)
        pad = limb("Knee." + side, knee + Vector((0, -0.02, 0.02)), knee + Vector((0, -0.045, -0.04)), 0.04, 0.03, VEST, "Thigh." + side, "Shin." + side, 8, 2, 0.1, 0.4)
        thicken(pad, 0.003, False)
        pad.name = "KneePads." + side
    rings = []
    for z, rx, ry in ((1.02, 0.17, 0.14), (1.18, 0.19, 0.155), (1.34, 0.20, 0.15), (1.46, 0.15, 0.12)):
        rings.append([Vector((math.cos(a) * rx, -0.02 - math.sin(a) * ry, z)) for a in [2 * math.pi * i / 12 for i in range(12)]])
    shirt = add_loft("Shirt", rings, CLOTH)
    weight_rings(shirt, "Chest", "Hips", 3, 12)
    thicken(shirt, 0.003)
    vest = add_loft("Vest", rings[1:], VEST)
    weight_rings(vest, "Chest", "Chest", 2, 12)
    thicken(vest, 0.006, False)
    inserts = add_loft("VestInserts", [rings[1], rings[2]], POLYMER)
    weight_rings(inserts, "Chest", "Chest", 1, 12)
    thicken(inserts, 0.004, False)
    shoulder_l, elbow_l, wrist_l = Vector((0.18, -0.02, 1.44)), Vector((0.20, -0.05, 1.18)), Vector((0.12, -0.22, 1.05))
    shoulder_r, elbow_r, wrist_r = Vector((-0.18, -0.02, 1.44)), Vector((-0.16, -0.10, 1.16)), Vector((-0.08, -0.28, 1.08))
    for side, a, b, c in (("L", shoulder_l, elbow_l, wrist_l), ("R", shoulder_r, elbow_r, wrist_r)):
        sleeve = limb("Sleeve." + side, a, b, 0.07, 0.06, CLOTH, "UpperArm." + side, "Chest")
        thicken(sleeve)
        fore = limb("SleeveFore." + side, b, c, 0.056, 0.045, CLOTH, "ForeArm." + side, "UpperArm." + side)
        thicken(fore)
        glove = limb("Glove." + side, c, c + Vector((0, -0.05, -0.015)), 0.04, 0.028, BOOT, "Hand." + side, "ForeArm." + side, 8, 2, 0.02, 0.6)
        thicken(glove, 0.003, False)
        elbow = limb("Elbow." + side, b + Vector((0, -0.02, 0.02)), b + Vector((0, -0.04, -0.03)), 0.03, 0.022, VEST, "UpperArm." + side, "ForeArm." + side, 8, 2, 0.1, 0.45)
        thicken(elbow, 0.003, False)
        elbow.name = "ElbowPads." + side
    belt_rings = []
    for z in (0.99, 1.04):
        belt_rings.append([Vector((math.cos(a) * 0.18, -0.01 - math.sin(a) * 0.13, z)) for a in [2 * math.pi * i / 12 for i in range(12)]])
    belt = add_loft("Belt", belt_rings, BOOT)
    belt.vertex_groups.new(name="Hips").add(list(range(len(belt.data.vertices))), 1, "REPLACE")
    thicken(belt, 0.005, False)
    for i, x in enumerate((-0.06, -0.02, 0.03)):
        pouch = limb("MagPouch.%d" % i, Vector((x, -0.12, 1.0)), Vector((x, -0.15, 0.90)), 0.028, 0.024, VEST, "Hips", "Hips", 8, 2, 0.05, 0.7)
        thicken(pouch, 0.002, False)
    utility = limb("UtilityPouch", Vector((0.10, -0.11, 1.0)), Vector((0.11, -0.145, 0.92)), 0.032, 0.026, CLOTH, "Hips", "Hips", 8, 2)
    thicken(utility, 0.002, False)
    helmet = add_loft("Helmet", segment_rings(Vector((0, 0.0, 1.70)), Vector((0, -0.01, 1.78)), 0.092, 0.05, 12, 3, 0.06, 0.95), VEST)
    helmet.vertex_groups.new(name="Head").add(list(range(len(helmet.data.vertices))), 1, "REPLACE")
    thicken(helmet, 0.004, False)
    cover = add_loft("HelmetCover", segment_rings(Vector((0, 0.0, 1.705)), Vector((0, -0.012, 1.785)), 0.098, 0.055, 12, 2, 0.04), CLOTH)
    cover.vertex_groups.new(name="Head").add(list(range(len(cover.data.vertices))), 1, "REPLACE")
    thicken(cover, 0.002, False)
    radio = limb("Radio", Vector((0.12, 0.06, 1.28)), Vector((0.13, 0.05, 1.18)), 0.035, 0.03, POLYMER, "Chest", "Chest", 8, 2, 0.05, 0.7)
    thicken(radio, 0.002, False)
    antenna = limb("Antenna", Vector((0.13, 0.04, 1.30)), Vector((0.16, 0.02, 1.52)), 0.004, 0.003, METAL, "Chest", "Chest", 6, 3, 0, 1)
    pack = limb("Backpack", Vector((0, 0.08, 1.38)), Vector((0, 0.12, 1.12)), 0.11, 0.09, CLOTH, "Chest", "Hips", 10, 3, 0.08, 0.75)
    thicken(pack, 0.004)
    for name, loc in (("InsigniaRecruit", Vector((0.16, -0.08, 1.40))), ("InsigniaVeteran", Vector((-0.16, -0.08, 1.40))), ("InsigniaElite", Vector((0, -0.16, 1.22))), ("InsigniaLegendary", Vector((0.0, -0.02, 1.70)))):
        mark = limb(name, loc, loc + Vector((0.03, -0.005, 0.02)), 0.012, 0.008, PALE, "Chest", "Chest", 6, 1, 0, 0.4)
        uv_project(mark)
    pauldron = limb("Pauldron", Vector((-0.18, -0.03, 1.46)), Vector((-0.24, -0.04, 1.42)), 0.045, 0.03, VEST, "UpperArm.R", "Chest", 8, 2, 0.1)
    thicken(pauldron, 0.003, False)

def weapon():
    grip = Vector((-0.04, -0.30, 1.08))
    muzzle = Vector((-0.02, -0.78, 1.20))
    receiver = limb("Receiver", grip + Vector((0, 0.02, 0.04)), grip + Vector((0.01, -0.16, 0.07)), 0.028, 0.022, METAL, "Weapon", "Hand.R", 8, 4, 0.05, 0.72)
    barrel = limb("Barrel", grip + Vector((0.01, -0.16, 0.07)), muzzle, 0.012, 0.009, METAL, "Weapon", "Hand.R", 8, 6, 0, 1)
    stock = limb("Stock", grip + Vector((0, 0.02, 0.03)), grip + Vector((0.01, 0.16, -0.02)), 0.02, 0.016, POLYMER, "Weapon", "Hand.R", 8, 3, 0.04, 0.55)
    handguard = limb("Handguard", grip + Vector((0.01, -0.08, 0.05)), grip + Vector((0.01, -0.28, 0.09)), 0.02, 0.016, POLYMER, "Weapon", "Hand.R", 8, 3, 0.02, 0.8)
    handle = limb("Grip", grip + Vector((0, 0.01, 0.03)), grip + Vector((0, 0.015, -0.07)), 0.016, 0.014, POLYMER, "Weapon", "Hand.R", 8, 3, 0.08, 0.7)
    magazine = limb("Magazine", grip + Vector((0, -0.02, 0.0)), grip + Vector((0, 0.01, -0.12)), 0.016, 0.014, POLYMER, "Weapon", "Hand.R", 6, 3, 0.04, 0.6)
    sight = limb("Sight", grip + Vector((0.01, -0.12, 0.075)), grip + Vector((0.01, -0.16, 0.10)), 0.008, 0.006, METAL, "Weapon", "Hand.R", 6, 2)
    sling = limb("Sling", grip + Vector((0, 0.08, 0.02)), Vector((-0.12, -0.05, 1.25)), 0.004, 0.004, CLOTH, "Chest", "Hand.R", 6, 4, 0, 1)
    for part in (receiver, barrel, stock, handguard, handle, magazine, sight, sling):
        uv_project(part)
    empty = bpy.data.objects.new("Muzzle", None)
    bpy.context.collection.objects.link(empty)
    adopt(empty)
    empty.location = muzzle
    empty.parent = barrel
    return receiver

def armature():
    arm = bpy.data.armatures.new("INF001")
    obj = bpy.data.objects.new("INF001_Armature", arm)
    bpy.context.collection.objects.link(obj)
    adopt(obj)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode="EDIT")
    def bone(name, head, tail, parent=None):
        edit = arm.edit_bones.new(name)
        edit.head, edit.tail = head, tail
        if parent:
            edit.parent = arm.edit_bones[parent]
        edit.align_roll(Vector((0, -1, 0)))
        return edit
    bone("Root", Vector((0, 0, 0.92)), Vector((0, 0, 0.98)))
    bone("Hips", Vector((0, 0, 0.98)), Vector((0, 0, 1.12)), "Root")
    bone("Spine", Vector((0, 0, 1.12)), Vector((0, -0.01, 1.30)), "Hips")
    bone("Chest", Vector((0, -0.01, 1.30)), Vector((0, -0.01, 1.50)), "Spine")
    bone("Neck", Vector((0, -0.01, 1.50)), Vector((0, -0.01, 1.58)), "Chest")
    bone("Head", Vector((0, -0.01, 1.58)), Vector((0, -0.02, 1.76)), "Neck")
    bone("UpperArm.L", Vector((0.18, -0.02, 1.44)), Vector((0.20, -0.05, 1.18)), "Chest")
    bone("ForeArm.L", Vector((0.20, -0.05, 1.18)), Vector((0.12, -0.22, 1.05)), "UpperArm.L")
    bone("Hand.L", Vector((0.12, -0.22, 1.05)), Vector((0.10, -0.30, 1.02)), "ForeArm.L")
    bone("Fingers.L", Vector((0.10, -0.28, 1.02)), Vector((0.08, -0.34, 1.0)), "Hand.L")
    bone("Thumb.L", Vector((0.13, -0.24, 1.04)), Vector((0.15, -0.27, 1.045)), "Hand.L")
    bone("UpperArm.R", Vector((-0.18, -0.02, 1.44)), Vector((-0.16, -0.10, 1.16)), "Chest")
    bone("ForeArm.R", Vector((-0.16, -0.10, 1.16)), Vector((-0.08, -0.28, 1.08)), "UpperArm.R")
    bone("Hand.R", Vector((-0.08, -0.28, 1.08)), Vector((-0.04, -0.34, 1.07)), "ForeArm.R")
    bone("Fingers.R", Vector((-0.05, -0.33, 1.07)), Vector((-0.03, -0.38, 1.06)), "Hand.R")
    bone("Thumb.R", Vector((-0.07, -0.30, 1.09)), Vector((-0.09, -0.33, 1.095)), "Hand.R")
    bone("Weapon", Vector((-0.04, -0.30, 1.08)), Vector((-0.02, -0.78, 1.20)), "Hand.R")
    bone("Thigh.L", Vector((0.09, 0, 0.94)), Vector((0.09, 0.015, 0.50)), "Hips")
    bone("Shin.L", Vector((0.09, 0.015, 0.50)), Vector((0.10, 0, 0.08)), "Thigh.L")
    bone("Foot.L", Vector((0.10, 0, 0.08)), Vector((0.10, -0.14, 0.02)), "Shin.L")
    bone("Thigh.R", Vector((-0.09, 0, 0.94)), Vector((-0.09, 0.015, 0.50)), "Hips")
    bone("Shin.R", Vector((-0.09, 0.015, 0.50)), Vector((-0.10, 0, 0.08)), "Thigh.R")
    bone("Foot.R", Vector((-0.10, 0, 0.08)), Vector((-0.10, -0.14, 0.02)), "Shin.R")
    bpy.ops.object.mode_set(mode="OBJECT")
    return obj

def parent_meshes(arm_obj):
    for ob in list(collection.objects):
        if ob.type != "MESH":
            continue
        ob.parent = arm_obj
        mod = ob.modifiers.new("Armature", "ARMATURE")
        mod.object = arm_obj

def pose_action(arm_obj, name, samples):
    ad = arm_obj.animation_data or arm_obj.animation_data_create()
    action = bpy.data.actions.new(name)
    slot = action.slots.new(id_type="OBJECT", name=arm_obj.name)
    ad.action = action
    ad.action_slot = slot
    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.object.mode_set(mode="POSE")
    for frame, values in samples:
        scene.frame_set(frame)
        for bone_name, rotation in values.items():
            pose = arm_obj.pose.bones[bone_name]
            pose.rotation_mode = "XYZ"
            pose.rotation_euler = rotation
            pose.keyframe_insert("rotation_euler", frame=frame)
    for pose in arm_obj.pose.bones:
        pose.rotation_euler = (0, 0, 0)
    bpy.ops.object.mode_set(mode="OBJECT")
    track = ad.nla_tracks.new()
    track.name = name
    strip = track.strips.new(name, 1, action)
    strip.action_slot = slot
    strip.mute = True
    action.use_fake_user = True
    return action

def deg(x, y=0, z=0):
    return (math.radians(x), math.radians(y), math.radians(z))

def animate(arm_obj):
    def swing(frame, amount, lift):
        phase = frame / 12.0 * math.pi
        return {
            "Thigh.L": deg(28 * math.sin(phase)),
            "Shin.L": deg(max(0, 32 * math.cos(phase))),
            "Foot.L": deg(-10 * math.sin(phase)),
            "Thigh.R": deg(28 * math.sin(phase + math.pi)),
            "Shin.R": deg(max(0, 32 * math.cos(phase + math.pi))),
            "Foot.R": deg(-10 * math.sin(phase + math.pi)),
            "UpperArm.L": deg(-12 * math.sin(phase)),
            "Chest": deg(2 * math.sin(phase * 2), 0, 3 * math.sin(phase)),
            "Hips": deg(0, 0, -3 * math.sin(phase)),
        }
    idle = [(1, {"Chest": deg(0, 0, 0)}), (20, {"Chest": deg(3, 0, 0), "Head": deg(-2, 0, 0)}), (40, {"Chest": deg(0, 0, 0)})]
    walk = [(f, swing(f, 1, 1)) for f in (1, 6, 12, 18, 24)]
    run = [(f, swing(f, 1.4, 1.4)) for f in (1, 5, 10, 15, 20)]
    for frame, values in run:
        values["Chest"] = deg(12, 0, values["Chest"][2] * 57.3)
        values["Thigh.L"] = deg(values["Thigh.L"][0] * 70, 0, 0)
    crouch = [(1, {"Thigh.L": deg(55), "Thigh.R": deg(55), "Shin.L": deg(70), "Shin.R": deg(70), "Chest": deg(18), "Head": deg(-8)})]
    aim = [(1, {"UpperArm.R": deg(-55), "ForeArm.R": deg(-20), "UpperArm.L": deg(-70), "Head": deg(-4)})]
    fire = [(1, aim[0][1]), (3, {"Chest": deg(-4), "Head": deg(2), "UpperArm.R": deg(-48)}), (7, aim[0][1])]
    reload = [(1, {"UpperArm.R": deg(-20), "ForeArm.R": deg(-40), "Chest": deg(8)}), (8, {"ForeArm.L": deg(-30), "Chest": deg(12)}), (16, aim[0][1])]
    cover = [(1, {"Thigh.L": deg(70), "Shin.L": deg(80), "Thigh.R": deg(20), "Chest": deg(30), "Head": deg(-12)})]
    enter = [(1, {"Thigh.R": deg(80), "Shin.R": deg(40), "Chest": deg(25), "UpperArm.L": deg(-30)})]
    exit = [(1, {"Thigh.L": deg(60), "Chest": deg(15)}), (10, {})]
    interact = [(1, {"UpperArm.R": deg(-30), "ForeArm.R": deg(-50), "Chest": deg(10)})]
    hit = [(1, {"Chest": deg(-12, 18, 0), "Head": deg(10, 12, 0), "UpperArm.L": deg(20)})]
    down = [(1, {"Hips": deg(80), "Chest": deg(70), "Thigh.L": deg(10), "Thigh.R": deg(10), "Head": deg(20)})]
    clips = {
        "Idle": idle, "Walk": walk, "Run": run, "Crouch": crouch, "Aim": aim, "Fire": fire,
        "Reload": reload, "TakeCover": cover, "EnterVehicle": enter, "ExitVehicle": exit,
        "Interact": interact, "Hit": hit, "Incapacitation": down,
    }
    for name, samples in clips.items():
        pose_action(arm_obj, name, samples)

def collision():
    ob = limb("INF001_Collision", Vector((0, 0, 0.15)), Vector((0, 0, 1.7)), 0.22, 0.16, POLYMER, "Hips", "Root", 8, 3, 0.0, 0.7)
    ob.display_type = "WIRE"
    ob.hide_render = True
    return ob

def lod_copy(ratio, suffix):
    meshes = [ob for ob in collection.objects if ob.type == "MESH" and ob.name != "INF001_Collision"]
    bpy.ops.object.select_all(action="DESELECT")
    for ob in meshes:
        ob.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.duplicate()
    clones = list(bpy.context.selected_objects)
    for ob in clones:
        ob.name = ob.name.split(".")[0] + suffix
        bpy.context.view_layer.objects.active = ob
        mod = ob.modifiers.new("LOD", "DECIMATE")
        mod.ratio = ratio
        bpy.ops.object.modifier_apply(modifier=mod.name)
        for col in list(ob.users_collection):
            col.objects.unlink(ob)
    lod = bpy.data.collections.new("INF001" + suffix)
    scene.collection.children.link(lod)
    for ob in clones:
        lod.objects.link(ob)
    return lod

def export_collection(col, path):
    bpy.ops.object.select_all(action="DESELECT")
    for ob in col.objects:
        ob.select_set(True)
    if col.objects:
        bpy.context.view_layer.objects.active = col.objects[0]
    bpy.ops.export_scene.gltf(filepath=str(path), export_format="GLB", export_animations=True, export_skins=True, use_selection=True, export_yup=True)

def look(cam, target):
    cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()

def shoot(path, location, target, ortho=None):
    camera = bpy.data.cameras.new("View")
    camera.type = "ORTHO" if ortho else "PERSP"
    if ortho:
        camera.ortho_scale = ortho
    else:
        camera.lens = 50
    obj = bpy.data.objects.new("View", camera)
    scene.collection.objects.link(obj)
    obj.location = location
    obj.rotation_euler = (target - obj.location).to_track_quat("-Z", "Z").to_euler()
    sun = bpy.data.lights.new("Sun", "SUN")
    sun.energy = 3.5
    sun_obj = bpy.data.objects.new("Sun", sun)
    scene.collection.objects.link(sun_obj)
    sun_obj.rotation_euler = (math.radians(50), 0, math.radians(-30))
    scene.camera = obj
    scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(obj, do_unlink=True)

def hide_except(names):
    for ob in collection.objects:
        if ob.type == "MESH":
            ob.hide_render = ob.name not in names and not ob.name.startswith("Body") and ob.name not in ("Head", "Hair", "Torso") and not ob.name.startswith("Eye") and not ob.name.startswith("Ear") and not ob.name.startswith("Palm") and not ob.name.startswith("Finger") and not ob.name.startswith("Thumb") and not ob.name.startswith("Thigh") and not ob.name.startswith("Shin") and not ob.name.startswith("Foot") and not ob.name.startswith("UpperArm") and not ob.name.startswith("ForeArm")

def main():
    build_body()
    clothing()
    weapon()
    arm = armature()
    collision()
    parent_meshes(arm)
    animate(arm)
    for ob in list(collection.objects):
        if ob.type == "MESH" and "UVMap" not in ob.data.uv_layers:
            uv_project(ob)
    tris = sum(len(ob.data.polygons) for ob in collection.objects if ob.type == "MESH" and ob.name != "INF001_Collision")
    lod1 = lod_copy(0.45, "_LOD1")
    lod2 = lod_copy(0.2, "_LOD2")
    bpy.ops.wm.save_as_mainfile(filepath=str(blend_dir / "inf001_rifleman.blend"))
    export_collection(collection, out / "inf001_rifleman.glb")
    export_collection(lod1, out / "inf001_rifleman_lod1.glb")
    export_collection(lod2, out / "inf001_rifleman_lod2.glb")
    arm.data.pose_position = "REST"
    arm.hide_render = True
    center = Vector((0, 0, 0.95))
    views = {
        "front": (Vector((0, -3.2, 0.95)), 2.05),
        "back": (Vector((0, 3.2, 0.95)), 2.05),
        "left": (Vector((-3.2, 0, 0.95)), 2.05),
        "right": (Vector((3.2, 0, 0.95)), 2.05),
        "top": (Vector((0, -0.2, 4.2)), 1.4),
        "three_quarter": (Vector((1.8, -2.4, 1.5)), None),
    }
    for name, (loc, ortho) in views.items():
        shoot(sheets / ("inf001_" + name + ".png"), loc, center, ortho)
    shoot(sheets / "inf001_helmet.png", Vector((0.4, -1.1, 1.7)), Vector((0, 0, 1.68)), 0.45)
    shoot(sheets / "inf001_vest.png", Vector((0.2, -1.3, 1.25)), Vector((0, 0, 1.25)), 0.7)
    shoot(sheets / "inf001_belt.png", Vector((0.3, -1.2, 1.0)), Vector((0, 0, 0.98)), 0.55)
    shoot(sheets / "inf001_gloves_boots.png", Vector((1.1, -1.5, 0.55)), Vector((0, 0, 0.5)), 1.3)
    shoot(sheets / "inf001_pack_radio.png", Vector((0.8, 1.6, 1.3)), Vector((0, 0, 1.25)), 0.8)
    shoot(sheets / "inf001_weapon.png", Vector((-0.8, -1.5, 1.15)), Vector((-0.05, -0.45, 1.12)), 0.7)
    (out / "manifest.json").write_text(json.dumps({
        "id": "INF-001", "author": "FRONTLINE ZERO procedural pipeline", "license": "CC0-1.0",
        "source": "scripts/build_infantry.py", "height_m": 1.78, "lod0_triangles": tris,
        "animations": ["Idle", "Walk", "Run", "Crouch", "Aim", "Fire", "Reload", "TakeCover", "EnterVehicle", "ExitVehicle", "Interact", "Hit", "Incapacitation"],
    }, indent=2))
    print("INF001_TRIS", tris)

if __name__ == "__main__":
    main()
