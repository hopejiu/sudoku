extends Node
## SceneParams — 跨场景参数传递 (Autoload)
##
## 替代 SaveManager.set_temp / get_temp，职责单一：仅做内存参数传递。
## 场景切换时写入参数，目标场景 _ready 中读取并清理。

var _temp_meta: Dictionary = {}

## 存储临时参数
func set_param(key: String, value) -> void:
	_temp_meta[key] = value

## 读取临时参数
func get_param(key: String, default_value = null):
	return _temp_meta.get(key, default_value)

## 清理指定键
func clear_param(key: String) -> void:
	_temp_meta.erase(key)
