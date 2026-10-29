extends RefCounted
const PATH = "user://campaign-v1.json"
static func load_record(path: String = PATH) -> Dictionary:
 var fallback = {"version":1,"wins":0,"losses":0,"territory":"contested","history":[]}
 if not FileAccess.file_exists(path):
  return fallback
 var data = JSON.parse_string(FileAccess.get_file_as_string(path))
 if not data is Dictionary or data.get("version") != 1 or not data.get("history") is Array or not data.get("wins") is float and not data.get("wins") is int or not data.get("losses") is float and not data.get("losses") is int:
  return fallback
 return data
static func save_result(result: Dictionary, id: String, path: String = PATH) -> Error:
 if not result.has("winner"):
  return ERR_INVALID_DATA
 var data = load_record(path)
 if data.history.any(func(h): return h.get("id") == id):
  return OK
 data.wins += 1 if result.winner == 0 else 0
 data.losses += 1 if result.winner == 1 else 0
 data.territory = "Aster" if result.winner == 0 else "Veyr" if result.winner == 1 else data.territory
 var entry = result.duplicate()
 entry.id = id
 data.history.push_front(entry)
 if data.history.size()>20:
  data.history.resize(20)
 var f = FileAccess.open(path+".tmp",FileAccess.WRITE)
 if f == null:
  return FileAccess.get_open_error()
 f.store_string(JSON.stringify(data))
 f.close()
 return DirAccess.rename_absolute(path+".tmp",path)
