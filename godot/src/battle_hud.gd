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
var advanced: PanelContainer
var building_panel: PanelContainer
var building_label: Label
var group_buttons: Array=[]
var multi_button: Button
var result_title: Label
var begin: Button
var role_buttons: Array=[]
var drive_button: Button
var theme_=Theme.new()
var panel_title: Label
var panel_mode: String="hq"
var build_factory: Button
var workshop_button: Button
var briefing_button: Button
var produce_row: HBoxContainer
var warning: Label

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
 objective=label(mission,"SUPPLY 0    NORTH  ○   SOUTH  ○    00:00",18)
 warning=label(mission,"",13,Color("e2c07a"))
 battle.pause_button=button(row,"Resume",func():
  battle.paused=not battle.paused;battle.pause_button.text="Resume" if battle.paused else "Pause";battle.clear_direct())
 button(row,"Menu",func():briefing.visible=not briefing.visible;battle.paused=true;battle.clear_direct();battle.pause_button.text="Resume")
 # Tactical map and squad selector form the permanent information frame.
 var map_panel=panel(root_);map_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT);map_panel.offset_left=16;map_panel.offset_top=-175;map_panel.offset_right=222;map_panel.offset_bottom=-14
 var map_box=VBoxContainer.new();map_panel.add_child(map_box)
 label(map_box,"TACTICAL MAP",11,Color("a1b396"))
 minimap=Overlay.new();minimap.minimap=true;minimap.battle=battle;minimap.custom_minimum_size=Vector2(176,110);minimap.clip_contents=true;map_box.add_child(minimap)
 context=panel(root_);context.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE);context.offset_left=234;context.offset_top=-82;context.offset_right=-16;context.offset_bottom=-14
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
 button(select_row,"More",func():open_advanced(Vector2(context.position.x+context.size.x-320,context.position.y-220)))
 for slot in [1,2,3]:
  var number=slot
  var b=button(select_row,str(slot),func():battle.recall_group(number))
  b.custom_minimum_size.x=44;b.tooltip_text="Recall control group "+str(slot)
  group_buttons.append(b)
 advanced=panel(root_);advanced.custom_minimum_size=Vector2(360,0);advanced.z_index=20;advanced.hide()
 var advanced_box=VBoxContainer.new();advanced.add_child(advanced_box)
 label(advanced_box,"ADVANCED ORDERS  /  HOLD A SELECTED UNIT",12,Color("b7c59c"))
 var commands=HBoxContainer.new();advanced_box.add_child(commands)
 var formation=button(commands,"Formation: Box",func():pass)
 formation.pressed.connect(func():battle.command_formation="line" if battle.command_formation=="box" else "box";formation.text="Formation: "+battle.command_formation.capitalize())
 battle.queue_button=button(commands,"Queue orders",func():pass);battle.queue_button.toggle_mode=true
 battle.queue_button.toggled.connect(func(enabled):battle.queue_orders=enabled;battle.hud.refresh())
 button(commands,"Hold position",func():battle.clear_direct();battle.sim.hold(battle.selected);close_advanced())
 var selection_row=HBoxContainer.new();advanced_box.add_child(selection_row)
 multi_button=button(selection_row,"Add selection",func():pass);multi_button.toggle_mode=true
 multi_button.toggled.connect(func(enabled):battle.additive_selection=enabled;refresh())
 button(selection_row,"All",func():battle.select_all();refresh())
 button(selection_row,"Clear",func():battle.clear_direct();battle.selected.clear();close_advanced())
 var group_row=HBoxContainer.new();advanced_box.add_child(group_row)
 label(group_row,"SAVE GROUP",12)
 for slot in [1,2,3]:
  var number=slot
  button(group_row,str(slot),func():battle.save_group(number))
 drive_button=button(advanced_box,"Direct drive",func():pass);drive_button.toggle_mode=true
 drive_button.toggled.connect(func(enabled):battle.clear_direct();drive_pad.visible=enabled and battle.selected.size()==1)
 drive_pad=GridContainer.new();drive_pad.columns=3;advanced_box.add_child(drive_pad);drive_pad.hide()
 for item in [["",Vector2.ZERO],["↑",Vector2.UP],["",Vector2.ZERO],["←",Vector2.LEFT],["↓",Vector2.DOWN],["→",Vector2.RIGHT]]:
  var axis: Vector2=item[1]
  var b=button(drive_pad,item[0],func():pass);b.disabled=item[0].is_empty();b.custom_minimum_size=Vector2(74,46)
  b.button_down.connect(func():battle.pad_axes[b.get_instance_id()]=axis;battle.touching=true)
  b.button_up.connect(func():battle.pad_axes.erase(b.get_instance_id());battle.touching=not battle.pad_axes.is_empty())
 button(advanced_box,"Close",close_advanced)
 building_panel=panel(root_);building_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT);building_panel.offset_left=-330;building_panel.offset_top=96;building_panel.offset_right=-16;building_panel.z_index=10;building_panel.hide()
 var building_box=VBoxContainer.new();building_panel.add_child(building_box)
 panel_title=label(building_box,"ASTER COMMAND POST",20)
 building_label=label(building_box,"",15)
 building_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 building_label.custom_minimum_size.x=270
 build_factory=button(building_box,"Build vehicle factory",func():
  if battle.sim.construct(0):battle.message.text=battle.sim.warning
  else:battle.message.text=battle.sim.warning
  refresh())
 workshop_button=button(building_box,"Vehicle workshop",func():building_panel.hide();briefing.show();workshop.show();battle.paused=true;battle.clear_direct();battle.pause_button.text="Resume")
 briefing_button=button(building_box,"Mission briefing",func():building_panel.hide();briefing.show();battle.paused=true;battle.clear_direct();battle.pause_button.text="Resume")
 produce_row=HBoxContainer.new();building_box.add_child(produce_row);produce_row.hide()
 for role in ["scout","tank","artillery"]:
  var kind=role
  button(produce_row,role.capitalize(),func():
   battle.message.text=battle.sim.warning if not battle.sim.enqueue(0,kind) else battle.sim.warning
   refresh())
 button(building_box,"Close",func():building_panel.hide())
 battle.message=Label.new();battle.message.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 root_.add_child(battle.message);battle.message.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE);battle.message.offset_left=242;battle.message.offset_top=-128;battle.message.offset_right=-20;battle.message.offset_bottom=-86
 battle.message.add_theme_color_override("font_shadow_color",Color(0,0,0,.9))
 battle.message.add_theme_constant_override("shadow_offset_x",1);battle.message.add_theme_constant_override("shadow_offset_y",1)
 battle.message.add_theme_font_size_override("font_size",13);battle.message.add_theme_color_override("font_color",Color("e0d3b0"))
 battle.message.text="Tap units / terrain / enemy  •  Drag, pinch, rotate camera  •  Hold for orders; double-tap selects a class"
 # Deployment/customization is a modal briefing, never a permanent debug sidebar.
 briefing=panel(root_);briefing.set_anchors_and_offsets_preset(Control.PRESET_CENTER);briefing.offset_left=-270;briefing.offset_right=270;briefing.offset_top=-245;briefing.offset_bottom=225
 var brief=VBoxContainer.new();brief.add_theme_constant_override("separation",10);briefing.add_child(brief)
 label(brief,"OPERATION  /  04",12,Color("a2b68a"))
 result_title=label(brief,"IRON CROSSING",32)
 var desc=label(brief,"Two woodland relays feed supply. Build a vehicle factory at the command post and replace losses.\nCapture 120 relay-seconds, destroy the Veyr HQ, or eliminate a force that cannot rebuild.\nWoods reduce incoming damage; crossing mud costs speed. Fifteen minutes.",16);desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
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
 selection.text=(str(count)+" SELECTED · "+str(queued)+" ORDERS"+(" · QUEUE" if battle.queue_orders else "")+(" · MULTI" if battle.additive_selection else "")) if count>0 else "TASK FORCE"
 for i in group_buttons.size():
  group_buttons[i].disabled=battle.control_groups.recall(i+1,s.units).is_empty()
 for i in role_buttons.size():
  var role=["scout","tank","artillery"][i]
  var amount=living.filter(func(u):return u.type==role).size()
  role_buttons[i].text=role.capitalize()+"  "+str(amount)
  role_buttons[i].disabled=amount==0
 if count!=1:
  drive_pad.hide();drive_button.set_pressed_no_signal(false)
 var owners=[]
 for p in s.points:owners.append("ASTER" if p.owner==0 else "VEYR" if p.owner==1 else "NEUTRAL")
 objective.text="SUPPLY %d    N %s / S %s    %d:%d /120    %02d:%02d" % [int(s.supply[0]),owners[0],owners[1],s.score[0],s.score[1],int(s.time)/60,int(s.time)%60]
 warning.text=s.warning
 var yard=s.building_for(0)
 var factory_open=panel_mode=="factory"
 panel_title.text="VEHICLE FACTORY" if factory_open else "ASTER COMMAND POST"
 build_factory.visible=not factory_open
 workshop_button.visible=not factory_open
 briefing_button.visible=not factory_open
 produce_row.visible=factory_open
 if factory_open and not yard.is_empty():
  var line="Integrity %d / %d" % [maxi(0,ceili(yard.hp)),int(s.FACTORY_HP)]
  if not yard.complete:line+="\nConstruction %d%%" % int(yard.progress/s.FACTORY_SECONDS*100.0)
  else:
   line+="\nQueue"
   if yard.queue.is_empty():line+=" empty"
   for job in yard.queue:line+="\n%s  %ds" % [job.role.capitalize(),ceili(job.remaining)]
  building_label.text=line+"\nSupply %d" % int(s.supply[0])
 elif not factory_open:
  building_label.text="Integrity: %d / 1600\nSupply %d\n%s" % [maxi(0,ceili(s.hq[0].hp)),int(s.supply[0]),battle.campaign_text.text]
  build_factory.text="Build factory  %d supply" % int(s.FACTORY_COST)
  build_factory.disabled=not yard.is_empty() or s.supply[0]<s.FACTORY_COST or s.hq[0].hp<=0
 for child in produce_row.get_children():
  if child is Button:
   var role=child.text.split(" ")[0].to_lower()
   var cost=int(s.blueprint(s.PRESETS[role]).cost)
   child.text="%s  %d" % [role.capitalize(),cost]
   child.disabled=yard.is_empty() or not yard.complete or s.supply[0]<cost
 overlay.queue_redraw();minimap.queue_redraw()
func show_result(result: Dictionary):
 close_advanced();building_panel.hide()
 result_title.text="VICTORY" if result.winner==0 else "DEFEAT" if result.winner==1 else "STALEMATE"
 begin.text="Replay battle"
 for connection in begin.pressed.get_connections():begin.pressed.disconnect(connection.callable)
 begin.pressed.connect(func():battle.reset_battle();briefing.hide();battle.paused=false;battle.pause_button.text="Pause")
 briefing.show()

func blocks_world(pos: Vector2) -> bool:
 if briefing.visible:return true
 for child in get_child(0).get_children():
  if child is PanelContainer and child.is_visible_in_tree() and child.get_global_rect().has_point(pos):return true
 return false

func open_advanced(pos: Vector2):
 battle.clear_direct()
 advanced.show()
 var viewport=battle.get_viewport().get_visible_rect().size
 advanced.reset_size()
 advanced.position=pos.clamp(Vector2(12,88),viewport-advanced.size-Vector2(12,96))
 refresh()

func close_advanced():
 battle.clear_direct();drive_pad.hide();drive_button.set_pressed_no_signal(false);advanced.hide()

func open_building(id: int):
 var yard=battle.sim.building_for(0)
 if id==battle.Sim.FRIENDLY_HQ and battle.sim.hq[0].hp>0:panel_mode="hq"
 elif not yard.is_empty() and id==yard.id and yard.hp>0:panel_mode="factory"
 else:return
 close_advanced()
 building_panel.show()
 refresh()
