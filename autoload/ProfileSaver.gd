extends Node
## ProfileSaver — 统一存档 Autoload
##
## 封装 ProfileManager，在 _process 中 tick flush。
## PlayerManager 和 CharacterManager 不再直接写文件，
## 改为调用 ProfileSaver.get_section / set_section。

const ProfileManager := preload("res://scripts/game/services/ProfileManager.gd")

var _pm: ProfileManager = null


func _ready() -> void:
	_pm = ProfileManager.new()


func _process(delta: float) -> void:
	if _pm:
		_pm.tick(delta)


func get_section(section: String) -> Dictionary:
	if _pm:
		return _pm.get_section(section)
	return {}


func set_section(section: String, data: Dictionary) -> void:
	if _pm:
		_pm.set_section(section, data)


func flush() -> void:
	if _pm:
		_pm.flush()


func _exit_tree() -> void:
	flush()
