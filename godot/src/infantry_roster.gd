extends RefCounted
## Reads INF-001 data. Does not alter the vehicle battle simulation.

static func read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"error": error_string(FileAccess.get_open_error())}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {"error": "invalid json"}

static func rifleman() -> Dictionary:
	return read_json("res://data/infantry/inf001_rifleman.json")

static func barracks() -> Dictionary:
	return read_json("res://data/production/barracks.json")
