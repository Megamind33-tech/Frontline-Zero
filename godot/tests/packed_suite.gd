extends SceneTree
func _initialize():
 call_deferred("run")
func run():
 var notice=FileAccess.get_file_as_string("res://third_party/rts_advanced/LICENSE.txt")
 if not notice.contains("Copyright (c) 2026 Huginhelm"):
  push_error("FAIL: MIT notice missing from pack")
  quit(1)
  return
 var scene=load("res://main.tscn").instantiate()
 root.add_child(scene)
 await process_frame
 var found=false
 for button in scene.find_children("*","Button",true,false):
  if button.text=="Formation: Box":
   button.pressed.emit()
   found=scene.command_formation=="line"
 if not found:
  push_error("FAIL: packed formation control")
  quit(1)
  return
 scene.queue_button.button_pressed=true
 scene.sim.command([1],Vector2(25,20))
 scene.sim.command([1],Vector2(35,20),-1,scene.command_formation,scene.queue_orders)
 if scene.sim.units[0].queue.size()!=1:
  push_error("FAIL: packed queue control")
  quit(1)
  return
 print("PASS: Android-target PCK includes MIT notice and boots 3D scene with formation and queue controls; host headless only")
 scene.queue_free()
 await process_frame
 quit(0)
