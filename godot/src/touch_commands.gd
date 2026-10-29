extends RefCounted
## One pointer lifecycle for mouse/touch. HUD-started gestures never become world orders.
const DRAG_SLOP=12.0
const LONG_PRESS_MS=500
const DOUBLE_TAP_MS=320
var battle
var pointers: Dictionary={}
var last_unit=-1
var last_time=-1000
var last_position=Vector2.ZERO
var right_drag=false
func cancel():
 pointers.clear();right_drag=false;last_unit=-1
func begin(id: int,pos: Vector2,shift: bool,now: int):
 var blocked=battle.hud.blocks_world(pos)
 if blocked:last_unit=-1
 if not blocked and battle.hud.advanced.visible:
  battle.hud.close_advanced()
  pointers[id]={"blocked":true}
  return true
 var hit={} if blocked else battle.pick_screen(pos)
 pointers[id]={"blocked":blocked,"start":pos,"pos":pos,"time":now,"dragged":false,"long":false,"shift":shift,"hit":hit}
 if pointers.size()>1:
  for p in pointers.values():p.dragged=true
 return not blocked
func move(id: int,pos: Vector2,relative: Vector2):
 if not pointers.has(id):return false
 var p=pointers[id]
 if p.blocked:return false
 if p.long:return true
 var active=pointers.values().filter(func(v):return not v.blocked)
 if active.size()==2 and pointers.size()==2:
  var old_vector: Vector2=active[1].pos-active[0].pos
  p.pos=pos
  var new_vector: Vector2=active[1].pos-active[0].pos
  if old_vector.length()>10 and new_vector.length()>10:
   battle.zoom_camera(battle.camera_zoom*(1.-new_vector.length()/old_vector.length()))
   battle.camera_yaw-=old_vector.angle_to(new_vector)
   battle.pan_camera(relative*.5)
  for item in active:item.dragged=true
 elif pointers.size()==1 and (p.dragged or pos.distance_to(p.start)>DRAG_SLOP):
  p.dragged=true;battle.pan_camera(relative)
 p.pos=pos
 return true
func end(id: int,pos: Vector2,shift: bool,now: int):
 if not pointers.has(id):return false
 var p=pointers[id]
 pointers.erase(id)
 if p.blocked:return false
 if p.long or p.dragged or pos.distance_to(p.start)>DRAG_SLOP or battle.hud.blocks_world(pos):
  last_unit=-1
  return true
 var double_tap=false
 if p.hit.get("kind","")=="friendly_unit":
  double_tap=p.hit.id==last_unit and now-last_time<=DOUBLE_TAP_MS and pos.distance_to(last_position)<=DRAG_SLOP*2
  last_unit=p.hit.id;last_time=now;last_position=pos
 else:last_unit=-1
 battle.dispatch_tap(p.hit,pos,battle.queue_orders or p.shift or shift,double_tap)
 return true
func advance(now: int):
 if pointers.size()!=1:return
 var p=pointers.values()[0]
 if p.blocked or p.dragged or p.long or now-p.time<LONG_PRESS_MS:return
 if p.hit.get("kind","")=="friendly_unit" and battle.selected.has(p.hit.id):
  p.long=true
  battle.hud.open_advanced(p.pos)
func handle(event) -> bool:
 # Keep default touch-to-mouse emulation for Godot Buttons; never duplicate world taps.
 if event is InputEventMouse and event.device==InputEvent.DEVICE_ID_EMULATION:return false
 var now=Time.get_ticks_msec()
 if event is InputEventScreenTouch:
  return begin(event.index,event.position,false,now) if event.pressed else end(event.index,event.position,false,now)
 if event is InputEventScreenDrag:return move(event.index,event.position,event.relative)
 if event is InputEventMouseButton:
  if event.button_index in [MOUSE_BUTTON_RIGHT,MOUSE_BUTTON_MIDDLE]:
   right_drag=event.pressed and not battle.hud.blocks_world(event.position)
   return right_drag
  if event.button_index==MOUSE_BUTTON_LEFT:
   return begin(-1,event.position,event.shift_pressed,now) if event.pressed else end(-1,event.position,event.shift_pressed,now)
  if event.pressed and not battle.hud.blocks_world(event.position):
   if event.button_index==MOUSE_BUTTON_WHEEL_UP:battle.zoom_camera(-3);return true
   if event.button_index==MOUSE_BUTTON_WHEEL_DOWN:battle.zoom_camera(3);return true
 if event is InputEventMouseMotion:
  if right_drag:battle.pan_camera(event.relative);return true
  return move(-1,event.position,event.relative)
 return false
