extends Node
## SaveManager — 存档管理器 (Autoload)
## 统一管理所有数据持久化，使用 FileAccess.store_var 二进制序列化。
## 三文件分离：settings.save / current.save / history.save

const SETTINGS_PATH := "user://settings.save"
const CURRENT_PATH  := "user://current.save"
const HISTORY_PATH  := "user://history.save"

## 存储主题设置
func save_settings(data: Dictionary) -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_var(data)

## 读取主题设置
func load_settings() -> Dictionary:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return {}
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file:
		return file.get_var()
	return {}

## 存储当前对局
func save_current_game(data: Dictionary) -> void:
	var file := FileAccess.open(CURRENT_PATH, FileAccess.WRITE)
	if file:
		file.store_var(data)

## 读取当前对局
func load_current_game() -> Dictionary:
	if not FileAccess.file_exists(CURRENT_PATH):
		return {}
	var file := FileAccess.open(CURRENT_PATH, FileAccess.READ)
	if file:
		return file.get_var()
	return {}

## 追加历史记录
func append_history(entry: Dictionary) -> void:
	var history: Array = load_history()
	history.push_front(entry)
	# 仅保留最近 20 局
	if history.size() > 20:
		history.resize(20)
	var file := FileAccess.open(HISTORY_PATH, FileAccess.WRITE)
	if file:
		file.store_var(history)

## 读取全部历史记录
func load_history() -> Array:
	if not FileAccess.file_exists(HISTORY_PATH):
		return []
	var file := FileAccess.open(HISTORY_PATH, FileAccess.READ)
	if file:
		return file.get_var()
	return []

## 清空当前对局（通关后调用）
func clear_current_game() -> void:
	DirAccess.remove_absolute(CURRENT_PATH)


## ========== 临时元数据（跨场景传递参数） ==========
var _temp_meta: Dictionary = {}

func set_temp(key: String, value) -> void:
	_temp_meta[key] = value

func get_temp(key: String, default_value = null):
	return _temp_meta.get(key, default_value)
