extends Node3D
const Sim = preload("res://src/simulation.gd")
const Campaign = preload("res://src/campaign.gd")
const Field = preload("res://src/battlefield.gd")
const HUD = preload("res://src/battle_hud.gd")
const Effects = preload("res://src/battle_effects.gd")
const TouchCommands = preload("res://src/touch_commands.gd")
const Groups = preload("res://src/control_groups.gd")
var touch_input=TouchCommands.new()
var control_groups=Groups.new()
var additive_selection=false
var order_feedback: Array=[]
var armor_paint=ShaderMaterial.new()
var hud
var effects
var camera_focus = Vector2(43,32.5)
var camera_yaw = 0.0
var camera_zoom = 48.0
var frame_samples: Array = []
var draw_samples: Array = []
var last_frame_usec = 0
var peak_memory = 0.0
var peak_video_memory = 0.0
var hud_elapsed = 0.0
var sim
var selected: Array = []
var command_formation = "box"
var queue_orders = false
var queue_button: Button
var visuals: Dictionary = {}
var camera: Camera3D
var status: Label
var unit_text: Label
var message: Label
var campaign_text: Label
var pause_button: Button
var workshop_text: Label
var chassis: OptionButton
var weapon: OptionButton
var armor: OptionButton
var map_root: Node3D
var relay_visuals: Array = []
var hq_visuals: Array = []
var paused = true
var accumulator = 0.0
var battle_id = ""
var saved = false
var loadout: Array = ["tank","tank","scout","scout","artillery"]
var materials: Dictionary = {}
var direct = Vector2.ZERO
var touching = false
var active_shots: Array = []
var model_scenes: Dictionary = {}
var pad_axes: Dictionary = {}

func material(color: Color) -> StandardMaterial3D:
 var m = StandardMaterial3D.new()
 m.albedo_color = color
 m.roughness = 0.85
 return m

func cube(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
 var n = MeshInstance3D.new()
 var mesh = BoxMesh.new()
 mesh.size = size
 n.mesh = mesh
 n.material_override = material(color)
 parent.add_child(n)
 n.position = at
 return n

func _ready():
 touch_input.battle=self
 armor_paint.shader=load("res://src/armor.gdshader")
 for role in ["scout","tank","artillery"]:
  var path = "res://assets/battle/%s.glb" % role
  if ResourceLoader.exists(path):
   model_scenes[role] = load(path)
 var light = DirectionalLight3D.new()
 light.rotation_degrees = Vector3(-55,-25,0)
 light.light_energy = .85
 light.light_color = Color("fff0da")
 light.shadow_enabled = true
 light.directional_shadow_max_distance = 120
 add_child(light)
 var world = WorldEnvironment.new()
 world.environment = Environment.new()
 world.environment.background_mode = Environment.BG_COLOR
 world.environment.background_color = Color("a7afa1")
 world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 world.environment.ambient_light_color = Color("bccdc4")
 world.environment.ambient_light_energy = 0.35
 world.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
 world.environment.tonemap_exposure = .85
 add_child(world)
 camera = Camera3D.new()
 add_child(camera)
 camera.projection = Camera3D.PROJECTION_ORTHOGONAL
 camera.size = 82
 camera.h_offset = 0
 update_camera()
 ui()
 reset_battle()

func custom() -> Dictionary:
 return {"chassis":chassis.get_item_text(chassis.selected),"weapon":weapon.get_item_text(weapon.selected),"armor":armor.get_item_text(armor.selected)}

func option(parent: Node, title: String, values: Array) -> OptionButton:
 var label = Label.new()
 label.text = title
 parent.add_child(label)
 var o = OptionButton.new()
 o.custom_minimum_size = Vector2(0,44)
 for v in values:
  o.add_item(v)
 parent.add_child(o)
 o.item_selected.connect(func(_i): update_blueprint())
 return o

func button(parent: Node, text: String, action: Callable) -> Button:
 var b = Button.new()
 b.text = text
 b.custom_minimum_size = Vector2(0,44)
 parent.add_child(b)
 b.pressed.connect(action)
 return b

func ui():
 hud=HUD.new()
 add_child(hud)
 hud.setup(self)

func update_blueprint():
 if not is_instance_valid(workshop_text) or not is_instance_valid(armor): return
 var b = Sim.blueprint(custom())
 workshop_text.text = b.error if b.has("error") else "%s / %d credits\n%d HP | %.1f m/s\n%.0f–%.0f m range" % [b.type.to_upper(),b.cost,b.hp,b.speed,b.min_range,b.range]

func select_all():
 selected.clear()
 clear_direct()
 for u in sim.units:
  if u.team==0 and u.hp>0: selected.append(u.id)

func deploy_siege():
 chassis.select(0)
 weapon.select(0)
 armor.select(1)
 update_blueprint()
 loadout=["custom","custom","scout","artillery"]
 deploy()

func deploy():
 var candidate = Sim.new(loadout,custom())
 if not candidate.error.is_empty():
  message.text = candidate.error
  return
 reset_battle(candidate)
 paused = false
 pause_button.text = "Pause"
 message.text = "Command confirmed. Capture both relays or destroy Veyr HQ."

func reset_battle(candidate = null):
 hud.close_advanced();hud.building_panel.hide()
 touch_input.cancel()
 order_feedback.clear()
 clear_direct()
 if is_instance_valid(map_root):
  remove_child(map_root)
  map_root.queue_free()
 map_root = Node3D.new()
 add_child(map_root)
 visuals.clear()
 active_shots.clear()
 relay_visuals.clear()
 hq_visuals.clear()
 selected.clear()
 sim = candidate if candidate != null else Sim.new()
 battle_id = str(Time.get_unix_time_from_system())+"-"+str(Time.get_ticks_usec())
 saved = false
 accumulator = 0
 Field.build(map_root)
 effects=Effects.new()
 map_root.add_child(effects)
 for p in sim.points:
  relay_visuals.append(Field.relay(map_root,p.pos))
 for h in sim.hq:
  hq_visuals.append(Field.hq(map_root,h.pos,h.team))
 for u in sim.units:
  var n = Node3D.new()
  map_root.add_child(n)
  var model=model_scenes[u.type].instantiate()
  n.add_child(model)
  var paint=armor_paint.duplicate()
  paint.set_shader_parameter("team_color",Color("bacd8d") if u.team==0 else Color("ce8a62"))
  for mesh in model.find_children("*","MeshInstance3D",true,false):mesh.material_override=paint
  var ring = MeshInstance3D.new()
  var torus = TorusMesh.new()
  torus.inner_radius=1.9
  torus.outer_radius=2.05
  torus.rings=12
  torus.ring_segments=12
  ring.mesh=torus
  ring.material_override=Field.mat("selection",Color("d5dba0"))
  ring.material_override.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
  n.add_child(ring)
  ring.position.y=0.13
  ring.visible=false
  visuals[u.id]={"node":n,"ring":ring,"last":u.pos,"animation":n.find_child("AnimationPlayer",true,false),"turret":n.find_child("Turret",true,false),"paint":paint,"travel":0.,"meshes":n.find_children("*","MeshInstance3D",true,false),"hp":u.hp,"damage":0.,"dead":false,"aim":u.pos+Vector2(1 if u.team==0 else -1,0)}
 update_visuals(0)
 refresh_campaign()

func refresh_campaign():
 var c = Campaign.load_record()
 campaign_text.text = "LOCAL CAMPAIGN / %d W — %d L / TERRITORY: %s" % [c.wins,c.losses,c.territory]

func clear_direct():
 direct=Vector2.ZERO
 touching=false
 pad_axes.clear()
 if sim != null:
  for u in sim.units: u.direct=Vector2.ZERO

func _notification(what):
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT:
  paused=true
  touch_input.cancel()
  clear_direct()
  if is_instance_valid(pause_button): pause_button.text="Resume"

func update_camera():
 camera_focus=camera_focus.clamp(Vector2(4,4),Vector2(96,61))
 camera.size=camera_zoom
 var center=Field.ground(camera_focus)
 var offset=Vector3(sin(camera_yaw)*55,42,cos(camera_yaw)*55)
 camera.position=center+offset
 camera.look_at(center)

func zoom_camera(amount: float):
 camera_zoom=clampf(camera_zoom+amount,25,80)
 update_camera()

func focus_selection():
 var center=Vector2.ZERO
 var count=0
 for u in sim.units:
  if u.hp>0 and selected.has(u.id):center+=u.pos;count+=1
 camera_focus=center/count if count>0 else Vector2(50,32.5)
 update_camera()

func pan_camera(relative: Vector2):
 var factor=camera_zoom/get_viewport().get_visible_rect().size.y
 var right=Vector2(cos(camera_yaw),-sin(camera_yaw))
 var forward=Vector2(sin(camera_yaw),cos(camera_yaw))
 camera_focus-=right*relative.x*factor+forward*relative.y*factor*1.35
 update_camera()

func world_at_screen(pos: Vector2):
 var origin=camera.project_ray_origin(pos)
 var direction=camera.project_ray_normal(pos)
 var hit=Plane(Vector3.UP,0).intersects_ray(origin,direction)
 if hit==null:return null
 # Match the rendered height field rather than clicking through hills onto y=0.
 for i in 4:
  var height=Field.height_at(Vector2(hit.x,hit.z))
  hit=Plane(Vector3.UP,height).intersects_ray(origin,direction)
  if hit==null:return null
 return Vector2(hit.x,hit.z)

func pick_screen(pos: Vector2) -> Dictionary:
 var p=world_at_screen(pos)
 if p==null:return {}
 var closest: Dictionary={}
 var distance=2.3
 for u in sim.units:
  var d: float=u.pos.distance_to(p)
  if u.hp>0 and d<distance:
   distance=d;closest={"kind":"friendly_unit" if u.team==0 else "enemy_unit","id":u.id,"pos":u.pos}
 if not closest.is_empty():return closest
 for h in sim.hq:
  if h.hp>0 and h.pos.distance_to(p)<3.4:
   return {"kind":"friendly_building" if h.team==0 else "enemy_building","id":Sim.FRIENDLY_HQ if h.team==0 else Sim.ENEMY_HQ,"pos":h.pos}
 return {"kind":"terrain","pos":p}

func select_class_near(id: int):
 var source: Dictionary={}
 for u in sim.units:
  if u.id==id and u.team==0 and u.hp>0:source=u
 if source.is_empty():return
 if not additive_selection:selected.clear()
 for u in sim.units:
  if u.team==0 and u.hp>0 and u.type==source.type and u.pos.distance_to(source.pos)<=25 and not selected.has(u.id):selected.append(u.id)
 clear_direct()
 hud.refresh()

func save_group(slot: int):
 var err=control_groups.assign(slot,selected,sim.units)
 message.text="Group "+str(slot)+" saved" if err==OK else "Group could not be saved"
 hud.refresh()

func recall_group(slot: int):
 var ids=control_groups.recall(slot,sim.units)
 if ids.is_empty():message.text="Group "+str(slot)+" has no living matching units";return
 clear_direct();selected=ids;hud.refresh()

func feedback(pos: Vector2,kind: String):
 if pos.is_finite():
  if order_feedback.size()>=12:order_feedback.pop_front()
  order_feedback.append({"pos":pos,"kind":kind,"age":0.})
  hud.overlay.queue_redraw()

func dispatch_tap(hit: Dictionary,screen: Vector2,append_order: bool,double_tap: bool = false):
 if hit.is_empty() or sim==null or not sim.result.is_empty():return
 var kind: String=hit.kind
 if kind=="friendly_unit":
  var alive=sim.units.any(func(u):return u.id==hit.id and u.team==0 and u.hp>0)
  if not alive:message.text="Unit no longer available";return
  if double_tap:select_class_near(hit.id)
  else:
   clear_direct()
   if additive_selection:
    if selected.has(hit.id):selected.erase(hit.id)
    else:selected.append(hit.id)
   else:selected=[hit.id]
  hud.refresh()
  return
 if kind=="friendly_building":
  hud.open_building(hit.id)
  return
 var target_id: int=hit.id if kind in ["enemy_unit","enemy_building"] else -1
 var p=hit.pos if target_id!=-1 else world_at_screen(screen)
 if p==null:return
 if not sim.command(selected,p,target_id,command_formation,append_order):
  message.text="Order unavailable: invalid target, outside map, or queue full"
  feedback(p,"reject")
 else:
  var label_="Attack confirmed" if target_id!=-1 else "Waypoint queued" if append_order else "Move confirmed"
  message.text=label_+"  /  "+str(selected.size())+" units"
  feedback(p,"attack" if target_id!=-1 else "move")
 hud.refresh()

func _input(event):
 if sim!=null and touch_input.handle(event):get_viewport().set_input_as_handled()

func _unhandled_input(event):
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode==KEY_F3:hud.developer.visible=not hud.developer.visible
  elif event.keycode==KEY_Q:camera_yaw-=.15;update_camera()
  elif event.keycode==KEY_E:camera_yaw+=.15;update_camera()
  elif event.keycode==KEY_ESCAPE:hud.briefing.visible=not hud.briefing.visible;paused=true;touch_input.cancel();clear_direct()
  elif event.keycode in [KEY_1,KEY_2,KEY_3]:
   var slot=event.keycode-KEY_1+1
   if event.ctrl_pressed:save_group(slot)
   else:recall_group(slot)
 else:touch_input.handle(event)

func _physics_process(dt):
 if sim==null or paused or not sim.result.is_empty(): return
 direct=Vector2.ZERO
 if touching:
  for axis in pad_axes.values(): direct+=axis
 else:
  direct=Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
 for u in sim.units:
  u.direct=direct if selected.size()==1 and selected.has(u.id) else Vector2.ZERO
  if u.direct!=Vector2.ZERO: sim.direct_control(u.id,u.direct)
 accumulator+=minf(dt,0.1)
 while accumulator>=Sim.STEP and sim.result.is_empty():
  sim.tick()
  for shot in sim.shots:
   effects.shot(shot,sim.units[shot.id-1].type)
   visuals[shot.id].aim=shot.to
   var ap = visuals[shot.id].animation
   if ap is AnimationPlayer:
    for a in ap.get_animation_list():
     if a!="RESET": ap.play(a); break
  accumulator-=Sim.STEP
 if not sim.result.is_empty() and not saved:
  saved=true
  var err = Campaign.save_result(sim.result,battle_id)
  message.text=("VICTORY" if sim.result.winner==0 else "DEFEAT" if sim.result.winner==1 else "DRAW")+" / "+sim.result.reason+(". Saved locally." if err==OK else ". SAVE FAILED: "+error_string(err))
  refresh_campaign()
  hud.show_result(sim.result)

func _process(dt):
 if sim==null:return
 var now=Time.get_ticks_usec()
 if last_frame_usec>0 and frame_samples.size()<10000:
  frame_samples.append((now-last_frame_usec)/1000.0)
  draw_samples.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
 last_frame_usec=now
 peak_memory=maxf(peak_memory,Performance.get_monitor(Performance.MEMORY_STATIC))
 peak_video_memory=maxf(peak_video_memory,Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED))
 touch_input.advance(Time.get_ticks_msec())
 for item in order_feedback:item.age+=dt
 order_feedback=order_feedback.filter(func(item):return item.age<1.)
 update_visuals(dt)
 hud_elapsed+=dt
 if hud_elapsed>.1:
  hud.refresh();hud_elapsed=0
  status.text="%d FPS  |  %d draws  |  %.1f MB video\n%.1f MB static  |  simulation 30 Hz" % [Engine.get_frames_per_second(),Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),peak_video_memory/1048576.,peak_memory/1048576.]
  unit_text.text="units: "+str(sim.units.size())+" | active FX: "+str(effects.items.size())+"\nSave: "+str(saved)+" | Camera size: "+str(camera_zoom)
 hud.overlay.queue_redraw();hud.minimap.queue_redraw()

func update_visuals(dt: float):
 for u in sim.units:
  var v=visuals[u.id]
  var n: Node3D=v.node
  n.position=Field.ground(u.pos)
  var direction: Vector2=u.pos-v.last
  if direction.length()>.001:n.rotation.y=lerp_angle(n.rotation.y,atan2(direction.x,direction.y),minf(1,dt*12) if dt>0 else 1.)
  v.travel+=direction.length()
  v.paint.set_shader_parameter("tread_phase",v.travel)
  v.last=u.pos
  if v.turret!=null:
   var aim: Vector2=v.aim-u.pos
   if aim.length()>.01:v.turret.rotation.y=lerp_angle(v.turret.rotation.y,atan2(aim.x,aim.y)-n.rotation.y,minf(1,dt*8))
  if u.hp<v.hp:v.damage=.12
  v.hp=u.hp
  v.damage=maxf(0,v.damage-dt)
  var meshes: Array=v.meshes
  if u.hp<=0 and not v.dead:
   v.dead=true;effects.destroyed(n.position);n.rotation.z=.08
   for mesh in meshes:
    if mesh!=v.ring:mesh.material_override=Field.mat("wreck",Color("34382f"))
  var flash=Field.mat("damage flash",Color(1,.40,.18,.22))
  flash.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
  flash.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
  for mesh in meshes:
   if mesh!=v.ring:mesh.material_overlay=flash if v.damage>0 else null
  v.ring.visible=selected.has(u.id) and u.hp>0
 for i in relay_visuals.size():
  relay_visuals[i].material_override=Field.mat("beacon "+str(sim.points[i].owner),Color("bddc95") if sim.points[i].owner==0 else Color("d38c65") if sim.points[i].owner==1 else Color("d8c590"))
