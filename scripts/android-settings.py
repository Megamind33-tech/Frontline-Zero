"""Set only required Godot Android paths, preserving existing settings."""
import sys,pathlib,json
path,sdk,jdk,key=sys.argv[1:]
p=pathlib.Path(path)
s=p.read_text() if p.exists() else '[gd_resource type="EditorSettings" format=3]\n\n[resource]\n'
for name,value in [('android_sdk_path',sdk),('java_sdk_path',jdk),('debug_keystore',key),('debug_keystore_user','androiddebugkey'),('debug_keystore_pass','android')]:
 setting='export/android/'+name
 lines=s.splitlines();lines=[l for l in lines if not l.startswith(setting+' =')]
 s='\n'.join(lines)+'\n'+setting+' = '+json.dumps(value)+'\n'
p.write_text(s)
