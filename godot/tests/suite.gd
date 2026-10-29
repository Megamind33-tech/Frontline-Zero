extends SceneTree
const Sim = preload("res://src/simulation.gd")
const Campaign = preload("res://src/campaign.gd")
var count=0
var failures=0
func check(condition: bool, label: String):
 if not condition:
  push_error("FAIL: "+label)
  failures+=1
  return
 count+=1
 print("PASS: "+label)
func _initialize():
 var s=Sim.new()
 check(s.error.is_empty() and s.units.size()==10,"balanced default armies")
 check(Sim.blueprint({"chassis":"wheeled","weapon":"howitzer","armor":"heavy"}).has("error"),"invalid payload rejected")
 var light=Sim.blueprint(Sim.PRESETS.tank)
 var heavy=Sim.blueprint({"chassis":"tracked","weapon":"cannon","armor":"heavy"})
 check(heavy.hp>light.hp and heavy.speed<light.speed,"modules affect stats")
 check(not Sim.new(["artillery","artillery","artillery","artillery"]).error.is_empty(),"budget enforced")
 var before: Vector2=s.units[0].pos
 s.units[0].direct=Vector2.RIGHT
 s.tick()
 check(s.units[0].pos.x>before.x and s.units[1].pos.x==13,"direct control isolates unit")
 s=Sim.new()
 for i in 1800:
  s.tick()
 check(s.units.any(func(u):return u.hp<u.max_hp),"AI advances and combat damages units")
 s=Sim.new()
 s.hq[1].hp=0
 s.tick()
 check(s.result.get("winner")==0,"headquarters victory")
 s=Sim.new()
 s.units.filter(func(u):return u.team==0).map(func(u):u.hp=0)
 s.tick()
 check(s.result.get("winner")==1,"army defeat")
 var path="user://test-campaign.json"
 DirAccess.remove_absolute(path)
 var outcome={"winner":0,"reason":"test","seconds":1}
 check(Campaign.save_result(outcome,"test-1",path)==OK,"persistent write")
 Campaign.save_result(outcome,"test-1",path)
 var data=Campaign.load_record(path)
 check(data.wins==1 and data.territory=="Aster","reload and duplicate idempotency")
 DirAccess.remove_absolute(path)
 # Verified siege plan: heavy tanks screen long-range howitzer; scout distracts north.
 s=Sim.new(["custom","custom","scout","artillery"],{"chassis":"tracked","weapon":"cannon","armor":"heavy"})
 for u in s.units:
  if u.team==0:
   s.command([u.id],Vector2(82,32.5) if u.type=="tank" else Vector2(68,32.5) if u.type=="artillery" else Vector2(50,13))
 for frame in 10801:
  if not s.result.is_empty():break
  s.tick()
 check(s.result.get("winner")==0 and s.result.get("reason")=="HQ destroyed","heavy armor siege is viable against AI")
 # Measure full 60-second simulations; no render, GPU or phone claims.
 var samples=[]
 for run in 10:
  s=Sim.new()
  var start=Time.get_ticks_usec()
  for frame in 1800: s.tick()
  samples.append((Time.get_ticks_usec()-start)/1800.0/1000.0)
 samples.sort()
 print("BENCHMARK: median=%.4f ms/step; max=%.4f ms/step; 10 units; headless host only" % [samples[5],samples[9]])
 check(samples[9]<2.0,"host simulation below 2 ms/step")
 print("TOTAL: %d checks passed; %d failed" % [count,failures])
 quit(1 if failures else 0)
