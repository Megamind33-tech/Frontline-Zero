extends SceneTree
func mat(c: Color) -> StandardMaterial3D:
 var m=StandardMaterial3D.new()
 m.albedo_color=c
 m.roughness=0.9
 return m
func box(root: Node3D, name_: String, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
 var n=MeshInstance3D.new()
 n.name=name_
 var mesh=BoxMesh.new()
 mesh.size=size
 n.mesh=mesh
 n.material_override=mat(color)
 root.add_child(n)
 n.owner=root
 n.position=at
 return n
func _initialize():
 for role in ["scout","tank","artillery"]:
  var root=Node3D.new()
  root.name=role.capitalize()
  var olive=Color("63764a")
  box(root,"LowerHull",Vector3(0,0.65,0),Vector3(1.8,0.6,3.1),olive)
  box(root,"Glacis",Vector3(0,0.94,-1),Vector3(1.7,0.3,0.8),olive).rotation_degrees.x=-15
  if role!="scout":
   for side in [-1,1]:
    box(root,"Track"+str(side),Vector3(side,0.4,0),Vector3(0.45,0.7,3.5),Color("252d26"))
  for side in [-1,1]:
   for i in (2 if role=="scout" else 5):
    var wheel=MeshInstance3D.new()
    wheel.name="Wheel_%s_%s" % [side,i]
    var mesh=CylinderMesh.new()
    mesh.top_radius=0.42 if role=="scout" else 0.28
    mesh.bottom_radius=mesh.top_radius
    mesh.height=0.25 if role=="scout" else 0.48
    mesh.radial_segments=12
    wheel.mesh=mesh
    wheel.material_override=mat(Color("1d251f"))
    root.add_child(wheel)
    wheel.owner=root
    wheel.rotation.z=PI/2
    wheel.position=Vector3(side*1.03,0.43,-1.1+i*(2.2 if role=="scout" else 0.55))
  box(root,"Turret",Vector3(0,1.2,0.1),Vector3(1.25,0.6,1.3),olive)
  box(root,"Hatch",Vector3(0,1.55,0.25),Vector3(0.5,0.1,0.6),Color("46513c"))
  var length_=2.7 if role=="artillery" else 1.8 if role=="tank" else 1.2
  var barrel=box(root,"Barrel",Vector3(0,1.32,-length_/2),Vector3(0.16,0.16,length_),Color("303b30"))
  box(root,"Vision",Vector3(0,1.4,-0.57),Vector3(0.7,0.14,0.04),Color("152f32"))
  var ap=AnimationPlayer.new()
  ap.name="AnimationPlayer"
  root.add_child(ap)
  ap.owner=root
  var lib=AnimationLibrary.new()
  var recoil=Animation.new()
  recoil.length=0.35
  var track=recoil.add_track(Animation.TYPE_VALUE)
  recoil.track_set_path(track,NodePath("Barrel:position:z"))
  recoil.track_insert_key(track,0.0,barrel.position.z)
  recoil.track_insert_key(track,0.08,barrel.position.z+0.25)
  recoil.track_insert_key(track,0.35,barrel.position.z)
  lib.add_animation("fire",recoil)
  ap.add_animation_library("",lib)
  var scene=PackedScene.new()
  scene.pack(root)
  var err=ResourceSaver.save(scene,"res://assets/"+role+".tscn")
  if err!=OK:
   push_error("Asset generation failed: "+error_string(err))
   quit(1)
   return
  root.free()
  print("GENERATED: ",role," with fire animation")
 quit(0)
