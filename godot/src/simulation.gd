extends RefCounted
const FormationOrders = preload("res://src/formation_orders.gd")
## Deterministic battle model. Coordinates are horizontal world meters.
const ENEMY_HQ = -2
const FRIENDLY_HQ = -3
const MAX_ORDERS = 16 # Includes the active order; group appends are atomic.
const STEP = 1.0 / 30.0
const PRESETS = {
 "scout": {"chassis":"wheeled", "weapon":"autocannon", "armor":"light"},
 "tank": {"chassis":"tracked", "weapon":"cannon", "armor":"light"},
 "artillery": {"chassis":"tracked", "weapon":"howitzer", "armor":"light"}}
const CHASSIS = {"wheeled":{"hp":90.0,"speed":10.5,"capacity":5,"cost":40}, "tracked":{"hp":240.0,"speed":5.2,"capacity":10,"cost":90}}
const WEAPONS = {"autocannon":{"weight":2,"damage":13.0,"range":13.0,"reload":0.55,"cost":25}, "cannon":{"weight":4,"damage":48.0,"range":17.0,"reload":1.8,"cost":40}, "howitzer":{"weight":6,"damage":95.0,"range":29.0,"reload":3.4,"cost":65}}
const ARMOR = {"light":{"weight":1,"hp":0.0,"speed":1.0,"cost":5}, "heavy":{"weight":4,"hp":140.0,"speed":0.72,"cost":30}}
var units: Array = []
var points: Array = [{"pos":Vector2(50,13),"progress":0.0,"owner":-1},{"pos":Vector2(50,52),"progress":0.0,"owner":-1}]
var hq: Array = [{"pos":Vector2(6.5,32.5),"hp":1600.0,"team":0},{"pos":Vector2(93.5,32.5),"hp":1600.0,"team":1}]
var score: Array = [0.0,0.0]
var time = 0.0
var result: Dictionary = {}
var shots: Array = []
var error = ""
const MATCH_SECONDS = 900.0
const FACTORY_COST = 220.0
const FACTORY_SECONDS = 20.0
const FACTORY_HP = 900.0
const SUPPLY_CAP = 800.0
const UNIT_CAP = 12
const QUEUE_CAP = 4
const INCOME_HQ = 4.0
const INCOME_RELAY = 6.0
const PADS = [Vector2(16, 48), Vector2(84, 48)]
const PRODUCE_SECONDS = {"scout": 12.0, "tank": 22.0, "artillery": 28.0}
var supply: Array = [0.0, 0.0]
var buildings: Array = []
var warning = ""

static func blueprint(b: Dictionary) -> Dictionary:
 if not CHASSIS.has(b.get("chassis")) or not WEAPONS.has(b.get("weapon")) or not ARMOR.has(b.get("armor")):
  return {"error":"Unknown module"}
 var c: Dictionary = CHASSIS[b.chassis]
 var w: Dictionary = WEAPONS[b.weapon]
 var a: Dictionary = ARMOR[b.armor]
 if w.weight + a.weight > c.capacity:
  return {"error":"Payload exceeds chassis capacity"}
 return {"chassis":b.chassis,"weapon":b.weapon,"armor":b.armor,"type":"artillery" if b.weapon == "howitzer" else "scout" if b.chassis == "wheeled" else "tank", "hp":c.hp+a.hp,"speed":c.speed*a.speed,"damage":w.damage,"range":w.range,"min_range":8.0 if b.weapon == "howitzer" else 0.0,"reload":w.reload,"cost":c.cost+w.cost+a.cost}

func _init(loadout: Array = ["tank","tank","scout","scout","artillery"], custom: Dictionary = PRESETS.tank):
 var builds: Array = []
 var cost = 0
 if loadout.is_empty() or loadout.size() > 12:
  error = "Choose 1–12 units"
  return
 for role in loadout:
  var b = blueprint(custom if role == "custom" else PRESETS.get(role, {}))
  if b.has("error"):
   error = b.error
   return
  builds.append(b)
  cost += b.cost
 if cost > 600:
  error = "Deployment budget exceeded"
  return
 for i in builds.size():
  spawn(0, builds[i], Vector2(13, 17.5+i*6.5))
 var enemy = ["tank","tank","scout","scout","artillery"]
 for i in enemy.size():
  spawn(1, blueprint(PRESETS[enemy[i]]), Vector2(87, 17.5+i*6.5))
 for u in units:
  if u.team == 1:
   u.roster = true

func spawn(team: int, b: Dictionary, pos: Vector2):
 var u = b.duplicate(true)
 u.merge({"id":units.size()+1,"team":team,"pos":pos,"max_hp":b.hp,"cooldown":0.0,"order":{},"queue":[],"domain":"ground","direct":Vector2.ZERO})
 units.append(u)

func command(ids: Array, pos: Vector2, target_id: int = -1, formation: String = "box", queued: bool = false) -> bool:
 if not pos.is_finite() or not result.is_empty() or not error.is_empty() or pos.x<1.5 or pos.x>98.5 or pos.y<1.5 or pos.y>63.5:
  return false
 var focus=attack_target(target_id)
 if target_id!=-1:
  if focus.is_empty():return false
  pos=focus.pos
 var group: Array = []
 var positions: Array[Vector2] = []
 for u in units:
  if u.team == 0 and u.hp > 0 and ids.has(u.id):
   if u.get("domain","ground")!="ground":return false
   if queued and u.queue.size() + (0 if u.order.is_empty() else 1) >= MAX_ORDERS:
    return false
   group.append(u)
   # Plan each leg from the preceding destination, not the current position.
   positions.append(u.queue[-1].pos if queued and not u.queue.is_empty() else u.order.pos if queued and not u.order.is_empty() else u.pos)
 if group.is_empty():
  return false
 var destinations = FormationOrders.destinations(positions, pos, formation)
 for i in group.size():
  var u = group[i]
  var origin: Vector2=positions[i]
  var outward: Vector2=pos.direction_to(origin)
  if outward==Vector2.ZERO:outward=Vector2.LEFT
  var order = {"pos":destinations[i],"target_id":target_id,"approach":outward,"offset":destinations[i]-pos}
  if queued and not u.order.is_empty():
   u.queue.append(order)
  else:
   u.order = order
   u.queue.clear()
  u.direct = Vector2.ZERO
 return true

func hold(ids: Array):
 for u in units:
  if u.team == 0 and u.hp > 0 and ids.has(u.id):
   u.order = {}
   u.queue.clear()
   u.direct = Vector2.ZERO

func direct_control(id: int, direction: Vector2):
 if not direction.is_finite(): return
 for u in units:
  if u.id == id and u.team == 0 and u.hp > 0 and u.get("domain","ground")=="ground":
   if direction != Vector2.ZERO:
    hold([id])
   u.direct = direction.limit_length()

func advance_order(u: Dictionary):
 if u.order.is_empty(): return
 var target_id: int = u.order.get("target_id", -1)
 var complete: bool = u.pos.distance_to(u.order.pos) <= 0.5 if target_id == -1 else attack_target(target_id).is_empty()
 if complete:
  u.order = {} if u.queue.is_empty() else u.queue.pop_front()

func attack_target(id: int) -> Dictionary:
 if id==ENEMY_HQ:return hq[1] if hq[1].hp>0 else {}
 for b in buildings:
  if b.id==id and b.team==1 and b.hp>0 and b.complete:return b
 for u in units:
  if u.id==id and u.team==1 and u.hp>0:return u
 return {}

func building_for(team: int) -> Dictionary:
 for b in buildings:
  if b.team==team and b.hp>0:return b
 return {}

func living_count(team: int) -> int:
 var n=0
 for u in units:
  if u.team==team and u.hp>0:n+=1
 return n

func reinforcing(team: int) -> bool:
 var b=building_for(team)
 return not b.is_empty() and (not b.complete or not b.queue.is_empty())

func construct(team: int) -> bool:
 if team<0 or team>1 or not result.is_empty() or not error.is_empty() or hq[team].hp<=0:
  return false
 if not building_for(team).is_empty():
  if team==0:warning="Vehicle factory already built"
  return false
 if supply[team]<FACTORY_COST:
  if team==0:warning="Need %d supply for a vehicle factory" % int(FACTORY_COST)
  return false
 supply[team]-=FACTORY_COST
 buildings.append({"id":-20-team,"team":team,"kind":"factory","pos":PADS[team],"hp":FACTORY_HP,"max_hp":FACTORY_HP,"progress":0.0,"complete":false,"queue":[]})
 if team==0:warning="Vehicle factory under construction"
 return true

func enqueue(team: int, role: String) -> bool:
 if not PRODUCE_SECONDS.has(role) or not result.is_empty() or not error.is_empty():return false
 var b=building_for(team)
 if b.is_empty() or not b.complete:
  if team==0:warning="Vehicle factory is not ready"
  return false
 if living_count(team)+b.queue.size()>=UNIT_CAP or b.queue.size()>=QUEUE_CAP:
  if team==0:warning="Production queue is full"
  return false
 var cost=float(blueprint(PRESETS[role]).cost)
 if supply[team]<cost:
  if team==0:warning="Need %d supply to build a %s" % [int(cost), role]
  return false
 supply[team]-=cost
 b.queue.append({"role":role,"remaining":PRODUCE_SECONDS[role]})
 if team==0:warning="%s queued" % role.capitalize()
 return true

func logistics(dt: float):
 for team in 2:
  if hq[team].hp<=0:continue
  var rate=INCOME_HQ
  for p in points:
   if p.owner==team:rate+=INCOME_RELAY
  supply[team]=minf(SUPPLY_CAP, supply[team]+rate*dt)
 for b in buildings:
  if b.hp<=0:continue
  if not b.complete:
   b.progress+=dt
   if b.progress>=FACTORY_SECONDS:
    b.complete=true
    b.progress=FACTORY_SECONDS
   continue
  if b.queue.is_empty():continue
  b.queue[0].remaining-=dt
  if b.queue[0].remaining>0:continue
  var role: String=b.queue[0].role
  b.queue.pop_front()
  if living_count(b.team)>=UNIT_CAP:continue
  var slide=Vector2(0, 7 if b.team==0 else -7)
  spawn(b.team, blueprint(PRESETS[role]), (b.pos+slide).clamp(Vector2(1.5,1.5),Vector2(98.5,63.5)))
 if hq[1].hp<=0:return
 var yard=building_for(1)
 if yard.is_empty():
  if supply[1]>=FACTORY_COST:construct(1)
  return
 if not yard.complete or living_count(1)+yard.queue.size()>=8 or yard.queue.size()>=2:return
 var tanks=0
 var guns=0
 for u in units:
  if u.team!=0 or u.hp<=0:continue
  if u.type=="tank":tanks+=1
  elif u.type=="artillery":guns+=1
 var role="artillery" if tanks>=3 else "scout" if guns>=1 else "tank"
 enqueue(1, role)

func steer_attack(u: Dictionary):
 if u.order.is_empty() or u.order.get("target_id",-1)==-1:return
 var target=attack_target(u.order.target_id)
 if target.is_empty():return
 var distance: float=u.pos.distance_to(target.pos)
 var outward: Vector2=target.pos.direction_to(u.pos)
 if outward==Vector2.ZERO:outward=u.order.get("approach",Vector2.LEFT)
 if distance<u.min_range+.6:
  u.order.pos=(target.pos+outward*(u.min_range+1.2)).clamp(Vector2(1.5,1.5),Vector2(98.5,63.5))
 elif distance>u.range-.6:
  var desired=maxf(u.min_range+1.2,u.range*.85)
  var offset: Vector2=u.order.get("offset",Vector2.ZERO)
  var relative: Vector2=(u.order.get("approach",outward)*desired+offset).limit_length(u.range-.8)
  u.order.pos=(target.pos+relative).clamp(Vector2(1.5,1.5),Vector2(98.5,63.5))
 else:u.order.pos=u.pos

static func cover(pos: Vector2) -> bool:
 return Rect2(39,7.5,22,11.5).has_point(pos) or Rect2(39,46.5,22,11.5).has_point(pos)

func tick(dt: float = STEP):
 if not result.is_empty() or not error.is_empty():
  return
 assert(dt > 0 and dt <= 0.1)
 time += dt
 logistics(dt)
 shots.clear()
 for u in units:
  if u.hp <= 0:
   continue
  if u.team == 0:
   advance_order(u)
   steer_attack(u)
  u.cooldown = maxf(0, u.cooldown-dt)
  if u.team == 1 and u.get("roster", false):
   u.order = {"pos":points[u.id%2].pos if u.type == "scout" else Vector2(15,24+(u.id%3)*8), "target_id":-1}
  elif u.team == 1:
   var threat=false
   for friendly in units:
    if friendly.team==0 and friendly.hp>0 and friendly.pos.distance_to(hq[1].pos)<22:threat=true;break
   var rally=hq[1].pos+Vector2(-8,(u.id%5-2)*2.5) if threat else Vector2(30,32.5)
   u.order={"pos":rally.clamp(Vector2(1.5,1.5),Vector2(98.5,63.5)),"target_id":-1}
  var target: Dictionary = {}
  var nearest = INF
  var explicit_focus=false
  # Explicit living hostile target first, then nearest hostile in range, then HQ.
  if u.team==0:
   var focused=attack_target(u.order.get("target_id",-1))
   if not focused.is_empty():
    var focused_distance: float=u.pos.distance_to(focused.pos)
    if focused_distance<=u.range and focused_distance>=u.min_range:target=focused;explicit_focus=true
  for e in units:
   if explicit_focus:break
   if e.team == u.team or e.hp <= 0:
    continue
   var d: float = u.pos.distance_to(e.pos)
   if d <= u.range and d >= u.min_range and (d < nearest or e.id == u.order.get("target_id",-1)):
    target = e
    nearest = d
    if e.id == u.order.get("target_id",-1):
     break
  var enemy_hq: Dictionary = hq[1-u.team]
  var hd: float = u.pos.distance_to(enemy_hq.pos)
  if target.is_empty() and hd <= u.range and hd >= u.min_range:
   target = enemy_hq
  if not target.is_empty() and u.cooldown <= 0:
   target.hp -= u.damage*(0.6 if cover(target.pos) else 1.0)
   u.cooldown = u.reload
   shots.append({"from":u.pos,"to":target.pos,"team":u.team,"id":u.id,"target_id":target.get("id",ENEMY_HQ if u.team==0 else FRIENDLY_HQ)})
   if target==hq[0]:warning="Command post under fire"
   if target.get("kind","")=="factory" and target.hp<=0:
    target.queue.clear()
    if target.team==0:warning="Vehicle factory destroyed"
  var direction: Vector2 = u.direct
  if direction == Vector2.ZERO and not u.order.is_empty():
   var d: float = u.pos.distance_to(u.order.pos)
   if d > 0.5 and (target.is_empty() or u.team == 0 or u.order.get("target_id",-1) >= 0):
    direction = u.pos.direction_to(u.order.pos)
  if direction != Vector2.ZERO:
   var slow = 0.5 if Rect2(44,23.5,12,18).has_point(u.pos) else 1.0
   u.pos = (u.pos + direction.limit_length()*u.speed*slow*dt).clamp(Vector2(1.5,1.5),Vector2(98.5,63.5))
 for p in points:
  var near = [false,false]
  for u in units:
   if u.hp > 0 and u.pos.distance_to(p.pos) < 6.5:
    near[u.team] = true
  if near[0] != near[1]:
   p.progress = clampf(p.progress+(dt if near[0] else -dt),-6,6)
  if p.progress >= 6:
   p.owner = 0
  elif p.progress <= -6:
   p.owner = 1
  elif absf(p.progress) < 0.05:
   p.owner = -1
  if p.owner >= 0 and not near[1-p.owner]:
   score[p.owner] += dt
 for team in 2:
  var foe=1-team
  var living_enemy = units.any(func(u): return u.team == foe and u.hp > 0)
  if hq[foe].hp <= 0 or score[team] >= 120 or (not living_enemy and not reinforcing(foe)):
   result = {"winner":team,"reason":"HQ destroyed" if hq[foe].hp<=0 else "territory secured" if score[team]>=120 else "army eliminated", "seconds":roundi(time)}
   return
 if time >= MATCH_SECONDS:
  result = {"winner":-1 if score[0] == score[1] else 0 if score[0] > score[1] else 1,"reason":"time limit","seconds":int(MATCH_SECONDS)}
