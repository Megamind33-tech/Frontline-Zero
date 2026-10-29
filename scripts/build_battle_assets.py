"""Original bevelled military art. Blender 4.3+: --background --python FILE -- OUTPUT.
No third-party geometry/textures. Runtime GLBs keep named turret/recoil nodes.
"""
import bpy, math, pathlib, sys, json
from mathutils import Vector
out=pathlib.Path(sys.argv[sys.argv.index('--')+1]).resolve();out.mkdir(parents=True,exist_ok=True)
source=out.parents[2]/'.tools'/'battle-sources' if out.name=='battle' else out/'sources'
# Designer files stay outside res:// so Godot never invokes Blender implicitly.
source.mkdir(parents=True,exist_ok=True)
metrics={}

def material(name,color,metal=0.,rough=.7):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
 p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough
 return m

def finish(o,name,m,parent=None,bevel=0):
 o.name=name;o.data.materials.append(m)
 if bevel:
  mod=o.modifiers.new('Manufactured edges','BEVEL');mod.width=bevel;mod.segments=2
  bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
 if parent:o.parent=parent
 return o

def block(name,loc,scale,m,parent=None,bevel=.035):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.scale=scale;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 return finish(o,name,m,parent,bevel)

def cylinder(name,loc,radius,depth,m,parent=None,rotation=(0,0,0),vertices=16):
 bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=radius,depth=depth,location=loc,rotation=rotation)
 return finish(bpy.context.object,name,m,parent,.012)

def hull(name,rings,m,parent=None):
 # Each ring is a deliberate chamfered armor cross-section, not stacked cubes.
 verts=[]
 for z,w,front,rear in rings:
  verts += [(-w*.72,front,z),(w*.72,front,z),(w,front+.32,z),(w,rear-.22,z),(w*.75,rear,z),(-w*.75,rear,z),(-w,rear-.22,z),(-w,front+.32,z)]
 faces=[tuple(reversed(range(8)))]
 for j in range(len(rings)-1):
  for i in range(8):faces.append((j*8+i,j*8+(i+1)%8,(j+1)*8+(i+1)%8,(j+1)*8+i))
 faces.append(tuple(range((len(rings)-1)*8,len(rings)*8)))
 mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update();o=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(o);return finish(o,name,m,parent,.045)

def join_group(parent,name):
 # Bake small static details per articulated group. A handful of surfaces per unit.
 objects=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.parent==parent]
 if not objects:return
 bpy.ops.object.select_all(action='DESELECT')
 for o in objects:o.select_set(True)
 bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();objects[0].name=name
 mesh=objects[0].data
 # One vertex-colour surface per articulated group, not a pass for every material.
 colors=mesh.color_attributes.new(name='Paint',type='FLOAT_COLOR',domain='CORNER')
 vehicle=name in ['Chassis','TurretArmor','GunAssembly']
 for face in mesh.polygons:
  old=mesh.materials[face.material_index]
  tag=(1. if old.name.startswith('Armor') else .65 if old.name.startswith('Faction') else .4 if old.name.startswith('Track') else .2) if vehicle else 1.
  for loop in face.loop_indices:colors.data[loop].color=(*old.diffuse_color[:3],tag)
  face.material_index=0
 mesh.materials.clear()
 batch=material('VehicleBatch' if vehicle else 'StructureBatch',(1.,1.,1.))
 attribute=batch.node_tree.nodes.new('ShaderNodeVertexColor');attribute.layer_name='Paint'
 batch.node_tree.links.new(attribute.outputs['Color'],batch.node_tree.nodes.get('Principled BSDF').inputs['Base Color'])
 mesh.materials.append(batch)
 mesh.color_attributes.active_color=colors

for role in ['tank','scout','artillery']:
 bpy.ops.wm.read_factory_settings(use_empty=True)
 armor=material('Armor • olive ceramic',(.24,.29,.18),.25,.63)
 panel=material('Armor • sand camouflage',(.40,.40,.28),.18,.75)
 steel=material('Gunmetal',(.065,.078,.072),.7,.4)
 track=material('Track rubber and manganese',(.037,.042,.033),.2,.9)
 glass=material('Optics',(.045,.19,.21),.45,.18)
 stripe=material('Faction identification',(.72,.78,.54),.2,.5)
 root=bpy.data.objects.new('Vehicle',None);bpy.context.collection.objects.link(root)
 wheeled=role=='scout'
 hull('Welded hull',[(.35,.73,-1.55,1.4),(.64,1.,-1.9,1.6),(1.07,.77,-1.35,1.35)],armor,root)
 hull('Engine deck',[(1.06,.70,.30,1.34),(1.22,.62,.42,1.24)],panel,root)
 if wheeled:
  for side in [-1,1]:
   for y in [-1.22,0,1.12]:
    cylinder('All terrain tire',(side*1.01,y,.48),.43,.32,track,root,(0,math.pi/2,0),20)
    cylinder('Armored wheel hub',(side*1.18,y,.48),.23,.03,steel,root,(0,math.pi/2,0))
    for a in range(12):
     angle=a*math.tau/12
     lug=block('Tire tread',(side*1.01,y+math.cos(angle)*.41,.48+math.sin(angle)*.41),(.34,.14,.075),track,root,.01);lug.rotation_euler.x=angle
 else:
  for side in [-1,1]:
   # Continuous rounded belt with individual tread shoes and recessed road wheels.
   for i in range(40):
    angle=math.tau*i/40
    y=math.cos(angle)*1.36;z=.47+math.sin(angle)*.37
    shoe=block('Tread shoe',(side*.99,y,z),(.46,.18,.075),track,root,.012);shoe.rotation_euler.x=angle
   for y in [-1.12,-.56,0,.56,1.12]:
    cylinder('Road wheel',(side*1.04,y,.45),.29,.35,steel,root,(0,math.pi/2,0),16)
    cylinder('Wheel inset',(side*1.23,y,.45),.17,.025,armor,root,(0,math.pi/2,0),12)
   block('Track side skirt',(side*1.03,0,.94),(.16,2.9,.30),panel,root,.04)
   for y in [-1,-.5,0,.5,1]:block('Skirt fastener',(side*1.12,y,.98),(.04,.10,.07),steel,root,.012)
 # Louvred engine radiator, headlights, tow points and stowed equipment.
 for x in [-.45,-.30,-.15,0,.15,.30,.45]:block('Radiator louvre',(x,.92,1.24),(.065,.45,.028),steel,root,.008)
 for side in [-1,1]:
  cylinder('Headlamp',(side*.64,-1.36,.99),.085,.08,glass,root,(math.pi/2,0,0),12)
  cylinder('Tow ring',(side*.55,-1.63,.66),.06,.10,steel,root,(math.pi/2,0,0),10)
  block('Stowage',(side*.65,.75,1.20),(.21,.50,.19),armor,root,.045)
 join_group(root,'Chassis')
 turret=bpy.data.objects.new('Turret',None);bpy.context.collection.objects.link(turret);turret.parent=root
 turret.location=(0,-.18,1.10)
 if role=='artillery':
  hull('Sloped gun casemate',[(0,.66,-.65,.92),(.57,.49,-.43,.74)],panel,turret)
  block('Rear ammunition locker',(0,.82,.23),(1.2,.36,.46),armor,turret,.06)
 elif wheeled:hull('Recon turret',[(0,.48,-.47,.46),(.39,.35,-.35,.35)],armor,turret)
 else:
  hull('Composite turret cheeks',[(0,.77,-.86,.64),(.36,.80,-.66,.73),(.56,.52,-.38,.47)],armor,turret)
  for side in [-1,1]:
   plate=block('Reactive cheek armor',(side*.66,-.29,.30),(.16,.75,.28),panel,turret,.035);plate.rotation_euler.z=side*.20
 cylinder('Commander hatch',(0,.22,.60 if not wheeled else .44),.24,.08,steel,turret)
 block('Thermal sight',(.30,-.30,.55 if not wheeled else .39),(.20,.27,.14),glass,turret,.018)
 cylinder('Antenna',(-.34,.41,.98),.016,.95,steel,turret,vertices=6)
 for side in [-1,1]:block('Recognition stripe',(side*.54,.10,.49),(.08,.34,.035),stripe,turret,.005)
 join_group(turret,'TurretArmor')
 recoil=bpy.data.objects.new('Recoil',None);bpy.context.collection.objects.link(recoil);recoil.parent=turret
 recoil.location=(0,-.58,.28)
 length=2.9 if role=='artillery' else 1.9 if role=='tank' else 1.2
 cylinder('Rifled barrel',(0,-length*.5,0),.075 if not wheeled else .045,length,steel,recoil,(math.pi/2,0,0),16)
 cylinder('Mantlet',(0,.02,0),.22,.34,armor,recoil,(math.pi/2,0,0),16)
 cylinder('Bore',(0,-length-.025,0),.055 if not wheeled else .03,.02,track,recoil,(math.pi/2,0,0),12)
 if role=='artillery':
  block('Muzzle brake',(0,-length+.08,0),(.27,.34,.21),steel,recoil,.025)
  for side in [-1,1]:block('Brake slot',(side*.14,-length+.07,0),(.015,.13,.07),track,recoil,.003)
 join_group(recoil,'GunAssembly')
 for frame,y in [(1,-.58),(3,-.40),(11,-.58)]:
  recoil.location.y=y;recoil.keyframe_insert(data_path='location',frame=frame,group='Fire')
 bpy.context.scene.frame_end=11;bpy.context.scene.frame_set(1)
 meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
 metrics[role]={'triangles':sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in meshes),'articulated_meshes':len(meshes)}
 bpy.ops.wm.save_as_mainfile(filepath=str(source/(role+'.blend')))
 bpy.ops.export_scene.gltf(filepath=str(out/(role+'.glb')),export_format='GLB',export_animations=True,export_apply=True)
 print('BATTLE ASSET',role,metrics[role],flush=True)
# Battlefield structures follow the same drawn material/shape reference.
bpy.ops.wm.read_factory_settings(use_empty=True)
concrete=material('Weathered concrete',(.20,.21,.18),0.,.95)
steel=material('Dark structural steel',(.065,.078,.072),.5,.55)
sand=material('Sandbags',(.28,.255,.18),0.,1.)
glass=material('Recessed windows',(.025,.04,.035),.1,.5)
root=bpy.data.objects.new('CommandPost',None);bpy.context.collection.objects.link(root)
hull('Reinforced concrete shell',[(0,3.0,-2.25,2.25),(1.75,3.0,-2.25,2.25),(2.1,2.72,-2.0,2.0)],concrete,root)
block('Roof cap',(0,0,2.12),(5.8,4.3,.23),steel,root,.10)
for x in [-1.5,1.5]:
 block('Recessed firing slit',(x,-2.265,1.35),(1.2,.025,.27),glass,root,.015)
 block('Window hood',(x,-2.32,1.55),(1.4,.30,.12),concrete,root,.025)
block('Armored door',(0,-2.27,.85),(.8,.06,1.65),steel,root,.04)
for i in range(3):block('Door step',(0,-2.6-i*.3,.32-i*.09),(1.5,.35,.18),concrete,root,.025)
for side in [-1,1]:
 for row in range(2):
  for i in range(6):
   bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=6,radius=1,location=(side*3.2,-1.9+i*.65+row*.15,.18+row*.27))
   o=bpy.context.object;o.scale=(.24,.38,.17);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);finish(o,'Sandbag',sand,root)
cylinder('Communications mast',(1.6,.8,3.2),.035,2.2,steel,root,vertices=8)
for h in [2.8,3.4,3.9]:cylinder('Antenna crossbar',(1.6,.8,h),.022,1.1,steel,root,(0,math.pi/2,0),8)
bpy.ops.mesh.primitive_uv_sphere_add(segments=20,ring_count=8,radius=1,location=(-1.3,.5,2.7))
o=bpy.context.object;o.scale=(.75,.75,.15);o.rotation_euler.x=.7;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);finish(o,'Satellite dish',concrete,root)
join_group(root,'FortifiedCommandPost')
bpy.ops.wm.save_as_mainfile(filepath=str(source/'command-post.blend'))
bpy.ops.export_scene.gltf(filepath=str(out/'command-post.glb'),export_format='GLB')
(out/'manifest.json').write_text(json.dumps({'license':'CC0-1.0','author':'FRONTLINE ZERO original Blender pipeline','source':'scripts/build_battle_assets.py','metrics':metrics},indent=2)+'\n')
