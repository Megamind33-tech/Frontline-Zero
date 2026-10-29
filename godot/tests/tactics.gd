extends SceneTree
const Sim=preload("res://src/simulation.gd")
func _initialize():
 var failures=0
 for strategy in ["territory","siege"]:
  var s=Sim.new(["tank","tank","scout","scout","artillery"] if strategy=="territory" else ["custom","custom","scout","artillery"], {"chassis":"tracked","weapon":"cannon","armor":"heavy"})
  var scout_index=0
  for u in s.units:
   if u.team!=0:continue
   var target=Vector2(27,32.5)
   if strategy=="territory":
    if u.type=="scout":
     target=s.points[scout_index].pos
     scout_index+=1
    elif u.type=="tank":target=Vector2(45,16 if u.id==1 else 49)
    else:target=Vector2(43,32.5)
   else:target=Vector2(82,32.5) if u.type=="tank" else Vector2(68,32.5) if u.type=="artillery" else Vector2(50,13)
   s.command([u.id],target)
  for frame in 10801:
   if not s.result.is_empty():break
   s.tick()
  print("TACTIC ",strategy,": ",JSON.stringify(s.result)," score=",s.score," HQ=",s.hq[0].hp,"/",s.hq[1].hp)
  if s.result.get("winner",-1)!=0:failures+=1
 quit(1 if failures else 0)
