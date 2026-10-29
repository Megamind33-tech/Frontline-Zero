extends SceneTree
const Sim = preload("res://src/simulation.gd")
const Orders = preload("res://src/formation_orders.gd")
var checks = 0
var failures = 0
func check(ok: bool, label: String):
 checks += 1
 if ok: print("PASS: ", label)
 else:
  failures += 1
  push_error("FAIL: " + label)
func _initialize():
 call_deferred("run")
func run():
 var s = Sim.new()
 var u = s.units[0]
 check(s.command([1], Vector2(20,17.5)), "first order accepted")
 s.command([1], Vector2(20,25), -1, "box", true)
 s.command([1], Vector2(13,25), -1, "box", true)
 var corners: Array = []
 var previous: Vector2 = u.order.pos
 for i in 180:
  s.tick()
  if u.order.is_empty() or u.order.pos != previous:
   corners.append(u.pos)
   if not u.order.is_empty(): previous = u.order.pos
  if u.order.is_empty(): break
 check(corners.size() == 3 and corners[0].distance_to(Vector2(20,17.5)) < 0.7 and corners[1].distance_to(Vector2(20,25)) < 0.7 and u.pos.distance_to(Vector2(13,25)) <= 0.5, "movement visits ordered corners then completes")
 check(u.queue.is_empty() and u.order.is_empty(), "completed queue drains")
 s = Sim.new()
 u = s.units[0]
 s.command([1],Vector2(30,20))
 for i in Sim.MAX_ORDERS-1: s.command([1],Vector2(40+i,20),-1,"box",true)
 check(u.queue.size()==Sim.MAX_ORDERS-1, "capacity includes active order")
 check(not s.command([1,2],Vector2(70,20),-1,"box",true) and s.units[1].order.is_empty(), "overflow rejects whole group without partial dispatch")
 check(s.command([1],Vector2(25,25)) and u.queue.is_empty() and u.order.pos==Vector2(25,25), "normal command replaces full queue")
 s.command([1],Vector2(30,30),-1,"box",true)
 var snapshot = u.duplicate(true)
 check(not s.command([1],Vector2(NAN,2),-1,"box",true) and not s.command([1],Vector2(20,20),999) and not s.command([1],Vector2(20,20),2), "nonfinite and invalid/friendly targets rejected")
 check(u==snapshot, "invalid commands preserve active and pending orders")
 s.units[5].hp=0
 check(not s.command([1],Vector2(20,20),6) and not s.command([6,999],Vector2(20,20)), "dead target and unauthorized selection rejected")
 s.hold([1,6])
 check(u.order.is_empty() and u.queue.is_empty(), "hold clears active and pending orders")
 s.command([1],Vector2(30,30))
 s.command([1],Vector2(40,30),-1,"box",true)
 s.direct_control(1,Vector2.RIGHT)
 s.direct_control(1,Vector2.ZERO)
 s.tick()
 check(u.order.is_empty() and u.queue.is_empty() and u.direct==Vector2.ZERO, "direct control cancels queue permanently on release")
 s = Sim.new()
 u = s.units[0]
 s.command([1],u.pos,6)
 s.command([1],Vector2(25,20),-1,"box",true)
 s.tick()
 check(u.order.target_id==6 and u.queue.size()==1, "live focus target keeps order active at destination")
 s.units[5].hp=0
 s.tick()
 check(u.order.target_id==-1 and u.order.pos==Vector2(25,20) and u.queue.is_empty(), "target death advances to queued move")
 s = Sim.new()
 s.command([1,2,3],Vector2(30,25),-1,"line")
 var positions: Array[Vector2] = []
 for i in 3: positions.append(s.units[i].order.pos)
 var expected = Orders.destinations(positions,Vector2(50,40),"line")
 s.command([1,2,3],Vector2(50,40),-1,"line",true)
 var correct = true
 for i in 3: correct = correct and s.units[i].queue[0].pos==expected[i]
 check(correct, "queued formations plan from previous destinations using licensed helper")
 s.command([1,2,3],Vector2(70,40),9,"box",true)
 check(s.units.slice(0,3).all(func(unit):return unit.queue[1].target_id==9), "queued focus fire preserves shared target")
 s = Sim.new()
 s.units[1].hp=0
 s.command([1,1,2,6,999],Vector2(30,30),-1,"box",true)
 check(not s.units[0].order.is_empty() and s.units[0].queue.is_empty() and s.units[1].order.is_empty() and s.units[5].order.is_empty(), "duplicate/dead/enemy/unknown IDs cannot add extra orders")
 var scene = load("res://main.tscn").instantiate()
 root.add_child(scene)
 await process_frame
 scene.selected=[1]
 var event = InputEventMouseButton.new()
 event.pressed=true
 event.button_index=MOUSE_BUTTON_LEFT
 event.position=scene.camera.unproject_position(Vector3(30,0,25))
 scene._unhandled_input(event)
 event.shift_pressed=true
 event.position=scene.camera.unproject_position(Vector3(40,0,25))
 scene._unhandled_input(event)
 check(scene.sim.units[0].queue.size()==1, "desktop Shift appends through scene input")
 scene.queue_button.button_pressed=true
 var touch = InputEventScreenTouch.new()
 touch.pressed=true
 touch.position=scene.camera.unproject_position(Vector3(50,0,25))
 scene._unhandled_input(touch)
 check(scene.queue_orders and scene.sim.units[0].queue.size()==2, "mobile Queue orders toggle appends touch command")
 scene.queue_button.button_pressed=false
 event.shift_pressed=false
 scene._unhandled_input(event)
 check(scene.sim.units[0].queue.is_empty(), "unmodified scene input replaces queue")
 scene.queue_button.button_pressed=true
 scene._unhandled_input(touch)
 for b in scene.find_children("*","Button",true,false):
  if b.text=="Hold position": b.pressed.emit()
 check(scene.sim.units[0].order.is_empty() and scene.sim.units[0].queue.is_empty(), "Hold button cancels queued scene commands")
 scene.sim.command([1],Vector2(30,30))
 scene.sim.command([1],Vector2(40,30),-1,"box",true)
 scene.paused=false
 scene.touching=true
 scene.pad_axes[1]=Vector2.RIGHT
 scene._physics_process(Sim.STEP)
 check(scene.sim.units[0].order.is_empty() and scene.sim.units[0].queue.is_empty(), "touch drive cancels queues through physics dispatch")
 scene.clear_direct()
 scene._physics_process(Sim.STEP)
 check(scene.sim.units[0].order.is_empty(), "released touch drive does not resume old orders")
 scene.queue_free()
 await process_frame
 print("TOTAL: %d queue checks, %d failed" % [checks,failures])
 quit(1 if failures else 0)
