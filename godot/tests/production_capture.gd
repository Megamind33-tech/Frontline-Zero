extends SceneTree
## Time-compressed in-engine capture. Supply is funded, then real build and production ticks run.
const Field=preload("res://src/battlefield.gd")
var battle
var frame=0
func _initialize():call_deferred("start")
func start():
 battle=load("res://main.tscn").instantiate()
 root.add_child(battle)
 await process_frame
 battle.deploy()
 battle.paused=true
 battle.hud.briefing.hide()
 battle.camera_focus=Vector2(18,42)
 battle.camera_zoom=36
 battle.update_camera()
func button_prefix(parent: Node, prefix: String) -> Button:
 for button in parent.find_children("*","Button",true,false):
  if button.visible and str(button.text).begins_with(prefix):return button
 return null
func click(world: Vector2):
 var event=InputEventScreenTouch.new()
 event.index=0;event.pressed=true
 event.position=battle.camera.unproject_position(Field.ground(world))
 root.push_input(event,true)
 event=event.duplicate();event.pressed=false;root.push_input(event,true)
func ui_click(button: Button):
 var event=InputEventMouseButton.new();event.device=InputEvent.DEVICE_ID_EMULATION
 event.position=button.get_global_rect().get_center();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true
 root.push_input(event,true)
 event=event.duplicate();event.pressed=false;root.push_input(event,true)
func advance(steps: int):
 for _i in steps:
  if battle.sim.result.is_empty():battle.sim.tick()
 battle.update_visuals(0)
 battle.hud.refresh()
func _process(_dt):
 if battle==null or battle.sim==null:return false
 frame+=1
 if frame==10:
  battle.sim.supply[0]=battle.Sim.FACTORY_COST+200
  click(battle.sim.hq[0].pos)
 if frame==16:
  var build=button_prefix(battle.hud.building_panel,"Build factory")
  if build!=null:ui_click(build)
  else:push_error("FAIL: factory button missing")
 if frame>=17 and frame<=46:advance(20)
 if frame==48:
  var yard=battle.sim.building_for(0)
  if not yard.is_empty():click(yard.pos)
 if frame==54:
  var tank=button_prefix(battle.hud.produce_row,"Tank")
  if tank!=null:ui_click(tank)
  else:push_error("FAIL: tank production button missing")
 if frame>=55 and frame<=86:advance(22)
 if frame==88:
  var newbie=battle.sim.units[-1]
  battle.selected=[newbie.id]
  battle.sim.command([newbie.id],battle.sim.hq[1].pos,battle.Sim.ENEMY_HQ)
  battle.camera_focus=newbie.pos
  battle.camera_zoom=42
  battle.update_camera()
  battle.paused=false
 if frame==150:
  var yard=battle.sim.building_for(0)
  print("CAPTURE factory=",yard.get("complete",false)," units=",battle.sim.units.size()," last=",battle.sim.units[-1].type," team=",battle.sim.units[-1].team)
  quit(0 if yard.get("complete",false) and battle.sim.units.size()>10 else 1)
 return false
