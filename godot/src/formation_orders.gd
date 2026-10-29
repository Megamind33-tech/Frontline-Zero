extends RefCounted
## Adapter from the existing horizontal simulation to MIT XZ formation helpers.
const Formation = preload("res://third_party/rts_advanced/rts_formation.gd")
const SPACING = 3.8 # Longest current vehicle is 3.5 m; reserve clearance.
const MIN = Vector2(1.5, 1.5)
const MAX = Vector2(98.5, 63.5)

static func destinations(positions: Array[Vector2], target: Vector2, shape: String = "box") -> Array[Vector2]:
 var result: Array[Vector2] = []
 if positions.is_empty() or not target.is_finite():
  return result
 target = target.clamp(MIN, MAX)
 if positions.size() == 1:
  return [target]
 var center = Vector3.ZERO
 var source: Array[Vector3] = []
 for p in positions:
  var p3 = Vector3(p.x, 0, p.y)
  source.append(p3)
  center += p3
 center /= positions.size()
 var end = Vector3(target.x, 0, target.y)
 var slots: Array[Vector3] = Formation.line(center, end, positions.size(), SPACING) if shape == "line" else Formation.box(center, end, positions.size(), SPACING)
 # Translate the whole shape at edges; clamping each slot collapses spacing.
 var lo = Vector2(INF, INF)
 var hi = Vector2(-INF, -INF)
 for p in slots:
  lo = lo.min(Vector2(p.x, p.z))
  hi = hi.max(Vector2(p.x, p.z))
 var shift = Vector2(maxf(0, MIN.x-lo.x)-maxf(0, hi.x-MAX.x), maxf(0, MIN.y-lo.y)-maxf(0, hi.y-MAX.y))
 for i in slots.size():
  slots[i] += Vector3(shift.x, 0, shift.y)
 var assignment: Array[int] = Formation.assign(source, slots)
 for index in assignment:
  var p = slots[index]
  result.append(Vector2(p.x, p.z))
 return result
