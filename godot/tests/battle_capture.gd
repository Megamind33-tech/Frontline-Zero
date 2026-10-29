extends SceneTree
## Reproducible real-engine gameplay driven through existing input/UI paths.
const Field=preload("res://src/battlefield.gd")
var battle
var finishing=false
var last_sim_tick=-1
var current_sim_tick=0
var frame=0
var benchmark=false
var photographed=false
var outcome_frame=-1
var out=ProjectSettings.globalize_path("res://../dist/")
func _initialize():
 benchmark=OS.get_cmdline_user_args().has("--benchmark")
 call_deferred("start")
func start():
 battle=load("res://main.tscn").instantiate()
 root.add_child(battle)
 await process_frame
 battle.deploy_siege()
 battle.hud.briefing.hide()
 battle.camera_focus=Vector2(50,32.5)
 battle.camera_zoom=65
 battle.update_camera()
 battle.command_formation="line"
 battle.hud.refresh()
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
func named_button(parent: Node,text_: String):
 for button in parent.find_children("*","Button",true,false):
  if button.text==text_ and button.is_visible_in_tree():return button
 return null
func hold_unit(id: int):
 var event=InputEventScreenTouch.new();event.index=0;event.pressed=true
 event.position=battle.camera.unproject_position(Field.ground(battle.sim.units[id-1].pos))
 root.push_input(event,true)
func release_hold():
 if not battle.touch_input.pointers.has(0):return
 var event=InputEventScreenTouch.new();event.index=0;event.pressed=false;event.position=battle.touch_input.pointers[0].pos
 root.push_input(event,true)
func close_advanced():
 var button=named_button(battle.hud.advanced,"Close")
 if button!=null:ui_click(button)
func due(step: int) -> bool:
 return frame==step if not benchmark else last_sim_tick<step and current_sim_tick>=step
func _process(_dt):
 if finishing or battle==null or battle.sim==null:return false
 frame+=1
 current_sim_tick=floori(battle.sim.time*30)
 if due(4):click(battle.sim.hq[0].pos)
 if due(18):
  var close=named_button(battle.hud.building_panel,"Close")
  if close!=null:ui_click(close)
 if due(24):
  click(battle.sim.units[0].pos);click(battle.sim.units[0].pos)
 if due(32):click(battle.sim.units[5].pos)
 if due(40):hold_unit(1)
 if due(60):
  release_hold()
  if battle.hud.advanced.visible:ui_click(battle.queue_button)
  close_advanced()
 if due(64):click(battle.sim.hq[1].pos)
 if due(70):hold_unit(1)
 if due(90):
  release_hold()
  var save=named_button(battle.hud.advanced,"1")
  if save!=null:ui_click(save)
  if battle.hud.advanced.visible and battle.queue_orders:ui_click(battle.queue_button)
  close_advanced()
 if due(95):click(battle.sim.units[2].pos)
 if due(100):click(Vector2(30,13))
 if due(105):hold_unit(3)
 if due(125):
  release_hold()
  if battle.hud.advanced.visible and not battle.queue_orders:ui_click(battle.queue_button)
  close_advanced()
 if due(128):click(Vector2(50,13))
 if due(135):
  var more=named_button(battle.hud.context,"More")
  if more!=null:ui_click(more)
 if due(145):
  if battle.hud.advanced.visible and battle.queue_orders:ui_click(battle.queue_button)
  close_advanced()
 if due(150):click(battle.sim.units[3].pos)
 if due(155):click(battle.sim.hq[1].pos)
 if due(160):
  for i in 2:
   var event=InputEventScreenTouch.new();event.index=i;event.pressed=true;event.position=Vector2(480+i*160,300);root.push_input(event,true)
 if due(165):
  var event=InputEventScreenDrag.new();event.index=1;event.position=Vector2(730,350);event.relative=Vector2(90,50);root.push_input(event,true)
 if due(170):
  for i in 2:
   var event=InputEventScreenTouch.new();event.index=i;event.pressed=false;event.position=Vector2(480,300) if i==0 else Vector2(730,350);root.push_input(event,true)
 if due(175):ui_click(battle.hud.group_buttons[0])
 if frame>=180 and frame<=300:
  battle.camera_focus=battle.camera_focus.lerp(Vector2(48,31),.02)
  battle.camera_yaw=lerpf(battle.camera_yaw,.40,.025)
  battle.update_camera()
 if due(360):
  battle.camera_zoom=32
  battle.camera_focus=Vector2(48,31)
  battle.update_camera()
 if frame>390 and not benchmark and not photographed and not battle.effects.shells.is_empty():
  photographed=true
  call_deferred("photograph")
 if not battle.sim.result.is_empty() and outcome_frame<0:
  outcome_frame=frame
  print("CAPTURE OUTCOME: ",JSON.stringify(battle.sim.result)," saved=",battle.saved)
 var limit=600 if benchmark else 1800
 if frame>=limit or (outcome_frame>=0 and frame-outcome_frame>=(1 if benchmark else 120)):
  call_deferred("finish")
 last_sim_tick=current_sim_tick
 return false
func photograph():
 await RenderingServer.frame_post_draw
 var path=out+"IRON_CROSSING-in-engine.png"
 var error=root.get_texture().get_image().save_png(path)
 print("ACTUAL IN-ENGINE SCREENSHOT: ",path," error=",error)
func percentile(values: Array, fraction: float) -> float:
 if values.is_empty():return 0
 var sorted=values.duplicate();sorted.sort()
 return sorted[mini(sorted.size()-1,int(sorted.size()*fraction))]
func finish():
 finishing=true
 if not photographed and not benchmark:
  await photograph()
 var samples=battle.frame_samples.slice(120)
 var draws=battle.draw_samples.slice(120)
 var rss_kb=0
 var status=FileAccess.get_file_as_string("/proc/self/status")
 for line in status.split("\n"):
  if line.begins_with("VmHWM:"):rss_kb=int(line.split(":")[1].strip_edges().split(" ",false)[0])
 var report={
  "engine":Engine.get_version_info().string,"renderer":RenderingServer.get_video_adapter_name(),
  "resolution":"1280x720","cpu":OS.get_processor_name(),"logical_cpus":OS.get_processor_count(),
  "capture_mode":"real-time rendered host benchmark, no movie writer" if benchmark else "offline fixed-30fps gameplay movie; includes recording/readback overhead",
  "samples":samples.size(),"simulation_hz":30,"units":battle.sim.units.size(),
  "wall_frame_ms_p50":percentile(samples,.50),"wall_frame_ms_p95":percentile(samples,.95),"wall_frame_ms_p99":percentile(samples,.99),
  "draw_calls_p50":percentile(draws,.50),"draw_calls_p95":percentile(draws,.95),
  "static_memory_peak_mib":battle.peak_memory/1048576.,"video_memory_peak_mib":battle.peak_video_memory/1048576.,"process_rss_peak_mib":rss_kb/1024. if rss_kb>0 else null,
  "shots_visualized":battle.effects.emitted,"input_demo":"engine-dispatched touch taps/holds, HUD emulated mouse, queued attacks, pinch/rotate, saved group recall","result":battle.sim.result,"saved":battle.saved,
  "android_device":false,"thermal_measurement":"unavailable: no representative physical Android hardware attached"}
 var name="IRON_CROSSING-host-performance.json" if benchmark else "IRON_CROSSING-movie-evidence.json"
 var file=FileAccess.open(out+name,FileAccess.WRITE)
 file.store_string(JSON.stringify(report," ")+"\n");file.close()
 print("RENDERED EVIDENCE: ",JSON.stringify(report))
 quit()
