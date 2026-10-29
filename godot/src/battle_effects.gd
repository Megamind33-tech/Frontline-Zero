extends Node3D
const Field=preload("res://src/battlefield.gd")
const LIMIT=64
var items: Array=[]
var shells: Array=[]
var sphere=SphereMesh.new()
var ring=TorusMesh.new()
var line_mesh=ImmediateMesh.new()
var line_node: MeshInstance3D
var emitted=0
func _ready():
 sphere.radius=.5;sphere.height=1;sphere.radial_segments=8;sphere.rings=4
 ring.inner_radius=.75;ring.outer_radius=1;ring.rings=16;ring.ring_segments=4
 line_node=MeshInstance3D.new();line_node.mesh=line_mesh
 var m=StandardMaterial3D.new();m.albedo_color=Color("ffe5a2");m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 line_node.material_override=m
 add_child(line_node)
func puff(pos: Vector3, color: Color, size_: float, life: float, kind: String = "blast"):
 if items.size()>=LIMIT:return
 var n=MeshInstance3D.new();n.mesh=ring if kind=="ring" else sphere
 var m=StandardMaterial3D.new();m.albedo_color=color;m.roughness=.95
 m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
 if kind!="smoke":m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 n.material_override=m;n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 add_child(n);n.position=pos;n.scale=Vector3.ONE*.1
 items.append({"node":n,"age":0.,"life":life,"size":size_,"kind":kind,"alpha":color.a})
func shot(event: Dictionary, role: String):
 if shells.size()>=LIMIT:return
 var start=Field.ground(event.from,1.5)
 var end=Field.ground(event.to,.8)
 shells.append({"from":start,"to":end,"age":0.,"life":.32 if role=="artillery" else .14,"role":role})
 puff(start,Color(1,.82,.32,.95),.9,.10)
 emitted+=1
func impact(at: Vector3, artillery: bool = false):
 var strength=1.6 if artillery else 1.
 puff(at,Color(1,.67,.20,.92),1.9*strength,.24)
 puff(at+Vector3(0,.2,0),Color(.36,.31,.24,.74),2.1*strength,1.1,"smoke")
 puff(at-Vector3(0,.6,0),Color(.55,.45,.27,.42),2.4*strength,.4,"ring")
func destroyed(at: Vector3):
 puff(at+Vector3.UP,Color(1,.52,.12,.95),3.5,.45)
 puff(at+Vector3(0,1.5,0),Color(.13,.15,.13,.90),4,3.4,"smoke")
func _process(dt):
 line_mesh.clear_surfaces()
 if not shells.is_empty():
  line_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
  for shell in shells:
   shell.age+=dt
   var t=clampf(shell.age/shell.life,0,1)
   var p: Vector3=shell.from.lerp(shell.to,t)
   if shell.role=="artillery":p.y+=sin(t*PI)*4
   line_mesh.surface_add_vertex(p)
   line_mesh.surface_add_vertex(p+(shell.from-shell.to).normalized()*.9)
   if t>=1:impact(shell.to,shell.role=="artillery")
  line_mesh.surface_end()
 shells=shells.filter(func(s):return s.age<s.life)
 for item in items:
  item.age+=dt
  var t: float=clampf(item.age/item.life,0,1)
  item.node.scale=Vector3.ONE*maxf(.05,item.size*sqrt(t))
  if item.kind=="smoke":item.node.position.y+=dt*.7
  item.node.material_override.albedo_color.a=item.alpha*(1.-t)
  if t>=1:item.node.queue_free()
 items=items.filter(func(p):return p.age<p.life)
