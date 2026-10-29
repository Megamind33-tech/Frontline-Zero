"""Original low-poly GLB unit generator. Blender --background --python this.py -- output_dir."""
import bpy,math,sys,pathlib,json
out=pathlib.Path(sys.argv[sys.argv.index('--')+1]).resolve();out.mkdir(parents=True,exist_ok=True)
def mat(name,c):
 m=bpy.data.materials.new(name);m.diffuse_color=(*c,1);return m
def box(name,p,s,m,parent=None):
 bpy.ops.mesh.primitive_cube_add(size=1,location=p);o=bpy.context.object;o.name=name;o.scale=s;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(m);o.parent=parent;return o
def cyl(name,p,r,d,m,rot=(0,0,0),parent=None):
 bpy.ops.mesh.primitive_cylinder_add(vertices=12,radius=r,depth=d,location=p,rotation=rot);o=bpy.context.object;o.name=name;o.data.materials.append(m);o.parent=parent;return o
for role in ['scout','tank','artillery']:
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 body=mat('Olive armor',(.24,.31,.18));dark=mat('Rubber',(.045,.055,.045));steel=mat('Steel',(.15,.17,.14));glass=mat('Periscopes',(.1,.21,.23))
 box('Hull',(0,0,.65),(1.8,3.1,.6),body);box('Glacis',(0,-1.05,.97),(1.7,.8,.35),body)
 if role=='scout':
  for x in [-.95,.95]:
   for y in [-1.,1.]:cyl('Wheel',(x,y,.45),.43,.24,dark,(0,math.pi/2,0))
  box('Cabin',(0,.3,1.18),(1.4,1.4,.55),body);box('Vision ports',(0,-.42,1.3),(1.15,.06,.22),glass)
 else:
  for x in [-1.,1.]:
   box('Track',(x,0,.43),(.45,3.5,.7),dark)
   for y in [-1.3,-.65,0,.65,1.3]:cyl('Roadwheel',(x,y,.44),.29,.48,steel,(0,math.pi/2,0))
 turret=bpy.data.objects.new('Turret',None);bpy.context.collection.objects.link(turret);turret.location=(0,.1,1.1)
 cyl('Turret armor',(0,0,.18),.65,.42,body,parent=turret)
 barrel=box('Barrel',(0,-1.35,.25),(.16,2.6 if role=='artillery' else 1.8,.16),steel,turret)
 if role=='scout':barrel.scale=(.65,.6,.65)
 box('Hatch',(0,.25,.42),(.45,.55,.08),steel,turret)
 for frame,y in [(1,-1.35),(4,-1.12),(12,-1.35)]:
  barrel.location.y=y;barrel.keyframe_insert(data_path='location',frame=frame,group='Recoil')
 bpy.context.scene.frame_end=12
 bpy.ops.export_scene.gltf(filepath=str(out/(role+'.glb')),export_format='GLB',export_animations=True,export_apply=True)
 print('GENERATED',role,flush=True)
(out/'manifest.json').write_text(json.dumps({'author':'FRONTLINE ZERO procedural pipeline','license':'CC0-1.0','source':'scripts/build_assets.py','assets':['scout.glb','tank.glb','artillery.glb'],'animation':'Barrel recoil action, 12 frames','purpose':'Prototype assets'},indent=2))
