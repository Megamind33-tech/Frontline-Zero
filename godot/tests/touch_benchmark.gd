extends SceneTree
const Field=preload("res://src/battlefield.gd")
func _initialize():call_deferred("run")
func percentile(values: Array,fraction: float) -> float:
 values.sort()
 return values[mini(values.size()-1,int(values.size()*fraction))]
func run():
 var scene=load("res://main.tscn").instantiate();root.add_child(scene)
 await process_frame
 scene.hud.briefing.hide();scene.paused=true;scene.select_all()
 var p=scene.camera.unproject_position(Field.ground(Vector2(35,25)))
 var samples: Array=[]
 for i in 1000:
  var event=InputEventScreenTouch.new();event.pressed=true;event.index=0;event.position=p
  var start=Time.get_ticks_usec()
  root.push_input(event,true)
  event=event.duplicate();event.pressed=false;root.push_input(event,true)
  samples.append((Time.get_ticks_usec()-start)/1000.)
 var result={"scope":"host headless engine-dispatched tap CPU cost, no raster/display/network/device input latency", "android_device":false,"tap_pairs":1000,"units_per_order":scene.selected.size(),"p50_ms":percentile(samples,.5),"p95_ms":percentile(samples,.95),"p99_ms":percentile(samples,.99),"feedback_count":scene.order_feedback.size()}
 var path=ProjectSettings.globalize_path("res://../dist/DIRECT_TOUCH-input-performance.json")
 var f=FileAccess.open(path,FileAccess.WRITE);f.store_string(JSON.stringify(result," ")+"\n");f.close()
 print("INPUT BENCHMARK: ",JSON.stringify(result))
 scene.queue_free();await process_frame;quit()
