extends Control
const Field=preload("res://src/battlefield.gd")
var battle
var minimap=false
const FRIEND=Color("b8d895")
const ENEMY=Color("e09a76")
func _ready():
 mouse_filter=Control.MOUSE_FILTER_STOP if minimap else Control.MOUSE_FILTER_IGNORE
func point(p: Vector2) -> Vector2:
 return Vector2(p.x/100.*size.x,p.y/65.*size.y)
func _gui_input(event):
 if not minimap:return
 if (event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed):
  battle.camera_focus=Vector2(event.position.x/size.x*100,event.position.y/size.y*65)
  battle.update_camera()
  accept_event()
func project(p: Vector2, elevation: float = .15) -> Vector2:
 return battle.camera.unproject_position(Field.ground(p,elevation))
func _draw():
 if battle==null or battle.sim==null:return
 var sim=battle.sim
 var font=ThemeDB.fallback_font
 if minimap:
  draw_rect(Rect2(Vector2.ZERO,size),Color("293b31"))
  for r in Field.COVER:draw_rect(Rect2(point(r.position),point(r.size)),Color("3c6046"))
  draw_line(point(Vector2(0,32.5)),point(Vector2(100,32.5)),Color("737262"),5)
  draw_rect(Rect2(point(Vector2(44,23.5)),point(Vector2(12,18))),Color("6b5a41"))
  for h in sim.hq:draw_rect(Rect2(point(h.pos)-Vector2(4,4),Vector2(8,8)),FRIEND if h.team==0 else ENEMY)
  for p in sim.points:draw_circle(point(p.pos),4,FRIEND if p.owner==0 else ENEMY if p.owner==1 else Color("e2d5a7"))
  for u in sim.units:
   if u.hp>0:draw_circle(point(u.pos),3 if battle.selected.has(u.id) else 2,FRIEND if u.team==0 else ENEMY)
  var corners: Array[Vector2]=[]
  var viewport=battle.get_viewport().get_visible_rect().size
  for screen in [Vector2.ZERO,Vector2(viewport.x,0),viewport,Vector2(0,viewport.y),Vector2.ZERO]:
   var hit=Plane(Vector3.UP,0).intersects_ray(battle.camera.project_ray_origin(screen),battle.camera.project_ray_normal(screen))
   if hit!=null:corners.append(point(Vector2(hit.x,hit.z)))
  if corners.size()>1:draw_polyline(PackedVector2Array(corners),Color(.83,.87,.70,.7),1,true)
  draw_rect(Rect2(Vector2.ZERO,size),Color("91a18a"),false,1)
  return
 for u in sim.units:
  if u.hp<=0:continue
  var p=project(u.pos,2.3)
  if not Rect2(Vector2.ZERO,size).has_point(p):continue
  var chosen=battle.selected.has(u.id)
  var color=FRIEND if u.team==0 else ENEMY
  var width=40 if chosen else 27
  draw_rect(Rect2(p-Vector2(width*.5,3),Vector2(width,4)),Color(.06,.09,.08,.9))
  draw_rect(Rect2(p-Vector2(width*.5,3),Vector2(width*maxf(0,u.hp/u.max_hp),3)),color)
  if chosen:
   draw_string(font,p+Vector2(-18,-9),u.type.to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("e2e6d6"))
   var previous=project(u.pos)
   var orders: Array=[]
   if not u.order.is_empty():orders.append(u.order)
   orders.append_array(u.queue)
   for i in orders.size():
    var target=project(orders[i].pos)
    draw_line(previous,target,Color(.77,.85,.58,.48),1.5,true)
    draw_circle(target,5,Color(.77,.85,.58,.85),false,1.4,true)
    if orders.size()>1:draw_string(font,target+Vector2(7,3),str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,12,color)
    previous=target
 for item in battle.order_feedback:
  var pos=project(item.pos,.5)
  var color=ENEMY if item.kind=="attack" else Color("e27c64") if item.kind=="reject" else FRIEND
  color.a=1.-item.age
  var radius=12.+item.age*16.
  draw_circle(pos,radius,color,false,2,true)
  if item.kind=="attack":
   draw_line(pos-Vector2(7,0),pos+Vector2(7,0),color,2,true)
   draw_line(pos-Vector2(0,7),pos+Vector2(0,7),color,2,true)
  elif item.kind=="reject":draw_string(font,pos+Vector2(-4,5),"×",HORIZONTAL_ALIGNMENT_LEFT,-1,20,color)
  else:draw_circle(pos,3,color)
 var targets: Array=[]
 for u in sim.units:
  if battle.selected.has(u.id) and not u.order.is_empty():
   var target=sim.attack_target(u.order.get("target_id",-1))
   if not target.is_empty() and not targets.has(target.pos):
    targets.append(target.pos)
    var pos=project(target.pos,1.4)
    draw_circle(pos,15,ENEMY,false,1.6,true)
    draw_string(font,pos+Vector2(18,4),"FOCUS",HORIZONTAL_ALIGNMENT_LEFT,-1,11,ENEMY)
 # Unit roles and objective names use terrain-projected anchors, not debug IDs.
 for i in sim.points.size():
  var p=project(sim.points[i].pos,5.8)
  draw_string(font,p+Vector2(-34,0),"RELAY "+("NORTH" if i==0 else "SOUTH"),HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("e3d5ad"))
