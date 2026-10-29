extends SceneTree
const Sim = preload("res://src/simulation.gd")
var count=0
var failures=0
func check(condition: bool, label: String):
 if not condition:
  push_error("FAIL: "+label)
  failures+=1
  return
 count+=1
 print("PASS: "+label)
func ticks(s: Sim, n: int):
 for _i in n:
  if not s.result.is_empty():return
  s.tick()
func _initialize():
 var s=Sim.new()
 check(s.supply[0]==0 and s.buildings.is_empty() and not s.construct(0),"factory purchase waits for supply")
 check(s.warning.begins_with("Need"),"low supply explains the rejected factory")
 s.supply[0]=Sim.FACTORY_COST
 check(s.construct(0) and s.supply[0]==0 and s.buildings.size()==1 and not s.buildings[0].complete,"command post spends supply to start a factory")
 check(not s.construct(0),"a second factory is rejected")
 ticks(s,int(Sim.FACTORY_SECONDS/Sim.STEP))
 check(s.buildings[0].complete,"factory construction finishes from elapsed battle time")
 var before=s.units.size()
 check(not s.enqueue(0,"tank"),"production waits until supply covers the vehicle")
 s.supply[0]=Sim.blueprint(Sim.PRESETS.tank).cost
 check(s.enqueue(0,"tank") and s.buildings[0].queue.size()==1,"tank enters the factory queue")
 check(not s.enqueue(0,"helicopter") and s.buildings[0].queue.size()==1,"unknown production is ignored")
 ticks(s,int(Sim.PRODUCE_SECONDS.tank/Sim.STEP)+1)
 check(s.units.size()==before+1 and s.units[-1].team==0 and s.units[-1].type=="tank" and not s.units[-1].get("roster",false),"finished queue spawns a replacement tank")
 s=Sim.new()
 s.points[0].owner=0
 var supply_before=s.supply[0]
 s.tick()
 check(s.supply[0]>supply_before+Sim.INCOME_HQ*Sim.STEP,"an owned relay adds supply income")
 s=Sim.new()
 ticks(s,1800)
 check(s.units.size()==10,"opening minute does not reinforce either army")
 var scout=s.units.filter(func(u):return u.team==1 and u.type=="scout")[0]
 check(scout.order.pos==s.points[scout.id%2].pos,"original enemy scouts keep the verified relay order")
 s=Sim.new()
 s.supply[0]=1000
 s.construct(0)
 s.buildings[0].complete=true
 s.enqueue(0,"scout")
 for u in s.units:
  if u.team==0:u.hp=0
 s.tick()
 check(s.result.is_empty(),"a queued factory keeps the battle open after the field force is lost")
 s.buildings[0].queue.clear()
 s.buildings[0].hp=0
 s.tick()
 check(s.result.get("winner")==1 and s.result.get("reason")=="army eliminated","elimination returns when nothing can be rebuilt")
 s=Sim.new()
 s.supply[1]=Sim.FACTORY_COST
 for u in s.units:u.damage=0
 s.tick()
 check(s.building_for(1).get("team",-1)==1,"enemy AI starts a factory when it can pay")
 var yard=s.building_for(1)
 yard.complete=true
 yard.queue.clear()
 s.supply[1]=1000
 for u in s.units:
  if u.team==0 and u.type=="tank":u.pos=s.hq[1].pos+Vector2(-10,0)
 s.tick()
 var produced=s.units.size()
 ticks(s,int(Sim.PRODUCE_SECONDS.scout/Sim.STEP)+2)
 check(s.units.size()>produced,"enemy production answers the units the player has fielded")
 var reinforcement=s.units[-1]
 check(reinforcement.team==1 and reinforcement.order.pos.distance_to(s.hq[1].pos)<20,"the new vehicle defends the threatened headquarters")
 s=Sim.new()
 for u in s.units:
  if u.team==0:u.hp=0
 s.tick()
 check(s.result.get("reason")=="army eliminated","a force with no factory is still eliminated")
 print("TOTAL: %d production checks, %d failed" % [count,failures])
 quit(1 if failures else 0)
