extends SceneTree
const Orders = preload("res://src/formation_orders.gd")
const Sim = preload("res://src/simulation.gd")
var checks = 0
var failures = 0
func check(ok: bool, label: String):
 checks += 1
 if ok: print("PASS: ",label)
 else:
  failures += 1
  push_error("FAIL: "+label)
func separated(slots: Array[Vector2]) -> bool:
 for i in slots.size():
  for j in range(i+1,slots.size()):
   if slots[i].distance_to(slots[j]) < Orders.SPACING-0.001: return false
 return true
func inside(slots: Array[Vector2]) -> bool:
 for p in slots:
  if not p.is_finite() or p.x<1.499 or p.x>98.501 or p.y<1.499 or p.y>63.501: return false
 return true
func click(scene,event):
 event.pressed=true
 scene._unhandled_input(event)
 event.pressed=false
 scene._unhandled_input(event)
 event.pressed=true
func _initialize():
 call_deferred("run")
func run():
 check(Orders.destinations([],Vector2(50,30)).is_empty(),"empty selection is a no-op")
 check(Orders.destinations([Vector2.ZERO],Vector2(NAN,30)).is_empty(),"nonfinite target rejected")
 check(Orders.destinations([Vector2(10,10)],Vector2(50,30))==[Vector2(50,30)],"single-unit destination unchanged")
 var group: Array[Vector2]=[Vector2(10,9),Vector2(10,13),Vector2(10,17),Vector2(10,21),Vector2(10,25)]
 var line=Orders.destinations(group,Vector2(70,17),"line")
 check(line.all(func(p):return is_equal_approx(p.x,70)),"line is perpendicular to eastward travel")
 check(separated(line),"line slots reserve vehicle clearance")
 var box=Orders.destinations(group,Vector2(70,17),"box")
 check(box.size()==5 and separated(box),"box assigns one distinct spaced slot per unit")
 check(Orders.destinations(group,Vector2(70,17),"box")==box,"same inputs produce deterministic assignments")
 check(Orders.destinations(group,Vector2(70,17),"unknown")==box,"unknown shape safely falls back to box")
 var worst: Array[Vector2]=[]
 for i in 12: worst.append(Vector2(15,2+i*4))
 var bounds_ok=true
 for target in [Vector2.ZERO,Vector2(100,0),Vector2(100,65),Vector2(0,65),Vector2(50,32.5)]:
  for shape in ["box","line"]:
   var slots=Orders.destinations(worst,target,shape)
   bounds_ok=bounds_ok and slots.size()==12 and inside(slots) and separated(slots)
 check(bounds_ok,"12-unit formations remain spaced at all four map edges")
 var reverse: Array[Vector2]=[Vector2(10,25),Vector2(10,17),Vector2(10,9)]
 var assigned=Orders.destinations(reverse,Vector2(70,17),"line")
 check(assigned[0].y>assigned[1].y and assigned[1].y>assigned[2].y,"assignment follows proximity rather than reversing input ranks")
 var sim=Sim.new()
 sim.units[0].direct=Vector2.LEFT
 sim.units[1].hp=0
 sim.command([1,1,2,3,6,999],Vector2(35,20),6,"line")
 check(sim.units[0].order.target_id==6 and sim.units[2].order.target_id==6,"focus-fire target survives formation adapter")
 check(sim.units[1].order.is_empty() and sim.units[5].order.is_empty(),"dead/enemy/unknown IDs ignored")
 check(sim.units[0].direct==Vector2.ZERO,"new order ends direct movement")
 check(sim.units[0].order.pos.distance_to(sim.units[2].order.pos)>=3.799,"simulation dispatches spaced group destinations")
 var before: Vector2=sim.units[0].pos
 sim.tick()
 check(sim.units[0].pos.distance_to(before)>0,"formation order uses existing movement loop")
 sim.command([1],Vector2(INF,2))
 check(sim.units[0].order.target_id==6,"invalid target does not erase prior order")
 var start=Time.get_ticks_usec()
 for i in 1000: Orders.destinations(worst,Vector2(50,32.5),"box")
 var command_ms=(Time.get_ticks_usec()-start)/1000000.0
 print("BENCHMARK: %.4f ms/group command, 1000 commands of 12 units, headless host only" % command_ms)
 check(command_ms<2.0,"host formation generation below 2ms/command")
 var cfg=ConfigFile.new()
 cfg.load("res://export_presets.cfg")
 check(cfg.get_value("preset.0","include_filter","").contains("third_party/rts_advanced/LICENSE.txt"),"Android export includes MIT notice")
 var license=FileAccess.get_file_as_string("res://third_party/rts_advanced/LICENSE.txt")
 check(license.contains("Copyright (c) 2026 Huginhelm") and license.contains("MIT License"),"vendored copyright and permission notice retained")
 var scene=load("res://main.tscn").instantiate()
 root.add_child(scene)
 await process_frame
 scene.hud.briefing.hide()
 var formation_button: Button
 for b in scene.find_children("*","Button",true,false):
  if b.text=="Formation: Box": formation_button=b
 check(formation_button!=null,"touch-accessible formation button exists")
 if formation_button!=null:
  formation_button.pressed.emit()
  check(scene.command_formation=="line" and formation_button.text=="Formation: Line","touch button changes active shape")
  scene.selected=[1,2,3]
  var event=InputEventMouseButton.new()
  event.pressed=true
  event.button_index=MOUSE_BUTTON_LEFT
  event.position=scene.camera.unproject_position(Vector3(35,0,30))
  click(scene,event)
  var dispatch_ok=true
  for u in scene.sim.units:
   if scene.selected.has(u.id): dispatch_ok=dispatch_ok and not u.order.is_empty()
  check(dispatch_ok,"scene input dispatches formation command")
 scene.queue_free()
 await process_frame
 print("TOTAL: %d formation checks, %d failed" % [checks,failures])
 quit(1 if failures else 0)
