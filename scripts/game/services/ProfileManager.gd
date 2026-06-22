class_name ProfileManager
## ProfileManager — 统一存档管理器
##
## 消除 PlayerManager 和 CharacterManager 各自写 profile.save 的竞争。
## 所有数据合并为一个 Dictionary，按 section 读/写，单次 flush。
## 用 RefCounted（非 Node）避免场景树依赖，由 Autoload 按需调用。

const PROFILE_PATH := "user://profile.save"
const DEFAULT_MAX_AGE_SEC := 5.0  # 最大 5 秒自动 flush

var _data: Dictionary = {}
var _dirty := false
var _flush_timer: float = 0.0


## 读取一个 section 的数据
func get_section(section: String) -> Dictionary:
	if _data.is_empty():
		_data = _load_raw()
	return _data.get(section, {})


## 写入一个 section
func set_section(section: String, data: Dictionary) -> void:
	_data[section] = data
	_dirty = true
	_flush_timer = DEFAULT_MAX_AGE_SEC


## 强制写入磁盘
func flush() -> void:
	if not _dirty:
		return
	var file := FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(_data)
		_dirty = false


# 由 Autoload 的 _process 驱动自动 flush
func tick(delta: float) -> void:
	if not _dirty:
		return
	_flush_timer -= delta
	if _flush_timer <= 0.0:
		flush()


func _load_raw() -> Dictionary:
	if not FileAccess.file_exists(PROFILE_PATH):
		return {}
	var file := FileAccess.open(PROFILE_PATH, FileAccess.READ)
	if not file:
		return {}
	var data = file.get_var()
	if typeof(data) == TYPE_DICTIONARY:
		return data
	return {}
