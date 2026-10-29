extends Node3D
const Sim = preload("res://src/simulation.gd")
const Campaign = preload("res://src/campaign.gd")
var sim
var selected: Array = []
var command_formation = "box"
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
 for role in ["scout","tank","artillery"]:
  var path = "res://assets/%s.tscn" % role
  if ResourceLoader.exists(path):
   model_scenes[role] = load(path)
 var light = DirectionalLight3D.new()
 light.rotation_degrees = Vector3(-55,-25,0)
 light.light_energy = 1.3
 light.shadow_enabled = false
 add_child(light)
 var world = WorldEnvironment.new()
 world.environment = Environment.new()
 world.environment.background_mode = Environment.BG_COLOR
 world.environment.background_color = Color("17241f")
 world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 world.environment.ambient_light_color = Color("c9d3b9")
 world.environment.ambient_light_energy = 0.65
 world.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
 add_child(world)
 camera = Camera3D.new()
 add_child(camera)
 camera.projection = Camera3D.PROJECTION_ORTHOGONAL
 camera.size = 82
 camera.h_offset = 13
 camera.position = Vector3(50,100,94)
 camera.look_at(Vector3(50,0,32.5))
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
 var layer = CanvasLayer.new()
 add_child(layer)
 var top = PanelContainer.new()
 top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
 layer.add_child(top)
 var topbox = VBoxContainer.new()
 top.add_child(topbox)
 status = Label.new()
 status.text = "FRONTLINE ZERO / OFFLINE VERTICAL SLICE"
 topbox.add_child(status)
 campaign_text = Label.new()
 topbox.add_child(campaign_text)
 var panel = PanelContainer.new()
 panel.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
 panel.offset_left = -270
 panel.offset_top = 60
 panel.offset_bottom = -8
 layer.add_child(panel)
 var scroll = ScrollContainer.new()
 panel.add_child(scroll)
 var box = VBoxContainer.new()
 box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 box.custom_minimum_size.x = 250
 scroll.add_child(box)
 var title = Label.new()
 title.text = "ASTER COMMAND / WORKSHOP"
 box.add_child(title)
 chassis = option(box,"CHASSIS",["tracked","wheeled"])
 weapon = option(box,"WEAPON",["cannon","autocannon","howitzer"])
 armor = option(box,"ARMOR",["light","heavy"])
 workshop_text = Label.new()
 box.add_child(workshop_text)
 button(box,"Deploy territory force",func(): loadout=["tank","tank","scout","scout","artillery"]; deploy())
 button(box,"Deploy siege force",deploy_siege)
 button(box,"Deploy custom force",func(): loadout=["custom","custom","scout","artillery"]; deploy())
 pause_button = button(box,"Resume",func(): paused=not paused; pause_button.text="Resume" if paused else "Pause"; clear_direct())
 button(box,"Select all",select_all)
 var formation_button = button(box,"Formation: Box",func(): pass)
 formation_button.pressed.connect(func():
  command_formation = "line" if command_formation == "box" else "box"
  formation_button.text = "Formation: " + command_formation.capitalize())
 button(box,"Hold position",func():
  clear_direct()
  for u in sim.units:
   if selected.has(u.id): u.order={})
 unit_text = Label.new()
 box.add_child(unit_text)
 var pad = GridContainer.new()
 pad.columns = 3
 box.add_child(pad)
 for item in [["",Vector2.ZERO],["↑",Vector2.UP],["",Vector2.ZERO],["←",Vector2.LEFT],["↓",Vector2.DOWN],["→",Vector2.RIGHT]]:
  var b = Button.new()
  b.text = item[0]
  b.custom_minimum_size = Vector2(70,48)
  b.disabled = item[0].is_empty()
  pad.add_child(b)
  var axis: Vector2 = item[1]
  b.button_down.connect(func(): pad_axes[b.get_instance_id()]=axis; touching=true)
  b.button_up.connect(func(): pad_axes.erase(b.get_instance_id()); touching=not pad_axes.is_empty())
 message = Label.new()
 message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 message.custom_minimum_size.x = 230
 box.add_child(message)
 message.text = "Tap friendly unit, then ground to move or enemy to focus fire. WASD/arrows/pad directly drive one selected unit. Units fire automatically. Relays: 120 combined seconds, or destroy HQ. Woods absorb 40% damage. Mud slows units."
 update_blueprint()

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
 cube(map_root,Vector3(50,-0.5,32.5),Vector3(100,1,65),Color("526549"))
 cube(map_root,Vector3(50,0.015,32.5),Vector3(100,0.03,6),Color("797b68"))
 cube(map_root,Vector3(50,0.025,32.5),Vector3(12,0.05,18),Color("635c40"))
 for p in sim.points:
  cube(map_root,Vector3(p.pos.x,0.02,p.pos.y),Vector3(22,0.04,11.5),Color("354d32"))
  var relay = cube(map_root,Vector3(p.pos.x,2,p.pos.y),Vector3(1,4,1),Color("ded7b1"))
  relay_visuals.append(relay)
  for i in 14:
   var x = 40+(i%7)*3.2
   var z = p.pos.y-4 if i<7 else p.pos.y+4
   cube(map_root,Vector3(x,1.7,z),Vector3(1.4,3.4,1.4),Color("273e2c"))
 for h in sim.hq:
  var n = cube(map_root,Vector3(h.pos.x,1.5,h.pos.y),Vector3(5,3,6),Color("91ad72") if h.team==0 else Color("b47c65"))
  cube(n,Vector3(0,2,0),Vector3(3,1,3),Color("343f35"))
  hq_visuals.append(n)
 for u in sim.units:
  var n = Node3D.new()
  map_root.add_child(n)
  if model_scenes.has(u.type):
   var model = model_scenes[u.type].instantiate()
   n.add_child(model)
  else:
   cube(n,Vector3(0,0.7,0),Vector3(2,1.4,3),Color("82995f"))
  var badge = cube(n,Vector3(0,2.3,0),Vector3(1.2,0.15,0.7),Color("d6ec9a") if u.team==0 else Color("ec9272"))
  var ring = MeshInstance3D.new()
  var torus = TorusMesh.new()
  torus.inner_radius=1.9
  torus.outer_radius=2.05
  torus.rings=12
  torus.ring_segments=12
  ring.mesh=torus
  ring.material_override=material(Color("fff6ad"))
  n.add_child(ring)
  ring.position.y=0.13
  ring.visible=false
  visuals[u.id]={"node":n,"ring":ring,"badge":badge,"last":u.pos,"animation":n.find_child("AnimationPlayer",true,false)}
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
  clear_direct()
  if is_instance_valid(pause_button): pause_button.text="Resume"

func _unhandled_input(event):
 var pos: Vector2
 if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
  pos=event.position
 elif event is InputEventScreenTouch and event.pressed:
  pos=event.position
 else: return
 if sim==null or not sim.result.is_empty(): return
 var hit = Plane(Vector3.UP,0).intersects_ray(camera.project_ray_origin(pos),camera.project_ray_normal(pos))
 if hit==null: return
 var p = Vector2(hit.x,hit.z)
 for u in sim.units:
  if u.hp>0 and u.team==0 and u.pos.distance_to(p)<3:
   clear_direct()
   selected=[u.id]
   return
 var target_id=-1
 for u in sim.units:
  if u.hp>0 and u.team==1 and u.pos.distance_to(p)<3: target_id=u.id
 sim.command(selected,p,target_id,command_formation)

func _physics_process(dt):
 if sim==null or paused or not sim.result.is_empty(): return
 direct=Vector2.ZERO
 if touching:
  for axis in pad_axes.values(): direct+=axis
 else:
  direct=Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
 for u in sim.units:
  u.direct=direct if selected.size()==1 and selected.has(u.id) else Vector2.ZERO
  if u.direct!=Vector2.ZERO: u.order={}
 accumulator+=minf(dt,0.1)
 while accumulator>=Sim.STEP and sim.result.is_empty():
  sim.tick()
  for shot in sim.shots:
   active_shots.append({"shot":shot,"ttl":0.12})
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

func _process(dt):
 if sim==null: return
 update_visuals(dt)
 status.text="FRONTLINE ZERO | ASTER %d/120 — VEYR %d/120 | %ds | %d FPS | %d draws | %.1f MB video" % [sim.score[0],sim.score[1],sim.time,Engine.get_frames_per_second(),Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)/1048576.0]
 var text="SELECTED: "+str(selected)+"\n"
 for u in sim.units:
  if u.team==0: text+="%s %d / %d HP\n" % [u.type,u.id,maxi(0,ceili(u.hp))]
 unit_text.text=text
 queue_redraw_if_needed()

func update_visuals(dt: float):
 for u in sim.units:
  var v=visuals[u.id]
  var n: Node3D=v.node
  n.position=Vector3(u.pos.x,0,u.pos.y)
  var direction: Vector2=u.pos-v.last
  if direction.length()>0.001: n.rotation.y=atan2(-direction.x,-direction.y)
  v.last=u.pos
  n.scale=Vector3.ONE if u.hp>0 else Vector3(1,0.2,1)
  v.ring.visible=selected.has(u.id) and u.hp>0
  v.badge.scale.x=maxf(0.01,u.hp/u.max_hp)
 for i in relay_visuals.size():
  relay_visuals[i].material_override.albedo_color=Color("d6ec9a") if sim.points[i].owner==0 else Color("ec9272") if sim.points[i].owner==1 else Color("ded7b1")
 for item in active_shots: item.ttl-=dt
 active_shots=active_shots.filter(func(item):return item.ttl>0)

func queue_redraw_if_needed():
 # Short-lived tracers use an ImmediateMesh; one draw for all active shots.
 var old=map_root.get_node_or_null("Tracers")
 if old!=null:
  map_root.remove_child(old)
  old.queue_free()
 if active_shots.is_empty(): return
 var mesh=ImmediateMesh.new()
 mesh.surface_begin(Mesh.PRIMITIVE_LINES)
 for item in active_shots:
  var s=item.shot
  mesh.surface_add_vertex(Vector3(s.from.x,1.5,s.from.y))
  mesh.surface_add_vertex(Vector3(s.to.x,1.5,s.to.y))
 mesh.surface_end()
 var n=MeshInstance3D.new()
 n.name="Tracers"
 n.mesh=mesh
 var m=material(Color("ffe0a0"))
 m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 n.material_override=m
 map_root.add_child(n)
