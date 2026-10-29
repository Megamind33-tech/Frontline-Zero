extends SceneTree
const Field=preload("res://src/battlefield.gd")
const Sim=preload("res://src/simulation.gd")
var checks=0
var failures=0
func check(ok: bool, label: String):
 checks+=1
 if ok:print("PASS: ",label)
 else:
  failures+=1
  push_error("FAIL: "+label)
func _initialize():call_deferred("run")
func run():
 var scene=load("res://main.tscn").instantiate()
 root.add_child(scene)
 await process_frame
 check(not scene.hud.developer.visible,"diagnostics hidden from player by default")
 check(scene.hud.briefing.visible and not scene.hud.workshop.visible,"workshop confined to optional briefing modal")
 scene.hud.begin.pressed.emit()
 scene.hud.refresh()
 check(not scene.hud.briefing.visible and not scene.paused,"Begin battle enters the actual battle")
 scene.paused=true
 check(scene.map_root.get_node_or_null("ElevatedTerrain")!=null,"rendered battlefield uses height-field mesh")
 check(absf(Field.height_at(Vector2(30,2))-Field.height_at(Vector2(30,32)))>1.,"battlefield has geometric elevation")
 check(Field.COVER.all(func(r):return Sim.cover(r.get_center())),"visual woodland zones match actual damage-cover rules")
 check(scene.hq_visuals[0].get_active_material(0).vertex_color_use_as_albedo,"command post displays baked concrete/steel colors")
 var trees=scene.map_root.get_node("InstancedPineCanopies")
 check(trees is MultiMeshInstance3D and trees.multimesh.instance_count>50,"foliage uses instancing instead of per-tree draws")
 for role in ["tank","scout","artillery"]:
  var model=scene.model_scenes[role].instantiate()
  root.add_child(model)
  var turret=model.find_child("Turret",true,false)
  var recoil=model.find_child("Recoil",true,false)
  var meshes=model.find_children("*","MeshInstance3D",true,false)
  check(turret!=null and recoil!=null and meshes.size()==3,role+" has modelled/merged chassis, turret and gun")
  check(model.find_child("AnimationPlayer",true,false)!=null,role+" retains imported firing animation")
  check(meshes.all(func(m):return m.mesh.get_surface_count()==1 and m.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR].size()>0),role+" batches detail into one vertex-painted surface per group")
  model.queue_free()
 scene.selected=[1]
 scene.hud.refresh()
 check(scene.hud.context.get_child(0).get_child(1).visible,"commands appear for selected units")
 scene.selected=[]
 scene.hud.refresh()
 check(not scene.hud.context.get_child(0).get_child(1).visible,"commands hide with no selection")
 var old=scene.camera.position
 scene.pan_camera(Vector2(80,20))
 check(scene.camera.position.distance_to(old)>1,"camera drag moves the actual 3D view")
 scene.zoom_camera(-999)
 check(scene.camera_zoom==25,"camera near zoom is bounded")
 scene.zoom_camera(999)
 check(scene.camera_zoom==80,"camera far zoom is bounded")
 var mini=InputEventMouseButton.new();mini.pressed=true;mini.button_index=MOUSE_BUTTON_LEFT;mini.position=scene.hud.minimap.size*.5
 scene.hud.minimap._gui_input(mini)
 check(scene.camera_focus.distance_to(Vector2(50,32.5))<.01,"minimap recenters the strategy camera")
 scene.selected=[1]
 scene.sim.command([1],Vector2(30,25))
 var before=scene.sim.units[0].duplicate(true)
 var touch=InputEventScreenTouch.new();touch.index=0;touch.pressed=true;touch.position=Vector2(500,300)
 scene._unhandled_input(touch)
 var drag=InputEventScreenDrag.new();drag.index=0;drag.position=Vector2(560,330);drag.relative=Vector2(60,30)
 scene._unhandled_input(drag)
 touch.pressed=false;touch.position=drag.position;scene._unhandled_input(touch)
 check(scene.sim.units[0].order==before.order and scene.sim.units[0].queue==before.queue,"touch camera drag cannot issue an unintended unit command")
 scene.effects.set_process(false)
 for i in 200:scene.effects.shot({"from":Vector2(20,30),"to":Vector2(30,30)},"tank")
 check(scene.effects.shells.size()<=scene.effects.LIMIT and scene.effects.items.size()<=scene.effects.LIMIT,"projectiles and transient effect count are bounded")
 scene.effects._process(2.)
 scene.effects._process(4.)
 check(scene.effects.shells.is_empty() and scene.effects.items.is_empty(),"effects expire instead of leaking nodes")
 scene.sim.units[0].hp=0
 scene.update_visuals(.033)
 check(scene.visuals[1].dead and not scene.visuals[1].ring.visible,"destroyed vehicles become wrecks and lose selection markers")
 scene.queue_free()
 await process_frame
 print("TOTAL: %d battle checks, %d failed" % [checks,failures])
 quit(1 if failures else 0)
