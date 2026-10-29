extends SceneTree
const Roster = preload("res://src/infantry_roster.gd")
var checks = 0
var failures = 0
func check(ok: bool, label: String):
	checks += 1
	if ok:
		print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: " + label)
func run():
	var spec: Dictionary = Roster.rifleman()
	var barracks: Dictionary = Roster.barracks()
	check(spec.get("id") == "INF-001", "rifleman id")
	var stats: Dictionary = spec.get("stats", {})
	for key in ["health", "armour", "attack_damage", "attack_interval_s", "accuracy", "range_m", "move_speed_m_s", "cover_damage_taken", "morale", "experience", "upgrade_level", "ammunition", "resupply_rounds"]:
		check(stats.has(key), "stat " + key)
	check(spec.get("variants", {}).size() == 5, "five equipment variants")
	check(spec.get("animations", []).size() == 13, "shared animation name list")
	var needs: Array = barracks.get("requires_infrastructure", [])
	for name in ["uniform_factory", "equipment_workshop", "armoury", "supply_depot", "power"]:
		check(needs.has(name), "barracks requires " + name)
	check(barracks.get("cost", {}).has("manpower") and barracks.get("cost", {}).has("credits"), "barracks spends manpower and credits")
	var model = load("res://assets/infantry/inf001_rifleman.glb").instantiate()
	root.add_child(model)
	await process_frame
	var armature = model.find_child("INF001_Armature", true, false)
	check(armature != null, "armature imports")
	var player = model.find_child("AnimationPlayer", true, false)
	check(player != null, "animation player imports")
	if player:
		var clips = player.get_animation_list()
		print("ANIMATIONS ", clips)
		for clip in spec.animations:
			check(clips.has(String(clip)), "animation " + String(clip))
	var rifle = model.find_child("Receiver", true, false)
	check(rifle != null, "rifle receiver imports")
	check(model.find_child("Helmet", true, false) != null, "helmet component imports")
	check(model.find_child("Muzzle", true, false) != null, "muzzle attachment imports")
	var meshes = model.find_children("*", "MeshInstance3D", true, false)
	var tris = 0
	var height = 0.0
	for mesh in meshes:
		if mesh.mesh == null:
			continue
		tris += mesh.mesh.get_faces().size() / 3
		var aabb = mesh.mesh.get_aabb()
		height = maxf(height, mesh.global_position.y + aabb.position.y + aabb.size.y)
	var budget: int = int(spec.lod_triangle_budget.lod0)
	check(tris > 500 and tris <= budget, "lod0 triangle count %d within %d" % [tris, budget])
	check(height > 1.4 and height < 2.2, "meter-scale height %.2f" % height)
	var lod1 = load("res://assets/infantry/inf001_rifleman_lod1.glb")
	var lod2 = load("res://assets/infantry/inf001_rifleman_lod2.glb")
	check(lod1 != null and lod2 != null, "lod glb files import")
	print("INF001_TRIS ", tris, " HEIGHT ", height)
	print("TOTAL: %d infantry checks, %d failed" % [checks, failures])
	quit(1 if failures else 0)
func _initialize():
	call_deferred("run")
