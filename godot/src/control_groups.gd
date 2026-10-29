extends RefCounted
## Local group assignment survives selection/relaunch, with blueprint identity checks.
const PATH="user://control-groups-v1.json"
var path: String
var groups: Dictionary={}
func _init(file_path: String = PATH):
 path=file_path
 if not FileAccess.file_exists(path):return
 var data=JSON.parse_string(FileAccess.get_file_as_string(path))
 if data is Dictionary and data.get("version")==1 and data.get("groups") is Dictionary:
  for key in ["1","2","3"]:
   var value=data.groups.get(key,[])
   if value is Array and value.size()<=12 and value.all(func(e):return e is Dictionary and e.get("id") is float and e.id>=1 and e.id<=12 and floor(e.id)==e.id and e.get("signature") is String and e.signature.length()<=120):groups[key]=value
static func signature(u: Dictionary) -> String:
 return str(u.get("chassis",""))+"/"+str(u.get("weapon",""))+"/"+str(u.get("armor",""))
func assign(slot: int,ids: Array,units: Array) -> Error:
 if slot<1 or slot>3:return ERR_INVALID_PARAMETER
 var entries: Array=[]
 for u in units:
  if u.team==0 and u.hp>0 and ids.has(u.id):entries.append({"id":u.id,"signature":signature(u)})
 if entries.is_empty():return ERR_INVALID_DATA
 var previous=groups.duplicate(true)
 groups[str(slot)]=entries
 var f=FileAccess.open(path+".tmp",FileAccess.WRITE)
 if f==null:
  groups=previous
  return FileAccess.get_open_error()
 f.store_string(JSON.stringify({"version":1,"groups":groups}));f.close()
 var error=DirAccess.rename_absolute(path+".tmp",path)
 if error!=OK:groups=previous
 return error
func recall(slot: int,units: Array) -> Array:
 var selection: Array=[]
 for entry in groups.get(str(slot),[]):
  for u in units:
   if u.team==0 and u.hp>0 and u.id==int(entry.id) and signature(u)==entry.signature:selection.append(u.id)
 return selection
