extends SceneTree
const Sim=preload("res://src/simulation.gd")
const Groups=preload("res://src/control_groups.gd")
const Field=preload("res://src/battlefield.gd")
var checks=0
var failures=0
func check(ok: bool,label: String):
 checks+=1
 if ok:print("PASS: ",label)
 else:failures+=1;push_error("FAIL: "+label)
func _initialize():call_deferred("run")
func screen(scene,p: Vector2) -> Vector2:return scene.camera.unproject_position(Field.ground(p))
func tap(scene,p: Vector2):
 var event=InputEventScreenTouch.new();event.index=0;event.pressed=true;event.position=screen(scene,p)
 scene.get_viewport().push_input(event,true)
 await process_frame
 event=event.duplicate();event.pressed=false;scene.get_viewport().push_input(event,true)
 await process_frame
func run():
 var s=Sim.new();var u=s.units[0]
 s.command([1],Vector2(30,20));var previous: Vector2=u.pos;s.tick()
 check(u.pos.distance_to(previous)>0,"single ground move remains responsive")
 s.command([1,2,3],Vector2(35,25),-1,"line")
 check(s.units[0].order.pos.distance_to(s.units[1].order.pos)>3.7,"multi-unit move preserves distinct formation slots")
 s=Sim.new();u=s.units[0];var enemy=s.units[5]
 u.pos=Vector2(30,20);enemy.pos=Vector2(65,20);u.hp=10000;enemy.hp=10000
 s.command([1],enemy.pos,enemy.id)
 s.tick();var destination: Vector2=u.order.pos
 enemy.pos+=Vector2(8,0);s.tick()
 check(u.order.pos.distance_to(destination)>5,"attack order follows a moving hostile instead of a stale point")
 u.pos=enemy.pos-Vector2(12,0);previous=u.pos;s.tick()
 check(u.pos==previous and s.shots.any(func(shot):return shot.id==1 and shot.target_id==6),"single attack holds valid range and fires")
 s=Sim.new();u=s.units[0];u.pos=Vector2(60,32)
 s.units[5].pos=Vector2(70,32);s.units[6].pos=Vector2(61,32)
 for i in range(1,5):s.units[i].cooldown=100
 var hp6: float=s.units[5].hp;var hp7: float=s.units[6].hp
 s.command([1],s.units[5].pos,6);s.tick()
 check(s.units[5].hp<hp6 and s.units[6].hp==hp7,"explicit focus wins over a nearer automatic target")
 s=Sim.new();s.units[0].pos=Vector2(80,29);s.units[1].pos=Vector2(80,36)
 s.units[5].pos=Vector2(81,31)
 s.command([1,2],s.hq[1].pos,Sim.ENEMY_HQ,"line")
 check(s.units[0].order.target_id==Sim.ENEMY_HQ and s.units[1].order.target_id==Sim.ENEMY_HQ,"multi-unit enemy-structure focus is accepted")
 s.tick()
 check(s.hq[1].hp==1600.-s.units[0].damage-s.units[1].damage,"multiple units attack enemy HQ before nearby units")
 s=Sim.new();var artillery=s.units[4];artillery.pos=Vector2(60,30);s.units[5].pos=Vector2(65,30)
 s.command([5],s.units[5].pos,6);var distance: float=artillery.pos.distance_to(s.units[5].pos);s.tick()
 check(artillery.pos.distance_to(s.units[5].pos)>distance and not s.shots.any(func(shot):return shot.id==5 and shot.target_id==6),"artillery retreats from minimum range instead of firing illegally")
 s=Sim.new();s.command([1],s.units[5].pos,6);s.command([1],Vector2(25,25),-1,"box",true)
 s.units[5].hp=0;s.tick()
 check(s.units[0].order.target_id==-1 and s.units[0].queue.is_empty(),"target death advances existing command queue")
 var snapshot=s.units[0].duplicate(true)
 check(not s.command([1],s.hq[0].pos,Sim.FRIENDLY_HQ) and not s.command([1],s.units[1].pos,2) and not s.command([1],Vector2(20,20),999),"friendly structures/units and unknown targets cannot be attacked")
 check(s.units[0].order==snapshot.order,"rejected attacks do not erase existing orders")
 check(not s.command([1],Vector2(-10,30)) and not s.command([1],Vector2(NAN,30)),"off-map and nonfinite destinations fail without clamping to a surprise order")
 s.units[0].domain="air";var air=s.command([1],Vector2(30,30))
 s.units[0].domain="naval";var naval=s.command([1],Vector2(30,30))
 check(not air and not naval,"ground command adapter rejects unsupported movement domains")
 var scene=load("res://main.tscn").instantiate();root.add_child(scene)
 await process_frame
 scene.hud.briefing.hide();scene.paused=true;scene.camera_focus=Vector2(50,32.5);scene.camera_zoom=65;scene.update_camera()
 await process_frame
 await tap(scene,scene.sim.units[0].pos)
 check(scene.selected==[1],"engine-dispatched touchscreen tap selects a friendly unit")
 var p=screen(scene,Vector2(35,28));var start=InputEventScreenTouch.new();start.index=0;start.pressed=true;start.position=p
 scene.get_viewport().push_input(start,true);await process_frame
 check(scene.sim.units[0].order.is_empty(),"pointer down does not issue an order before tap/drag classification")
 start=start.duplicate();start.pressed=false;scene.get_viewport().push_input(start,true);await process_frame
 check(not scene.sim.units[0].order.is_empty() and scene.order_feedback[-1].kind=="move","engine-dispatched terrain tap moves and confirms immediately")
 scene.additive_selection=true
 await tap(scene,scene.sim.units[1].pos)
 check(scene.selected.has(1) and scene.selected.has(2),"optional additive taps preserve multi-unit selection")
 scene.additive_selection=false
 await tap(scene,scene.sim.units[5].pos)
 check(scene.sim.units[0].order.get("target_id",-999)==6 and scene.sim.units[1].order.get("target_id",-999)==6 and scene.order_feedback[-1].kind=="attack","engine-dispatched enemy tap dispatches multi-unit focus fire and visual confirmation")
 await tap(scene,scene.sim.hq[1].pos)
 check(scene.sim.units[0].order.get("target_id",-999)==Sim.ENEMY_HQ,"engine-dispatched enemy-building tap attacks the structure")
 var old_order=scene.sim.units[0].order.duplicate(true)
 await tap(scene,scene.sim.hq[0].pos)
 check(scene.hud.building_panel.visible and scene.sim.units[0].order==old_order,"friendly building opens real management without an attack or move")
 check(scene.hud.building_panel.get_global_rect().end.x<=scene.get_viewport().get_visible_rect().size.x,"management panel text stays inside the screen")
 scene.hud.building_panel.hide()
 scene.touch_input.last_unit=-1
 await tap(scene,scene.sim.units[0].pos);await tap(scene,scene.sim.units[0].pos)
 check(scene.selected.has(1) and scene.selected.has(2) and scene.selected.size()==2,"double-tap selects nearby living units of the same class")
 scene.selected=[1];scene.touch_input.cancel()
 p=screen(scene,scene.sim.units[0].pos)
 scene.touch_input.begin(0,p,false,1000);scene.touch_input.advance(1501)
 check(scene.hud.advanced.visible,"long press on selected unit exposes advanced orders")
 scene.touch_input.end(0,p,false,1502)
 check(scene.sim.units[0].order==old_order,"long press release cannot issue a movement command")
 scene.hud.close_advanced()
 var visible_direction=false
 for b in scene.find_children("*","Button",true,false):
  if b.is_visible_in_tree() and b.text in ["Move","Attack","↑","↓","←","→","+","−"]:visible_direction=true
 check(not visible_direction,"main HUD has no permanent Move/Attack or directional camera controls")
 var camera_before=scene.camera.position
 scene.touch_input.begin(0,Vector2(560,300),false,2000)
 scene.touch_input.move(0,Vector2(620,330),Vector2(60,30));scene.touch_input.end(0,Vector2(620,330),false,2100)
 check(scene.camera.position!=camera_before and scene.sim.units[0].order==old_order,"single-finger camera pan never issues an order")
 var zoom=scene.camera_zoom;var yaw=scene.camera_yaw
 scene.touch_input.begin(0,Vector2(500,300),false,2200);scene.touch_input.begin(1,Vector2(650,300),false,2200)
 scene.touch_input.move(1,Vector2(710,360),Vector2(60,60));scene.touch_input.end(1,Vector2(710,360),false,2300);scene.touch_input.end(0,Vector2(500,300),false,2300)
 check(scene.camera_zoom!=zoom and scene.camera_yaw!=yaw and scene.sim.units[0].order==old_order,"pinch and two-finger rotation preserve orders")
 camera_before=scene.camera.position
 scene.touch_input.begin(0,Vector2(450,40),false,2500);scene.touch_input.move(0,Vector2(550,220),Vector2(100,180));scene.touch_input.end(0,Vector2(550,220),false,2600)
 check(scene.camera.position==camera_before and scene.sim.units[0].order==old_order,"HUD-started drag cannot become a battlefield gesture")
 scene.touch_input.begin(0,Vector2(500,620),false,2700);scene.touch_input.end(0,Vector2(500,680),false,2750)
 scene.touch_input.begin(0,Vector2(500,680),false,2800);scene.touch_input.end(0,Vector2(500,620),false,2850)
 check(scene.sim.units[0].order==old_order,"crossing the HUD boundary in either direction cannot issue an order")
 scene.hud.building_panel.show()
 await process_frame
 var edge=scene.hud.building_panel.get_global_rect().position.x
 var border_y=scene.hud.building_panel.get_global_rect().position.y+100
 scene.touch_input.begin(0,Vector2(edge-4,border_y),false,2900);scene.touch_input.end(0,Vector2(edge+4,border_y),false,2950)
 scene.touch_input.begin(0,Vector2(edge+4,border_y),false,2960);scene.touch_input.end(0,Vector2(edge-4,border_y),false,2990)
 check(scene.sim.units[0].order==old_order,"sub-threshold taps crossing a valid-terrain/HUD boundary are suppressed")
 scene.hud.building_panel.hide()
 scene.camera_focus=Vector2(50,32.5);scene.camera_zoom=65;scene.camera_yaw=0;scene.update_camera();scene.touch_input.cancel()
 p=screen(scene,scene.sim.units[0].pos)
 scene.touch_input.begin(0,p,false,3000);scene.sim.units[0].pos+=Vector2(1,0);scene.touch_input.end(0,p,false,3100)
 check(scene.selected==[1],"a moving friendly remains selectable from the pressed target")
 p=screen(scene,scene.sim.units[5].pos)
 scene.touch_input.begin(0,p,false,3200);scene.sim.units[5].hp=0;scene.touch_input.end(0,p,false,3300)
 check(scene.sim.units[0].order==old_order and scene.order_feedback[-1].kind=="reject","target destroyed during a tap rejects gracefully without a ground order")
 # Exercise the emulated mouse stream that Android supplies for ordinary Godot Buttons.
 scene.hud.open_advanced(Vector2(600,250))
 await process_frame
 var button_pos=scene.queue_button.get_global_rect().get_center()
 var emulated=InputEventMouseButton.new();emulated.device=InputEvent.DEVICE_ID_EMULATION;emulated.button_index=MOUSE_BUTTON_LEFT;emulated.position=button_pos;emulated.pressed=true
 var queue_before=scene.queue_orders
 scene.get_viewport().push_input(emulated,true)
 emulated=emulated.duplicate();emulated.pressed=false;scene.get_viewport().push_input(emulated,true)
 await process_frame
 check(scene.queue_orders!=queue_before and scene.sim.units[0].order==old_order,"emulated mouse activates HUD buttons without battlefield orders")
 scene.queue_button.button_pressed=false;scene.hud.close_advanced()
 var order_count=scene.order_feedback.size()
 p=screen(scene,Vector2(35,25))
 emulated=emulated.duplicate();emulated.position=p;emulated.pressed=true;scene.get_viewport().push_input(emulated,true)
 emulated=emulated.duplicate();emulated.pressed=false;scene.get_viewport().push_input(emulated,true)
 await process_frame
 check(scene.order_feedback.size()==order_count,"emulated mouse cannot duplicate a native world command")
 var path="user://touch-groups-test.json";DirAccess.remove_absolute(path)
 scene.control_groups=Groups.new(path);scene.selected=[1,2];scene.save_group(1);scene.selected=[];scene.recall_group(1)
 check(scene.selected==[1,2],"saved control group recalls selection")
 var loaded=Groups.new(path)
 check(loaded.recall(1,scene.sim.units)==[1,2],"control group assignments survive reload")
 scene.sim.units[0].hp=0
 check(loaded.recall(1,scene.sim.units)==[2],"group recall filters destroyed units")
 scene.sim.units[1].weapon="howitzer"
 check(loaded.recall(1,scene.sim.units).is_empty(),"group identities cannot select a different blueprint after redeployment")
 DirAccess.remove_absolute(path);DirAccess.remove_absolute(path+".tmp")
 scene.queue_free();await process_frame
 print("TOTAL: %d direct-touch checks, %d failed" % [checks,failures])
 quit(1 if failures else 0)
