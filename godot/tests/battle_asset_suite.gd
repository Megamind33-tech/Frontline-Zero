extends SceneTree
var checks=0
var failures=0
func check(ok: bool,label: String):
 checks+=1
 if ok:print("PASS: ",label)
 else:failures+=1;push_error("FAIL: "+label)
func _initialize():call_deferred("run")
func run():
 for role in ["tank","scout","artillery"]:
  var model=load("res://assets/battle/"+role+".glb").instantiate()
  root.add_child(model)
  await process_frame
  var meshes=model.find_children("*","MeshInstance3D",true,false)
  check(meshes.size()==3,role+" preserves separate chassis/turret/gun groups")
  check(model.find_child("Turret",true,false)!=null and model.find_child("Recoil",true,false)!=null,role+" retains named articulation")
  var player=model.find_child("AnimationPlayer",true,false)
  check(player!=null and player.get_animation_list().size()>0,role+" imports recoil animation")
  check(meshes.all(func(m):return m.mesh.get_surface_count()==1),role+" uses one draw surface per articulated group")
  check(meshes.all(func(m):return m.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR].size()>0),role+" retains baked paint/material identity")
  var chassis=model.find_child("Chassis",true,false)
  var bounds: AABB=chassis.mesh.get_aabb()
  check(bounds.size.x<2.8 and bounds.size.z<4.2 and bounds.size.y>0.8,role+" preserves compact footprint and meter-scale chassis")
  model.queue_free()
  await process_frame
 print("TOTAL: %d battle asset checks, %d failed" % [checks,failures])
 quit(1 if failures else 0)
