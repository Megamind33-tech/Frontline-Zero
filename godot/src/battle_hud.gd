extends CanvasLayer
const Overlay=preload("res://src/tactical_overlay.gd")
var battle
var context: PanelContainer
var briefing: PanelContainer
var workshop: VBoxContainer
var developer: PanelContainer
var objective: Label
var selection: Label
var minimap
var overlay
var drive_pad: GridContainer
var camera_pad: GridContainer
var result_title: Label
var begin: Button
var role_buttons: Array=[]
var drive_button: Button
var theme_=Theme.new()

func style(color: Color, border: Color = Color("455349")) -> StyleBoxFlat:
 var s=StyleBoxFlat.new()
 s.bg_color=color;s.border_color=border
 s.set_border_width_all(1);s.set_corner_radius_all(5)
 s.content_margin_left=14;s.content_margin_right=14;s.content_margin_top=10;s.content_margin_bottom=10
 return s
func label(parent: Node, text_: String, size_: int = 16, color: Color = Color("dce2d2")) -> Label:
 var n=Label.new();n.text=text_;n.add_theme_font_size_override("font_size",size_);n.add_theme_color_override("font_color",color);parent.add_child(n);return n
func button(parent: Node,text_: String,action: Callable) -> Button:
 var b=Button.new();b.text=text_;b.custom_minimum_size=Vector2(74,46);b.focus_mode=Control.FOCUS_NONE
 b.add_theme_stylebox_override("normal",style(Color("202c26")))
 b.add_theme_stylebox_override("hover",style(Color("344538")))
 b.add_theme_stylebox_override("pressed",style(Color("47583a"),Color("b4c289")))
 b.add_theme_font_size_override("font_size",15)
 parent.add_child(b);b.pressed.connect(action);return b
func panel(parent: Node) -> PanelContainer:
 var p=PanelContainer.new();p.add_theme_stylebox_override("panel",style(Color(.075,.11,.09,.95)));parent.add_child(p);return p
func setup(controller):
 battle=controller
 var root_=Control.new();root_.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root_.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(root_)
 overlay=Overlay.new();overlay.battle=battle;root_.add_child(overlay);overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var header=panel(root_);header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE);header.offset_left=16;header.offset_top=12;header.offset_right=-16;header.offset_bottom=76
 var row=HBoxContainer.new();header.add_child(row)
 var brand=VBoxContainer.new();brand.custom_minimum_size.x=280;row.add_child(brand)
 label(brand,"FRONTLINE ZERO",23,Color("eceddd"))
 label(brand,"IRON CROSSING  /  ASTER TASK FORCE",11,Color("94a78f"))
 var mission=VBoxContainer.new();mission.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(mission)
 label(mission,"SECURE THE RELAYS  /  BREAK THE ENEMY HQ",12,Color("c6c9ab"))
 objective=label(mission,"NORTH  ○   SOUTH  ○                                      00:00",18)
 battle.pause_button=button(row,"Resume",func():
  battle.paused=not battle.paused;battle.pause_button.text="Resume" if battle.paused else "Pause";battle.clear_direct())
 button(row,"Menu",func():briefing.visible=not briefing.visible;battle.paused=true;battle.clear_direct();battle.pause_button.text="Resume")
 # Tactical map and squad selector form the permanent information frame.
 var map_panel=panel(root_);map_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT);map_panel.offset_left=16;map_panel.offset_top=-175;map_panel.offset_right=222;map_panel.offset_bottom=-14
 var map_box=VBoxContainer.new();map_panel.add_child(map_box)
 label(map_box,"TACTICAL MAP",11,Color("a1b396"))
 minimap=Overlay.new();minimap.minimap=true;minimap.battle=battle;minimap.custom_minimum_size=Vector2(176,110);minimap.clip_contents=true;map_box.add_child(minimap)
 context=panel(root_);context.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE);context.offset_left=234;context.offset_top=-124;context.offset_right=-206;context.offset_bottom=-14
 var context_box=VBoxContainer.new();context.add_child(context_box)
 var select_row=HBoxContainer.new();context_box.add_child(select_row)
 selection=label(select_row,"TASK FORCE  /  tap a unit or select a class",14);selection.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 button(select_row,"All",battle.select_all)
 for role in ["scout","tank","artillery"]:
  var r=role
  var b=button(select_row,role.capitalize(),func():
   battle.clear_direct();battle.selected.clear()
   for u in battle.sim.units:
    if u.team==0 and u.hp>0 and u.type==r:battle.selected.append(u.id))
  role_buttons.append(b)
 var commands=HBoxContainer.new();commands.add_theme_constant_override("separation",6);context_box.add_child(commands)
 var formation=button(commands,"Formation: Box",func():pass)
 formation.pressed.connect(func():battle.command_formation="line" if battle.command_formation=="box" else "box";formation.text="Formation: "+battle.command_formation.capitalize())
 battle.queue_button=button(commands,"Queue orders",func():pass);battle.queue_button.toggle_mode=true
 battle.queue_button.toggled.connect(func(enabled):battle.queue_orders=enabled)
 button(commands,"Hold position",func():battle.clear_direct();battle.sim.hold(battle.selected))
 drive_button=button(commands,"Direct drive",func():pass);drive_button.toggle_mode=true
 drive_button.toggled.connect(func(enabled):battle.clear_direct();drive_pad.visible=enabled and battle.selected.size()==1;camera_pad.visible=not drive_pad.visible)
 # One compact gesture/control cluster, with a contextual direct-drive pad.
 var camera_panel=panel(root_);camera_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT);camera_panel.offset_left=-194;camera_panel.offset_top=-188;camera_panel.offset_right=-16;camera_panel.offset_bottom=-14
 var control_box=VBoxContainer.new();camera_panel.add_child(control_box)
 label(control_box,"CAMERA / 2-FINGER DRAG",10,Color("a1b396"))
 camera_pad=GridContainer.new();camera_pad.columns=3;control_box.add_child(camera_pad)
 for item in [["↶",Vector2.ZERO],["↑",Vector2.UP],["↷",Vector2.ZERO],["←",Vector2.LEFT],["⌖",Vector2.ZERO],["→",Vector2.RIGHT],["−",Vector2.ZERO],["↓",Vector2.DOWN],["+",Vector2.ZERO]]:
  var text_: String=item[0];var axis: Vector2=item[1]
  var b=button(camera_pad,text_,func():
   if text_=="+":battle.zoom_camera(-5)
   elif text_=="−":battle.zoom_camera(5)
   elif text_=="↶":battle.camera_yaw-=.22;battle.update_camera()
   elif text_=="↷":battle.camera_yaw+=.22;battle.update_camera()
   elif text_=="⌖":battle.focus_selection())
  b.custom_minimum_size=Vector2(44,44)
  b.button_down.connect(func():battle.camera_axes[b.get_instance_id()]=axis)
  b.button_up.connect(func():battle.camera_axes.erase(b.get_instance_id()))
 drive_pad=GridContainer.new();drive_pad.columns=3;control_box.add_child(drive_pad);drive_pad.hide()
 for item in [["",Vector2.ZERO],["↑",Vector2.UP],["",Vector2.ZERO],["←",Vector2.LEFT],["↓",Vector2.DOWN],["→",Vector2.RIGHT]]:
  var axis: Vector2=item[1]
  var b=button(drive_pad,item[0],func():pass);b.disabled=item[0].is_empty();b.custom_minimum_size=Vector2(44,46)
  b.button_down.connect(func():battle.pad_axes[b.get_instance_id()]=axis;battle.touching=true)
  b.button_up.connect(func():battle.pad_axes.erase(b.get_instance_id());battle.touching=not battle.pad_axes.is_empty())
 battle.message=Label.new();battle.message.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 root_.add_child(battle.message);battle.message.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE);battle.message.offset_left=242;battle.message.offset_top=-174;battle.message.offset_right=-185;battle.message.offset_bottom=-128
 battle.message.add_theme_color_override("font_shadow_color",Color(0,0,0,.9))
 battle.message.add_theme_constant_override("shadow_offset_x",1);battle.message.add_theme_constant_override("shadow_offset_y",1)
 battle.message.add_theme_font_size_override("font_size",13);battle.message.add_theme_color_override("font_color",Color("e0d3b0"))
 battle.message.text="Tap to select / command  •  Drag to pan  •  Pinch to zoom  •  Woods absorb fire; mud slows vehicles"
 # Deployment/customization is a modal briefing, never a permanent debug sidebar.
 briefing=panel(root_);briefing.set_anchors_and_offsets_preset(Control.PRESET_CENTER);briefing.offset_left=-270;briefing.offset_right=270;briefing.offset_top=-245;briefing.offset_bottom=225
 var brief=VBoxContainer.new();brief.add_theme_constant_override("separation",10);briefing.add_child(brief)
 label(brief,"OPERATION  /  04",12,Color("a2b68a"))
 result_title=label(brief,"IRON CROSSING",32)
 var desc=label(brief,"Two woodland relays. One broken supply road.\nCapture 120 relay-seconds or destroy the Veyr HQ.\nWoods reduce incoming damage; crossing mud costs speed.",16);desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 battle.campaign_text=label(brief,"",13,Color("a2b68a"))
 begin=button(brief,"Begin battle",func():briefing.hide();battle.paused=false;battle.pause_button.text="Pause")
 var choices=HBoxContainer.new();brief.add_child(choices)
 button(choices,"Territory force",func():battle.loadout=["tank","tank","scout","scout","artillery"];battle.deploy();briefing.hide())
 button(choices,"Siege force",func():battle.deploy_siege();briefing.hide())
 button(choices,"Vehicle workshop",func():workshop.visible=not workshop.visible)
 workshop=VBoxContainer.new();brief.add_child(workshop);workshop.hide()
 var modules=HBoxContainer.new();workshop.add_child(modules)
 battle.chassis=battle.option(modules,"Chassis",["tracked","wheeled"])
 battle.weapon=battle.option(modules,"Weapon",["cannon","autocannon","howitzer"])
 battle.armor=battle.option(modules,"Armor",["light","heavy"])
 battle.workshop_text=label(workshop,"",14)
 button(workshop,"Deploy custom force",func():battle.loadout=["custom","custom","scout","artillery"];battle.deploy();briefing.hide())
 var footer=HBoxContainer.new();brief.add_child(footer)
 button(footer,"Return to battle",func():briefing.hide();battle.paused=false;battle.pause_button.text="Pause")
 button(footer,"Diagnostics / F3",func():developer.visible=not developer.visible)
 developer=panel(root_);developer.position=Vector2(18,90);developer.hide()
 var dev=VBoxContainer.new();developer.add_child(dev)
 label(dev,"DEVELOPER TELEMETRY  /  HOST ≠ PHONE",12)
 battle.status=label(dev,"",13)
 battle.unit_text=label(dev,"",12)
 battle.update_blueprint()
func refresh():
 var s=battle.sim
 var living=s.units.filter(func(u):return u.team==0 and u.hp>0)
 battle.selected=battle.selected.filter(func(id):return living.any(func(u):return u.id==id))
 var count=battle.selected.size()
 drive_button.disabled=count!=1
 drive_button.tooltip_text="Select one vehicle for direct control"
 var queued=0
 for u in living:
  if battle.selected.has(u.id):queued+=u.queue.size()+(0 if u.order.is_empty() else 1)
 selection.text=(str(count)+" SELECTED  ·  "+str(queued)+" ORDERS") if count>0 else "TASK FORCE"
 # Commands are contextual; role selectors and All remain accessible.
 var commands=context.get_child(0).get_child(1)
 commands.visible=count>0
 for i in role_buttons.size():
  var role=["scout","tank","artillery"][i]
  var amount=living.filter(func(u):return u.type==role).size()
  role_buttons[i].text=role.capitalize()+"  "+str(amount)
  role_buttons[i].disabled=amount==0
 if count!=1:
  drive_pad.hide();camera_pad.show();drive_button.set_pressed_no_signal(false)
 var owners=[]
 for p in s.points:owners.append("ASTER" if p.owner==0 else "VEYR" if p.owner==1 else "NEUTRAL")
 objective.text="N  "+owners[0]+"   /   S  "+owners[1]+"     %d : %d  /120     %02d:%02d" % [s.score[0],s.score[1],int(s.time)/60,int(s.time)%60]
 overlay.queue_redraw();minimap.queue_redraw()
func show_result(result: Dictionary):
 result_title.text="VICTORY" if result.winner==0 else "DEFEAT" if result.winner==1 else "STALEMATE"
 begin.text="Replay battle"
 for connection in begin.pressed.get_connections():begin.pressed.disconnect(connection.callable)
 begin.pressed.connect(func():battle.reset_battle();briefing.hide();battle.paused=false;battle.pause_button.text="Pause")
 briefing.show()
