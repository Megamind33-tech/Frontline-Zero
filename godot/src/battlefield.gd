extends RefCounted
## Original woodland-road art using shared materials and MultiMesh vegetation.
const COVER = [Rect2(39,7.5,22,11.5), Rect2(39,46.5,22,11.5)]
static var materials: Dictionary = {}

static func height_at(p: Vector2) -> float:
 # Broad shoulders and low ridges; the road/relay approach remains navigable.
 var ridge = 2.8*exp(-pow((p.y-3.0)/7.0,2.0))+2.3*exp(-pow((p.y-62.0)/8.0,2.0))
 return ridge + 0.22*sin(p.x*.16)*sin(p.y*.24) + 0.12*cos(p.x*.33+p.y*.19)

static func mat(key: String, color: Color, roughness: float = .9) -> StandardMaterial3D:
 if materials.has(key): return materials[key]
 var m=StandardMaterial3D.new()
 m.albedo_color=color
 m.roughness=roughness
 materials[key]=m
 return m

static func mesh_node(parent: Node3D, mesh: Mesh, material: Material, pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
 var n=MeshInstance3D.new()
 n.mesh=mesh
 n.material_override=material
 parent.add_child(n)
 n.position=pos
 return n

static func ground(p: Vector2, offset: float = 0.0) -> Vector3:
 return Vector3(p.x,height_at(p)+offset,p.y)

static func terrain(root: Node3D):
 var st=SurfaceTool.new()
 st.begin(Mesh.PRIMITIVE_TRIANGLES)
 var noise=FastNoiseLite.new()
 noise.seed=2718
 noise.frequency=.13
 for z in range(-12,78,2):
  for x in range(-15,116,2):
   for v in [Vector2(x,z),Vector2(x+2,z),Vector2(x,z+2),Vector2(x+2,z),Vector2(x+2,z+2),Vector2(x,z+2)]:
    var n=noise.get_noise_2d(v.x,v.y)
    var base=Color("50573a").lerp(Color("717358"),(n+1)*.5)
    if COVER.any(func(r):return r.has_point(v)): base=base.darkened(.22)
    st.set_color(base)
    st.set_uv(v*.35)
    st.add_vertex(ground(v))
 st.generate_normals()
 st.index()
 var m=ShaderMaterial.new()
 m.shader=load("res://src/terrain.gdshader")
 m.set_shader_parameter("ground_texture",load("res://assets/battle/woodland-ground.png"))
 var n=mesh_node(root,st.commit(),m)
 n.name="ElevatedTerrain"

static func pine_mesh() -> ArrayMesh:
 # Layered 3D branch cards use the drawn alpha foliage, not solid cone placeholders.
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 for layer in 3:
  var y=1.0+layer*1.05
  var width=2.9-layer*.65
  for turn in 2:
   var angle=turn*PI/2+layer*.43
   var right=Vector3(cos(angle),0,sin(angle))*width*.5
   var base=Vector3(0,y,0)
   var top=Vector3(0,y+1.7,0)
   var verts=[base-right,base+right,top-right,top-right,base+right,top+right]
   var uvs=[Vector2(0,1),Vector2(1,1),Vector2(0,0),Vector2(0,0),Vector2(1,1),Vector2(1,0)]
   for i in 6:
    st.set_uv(uvs[i]);st.add_vertex(verts[i])
 st.generate_normals()
 return st.commit()

static func instances(root: Node3D, mesh: Mesh, material: Material, transforms: Array[Transform3D], label: String):
 var batch=MultiMeshInstance3D.new()
 batch.name=label
 batch.multimesh=MultiMesh.new()
 batch.multimesh.transform_format=MultiMesh.TRANSFORM_3D
 batch.multimesh.mesh=mesh
 batch.multimesh.instance_count=transforms.size()
 for i in transforms.size():batch.multimesh.set_instance_transform(i,transforms[i])
 batch.material_override=material
 # Thin foliage cards use the woodland ambient ground shade; retain vehicle/HQ shadows.
 if label=="InstancedPineCanopies":batch.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 root.add_child(batch)
 # Broad automatic visibility fades whole scenery batches, independent of units.
 batch.visibility_range_end=180

static func vegetation(root: Node3D):
 var rng=RandomNumberGenerator.new();rng.seed=20261029
 var trees: Array[Transform3D]=[]
 var trunks: Array[Transform3D]=[]
 for i in 160:
  var p: Vector2
  if i<88:
   var rect=COVER[i%2]
   p=rect.position+Vector2(rng.randf_range(.3,rect.size.x-.3),rng.randf_range(.3,rect.size.y-.3))
   # Leave actual lanes through the wooded capture areas.
   if absf(p.x-50)<2.3:continue
  else:
   p=Vector2(rng.randf_range(-9,109),rng.randf_range(-7,72))
   if p.y>5 and p.y<60:continue
  var scale_=rng.randf_range(.7,1.25)
  var basis=Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*scale_)
  trees.append(Transform3D(basis,ground(p)))
  trunks.append(Transform3D(basis,ground(p,.95*scale_)))
 var leaf=mat("pine",Color("b2bd99"));leaf.cull_mode=BaseMaterial3D.CULL_DISABLED
 leaf.albedo_texture=load("res://assets/battle/pine-foliage.png")
 leaf.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
 leaf.alpha_scissor_threshold=.45
 instances(root,pine_mesh(),leaf,trees,"InstancedPineCanopies")
 var trunk=CylinderMesh.new();trunk.top_radius=.09;trunk.bottom_radius=.17;trunk.height=1.9;trunk.radial_segments=6
 instances(root,trunk,mat("bark",Color("514836")),trunks,"InstancedPineTrunks")
 # Small rock outcrops on shoulders, away from the drivable lanes.
 var rocks: Array[Transform3D]=[]
 for i in 35:
  var p=Vector2(rng.randf_range(1,99),rng.randf_range(0,65))
  if p.y>8 and p.y<57:continue
  rocks.append(Transform3D(Basis.from_euler(Vector3(rng.randf(),rng.randf()*TAU,rng.randf())).scaled(Vector3(rng.randf_range(.7,2),rng.randf_range(.5,1.2),rng.randf_range(.7,1.7))),ground(p,.1)))
 var rock=PrismMesh.new();rock.size=Vector3(1,1,1);rock.left_to_right=.3
 instances(root,rock,mat("rock",Color("65675b")),rocks,"InstancedRockOutcrops")

static func cylinder(root: Node3D, at: Vector3, radius: float, depth: float, m: Material, top: float = -1.0) -> MeshInstance3D:
 var c=CylinderMesh.new();c.bottom_radius=radius;c.top_radius=radius if top<0 else top;c.height=depth;c.radial_segments=16
 return mesh_node(root,c,m,at)

static func relay(root: Node3D, pos: Vector2) -> MeshInstance3D:
 var at=ground(pos)
 cylinder(root,at+Vector3(0,.2,0),1.6,.4,mat("concrete",Color("838275")))
 cylinder(root,at+Vector3(0,2.5,0),.08,5,mat("metal",Color("a2a99b")))
 var beacon=cylinder(root,at+Vector3(0,5.1,0),.24,.5,mat("neutral",Color("d3c891")))
 var dish=SphereMesh.new();dish.radius=.8;dish.height=.23;dish.radial_segments=16;dish.rings=6
 mesh_node(root,dish,mat("dish",Color("b0b4a0")),at+Vector3(.5,4.1,0)).rotation_degrees.z=-35
 var ring=TorusMesh.new();ring.inner_radius=6.25;ring.outer_radius=6.45;ring.rings=32;ring.ring_segments=4
 var ringmat=mat("capture perimeter",Color(.71,.72,.48,.7));ringmat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 mesh_node(root,ring,ringmat,at+Vector3(0,.13,0))
 return beacon

static func hq(root: Node3D, pos: Vector2, team: int) -> MeshInstance3D:
 var at=ground(pos)
 var model=load("res://assets/battle/command-post.glb").instantiate()
 root.add_child(model)
 model.position=at
 var bunker: MeshInstance3D=model.find_child("FortifiedCommandPost",true,false)
 bunker.material_override=mat("baked structure",Color.WHITE)
 bunker.material_override.vertex_color_use_as_albedo=true
 var faction=mat("hq faction "+str(team),Color("b6c886") if team==0 else Color("b36c4a"))
 cylinder(root,at+Vector3(.5,2.4,0),.18,.3,faction)
 return bunker

static func build(root: Node3D):
 terrain(root)
 vegetation(root)
