extends Node
## CharacterManager — 角色管理器 (Autoload)
##
## 管理 3 个角色的定义数据、当前选择角色。
## 不持有 Texture/Resource，仅做文本数据和 ID 管理。
## 资源由 SudokuGame 按需加载，带缺失兼容。

signal character_changed(char_id: StringName)

# 技能类映射（预加载，热路径不 I/O）
const SKILL_CLASSES := {
	&"char_a": preload("res://scripts/game/skills/SkillChainReveal.gd"),
	&"char_b": preload("res://scripts/game/skills/SkillConflictBlock.gd"),
	&"char_c": preload("res://scripts/game/skills/SkillComboReveal.gd"),
}

# 角色定义
const CHARACTERS := {
	&"char_a": {
		"name": "连锁者",
		"skill_name": "连锁揭露",
		"skill_desc": "每完成一行/一列/一宫，自动揭露盘面上任意一个空格",
		"portrait": "res://assets/characters/char_a/portrait.png",
		"avatar": "res://assets/characters/char_a/avatar.png",
	},
	&"char_b": {
		"name": "明镜者",
		"skill_name": "冲突屏蔽",
		"skill_desc": "选中空格时，键盘自动禁用所有会导致冲突的数字",
		"portrait": "res://assets/characters/char_b/portrait.png",
		"avatar": "res://assets/characters/char_b/avatar.png",
	},
	&"char_c": {
		"name": "专注者",
		"skill_name": "连击馈赠",
		"skill_desc": "每连续正确填入5个数字，自动揭露1个空格",
		"portrait": "res://assets/characters/char_c/portrait.png",
		"avatar": "res://assets/characters/char_c/avatar.png",
	},
}

var current_char_id: StringName = &"char_a"


func _ready() -> void:
	_load()


## 获取角色定义
static func get_char_def(char_id: StringName) -> Dictionary:
	return CHARACTERS.get(char_id, {})


## 获取所有角色 ID 列表
static func get_all_char_ids() -> Array:
	var ids: Array = []
	for key in CHARACTERS:
		ids.append(key)
	return ids


## 设置当前角色
func set_character(char_id: StringName) -> void:
	if not CHARACTERS.has(char_id):
		return
	current_char_id = char_id
	character_changed.emit(char_id)
	_save()


## 获取当前角色定义
func get_current_def() -> Dictionary:
	return CHARACTERS.get(current_char_id, {})


## 获取当前角色名
func get_current_name() -> String:
	var def := get_current_def()
	return def.get("name", "?")


## 获取当前技能名
func get_current_skill_name() -> String:
	var def := get_current_def()
	return def.get("skill_name", "")


## 创建当前角色的技能实例
func create_skill() -> SkillBase:
	var cls = SKILL_CLASSES.get(current_char_id)
	if cls:
		return cls.new()
	return null


# ======== 台词系统（预留） ========

var _dialogue_data: Dictionary = {}
var _dialogue_loaded := false

## 加载台词 JSON（资源缺失时静默跳过）
func load_dialogue() -> void:
	if _dialogue_loaded:
		return
	var path := "res://assets/dialogue.json"
	if not FileAccess.file_exists(path):
		_dialogue_loaded = true
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		_dialogue_loaded = true
		return
	var json := JSON.parse_string(file.get_as_text())
	if typeof(json) == TYPE_DICTIONARY:
		_dialogue_data = json
	_dialogue_loaded = true


## 获取一句随机台词
func get_random_line(char_id: StringName, trigger_id: String) -> String:
	if not _dialogue_loaded:
		load_dialogue()
	var char_data: Dictionary = _dialogue_data.get(str(char_id), {})
	var lines: Array = char_data.get(trigger_id, [])
	if lines.is_empty():
		return ""
	return lines[randi() % lines.size()]


# ======== 语音（预留接口） ========

## 获取语音文件路径（文件不存在时返回空字符串）
func get_voice_path(char_id: StringName, trigger_id: String, index: int) -> String:
	var path := "res://assets/characters/%s/voice/%s_%s_%02d.ogg" % [char_id, char_id, trigger_id, index + 1]
	if not FileAccess.file_exists(path):
		return ""
	return path


# ======== 持久化 ========

func save() -> void:
	ProfileSaver.set_section("character", {"character": str(current_char_id)})


func _load() -> void:
	var data := ProfileSaver.get_section("character")
	if data.is_empty():
		return
	var saved_id := StringName(data.get("character", "char_a"))
	if CHARACTERS.has(saved_id):
		current_char_id = saved_id
