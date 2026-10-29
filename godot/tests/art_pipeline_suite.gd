extends SceneTree
## Validate the Blender-to-Godot GLB handoff, without changing battle assets.
var failures = 0
var checks = 0
func check(ok: bool, label: String):
 checks += 1
 if ok: print("PASS: ", label)
 else:
  failures += 1
  push_error("FAIL: " + label)
func _initialize():
 call_deferred("run")
func run():
 var args = OS.get_cmdline_user_args()
 if args.size()!=1:
  push_error("FAIL: supply generated GLB directory after --")
  quit(1)
  return
 for role in ["scout", "tank", "artillery"]:
  var path = args[0].path_join(role+".glb")
  var document = GLTFDocument.new()
  var state = GLTFState.new()
  var err = document.append_from_file(path,state)
  check(err==OK, role+" GLB parses in Godot")
  if err!=OK: continue
  var scene = document.generate_scene(state)
  check(scene!=null, role+" creates a 3D scene")
  if scene==null: continue
  root.add_child(scene)
  var meshes = scene.find_children("*","MeshInstance3D",true,false)
  check(meshes.size()>=10,role+" contains vehicle geometry")
  var vertices = 0
  var lo = Vector3(INF,INF,INF)
  var hi = Vector3(-INF,-INF,-INF)
  for mesh in meshes:
   for surface in mesh.mesh.get_surface_count():
    var arrays = mesh.mesh.surface_get_arrays(surface)
    for v in arrays[Mesh.ARRAY_VERTEX]:
     vertices+=1
     var world: Vector3 = mesh.global_transform*v
     lo=lo.min(world)
     hi=hi.max(world)
  check(vertices>0 and vertices<20000,role+" stays below 20k exported vertices")
  var size: Vector3 = hi-lo
  check(size.is_finite() and size.x>1.5 and size.x<4 and size.y>0.5 and size.y<3 and size.z>2 and size.z<7,role+" has meter-scale Godot Y-up bounds")
  var animated = false
  for player in scene.find_children("*","AnimationPlayer",true,false):
   for animation in player.get_animation_list():
    if animation!="RESET" and player.get_animation(animation).get_track_count()>0:
     animated=true
  check(animated,role+" retains recoil animation")
  scene.queue_free()
  await process_frame
 print("TOTAL: %d art pipeline checks, %d failed" % [checks,failures])
 quit(1 if failures else 0)
