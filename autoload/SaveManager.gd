extends Node
## SaveManager — 存档管理器 (Autoload)
##
## 数据持久化，使用 FileAccess.store_var 二进制序列化。
## 三文件分离：
##   - settings.save   : 主题设置
##   - current.save    : 游戏队列（Array[Dictionary]，最多 3 个条目）
##                     队首=当前游戏，队尾=预生成
##   - history.save    : 历史记录
##
## 跨场景参数传递已拆至 SceneParams Autoload。

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

# ======================== 游戏队列（FIFO，最多 3 个） ========================

## 加载完整游戏队列
func load_queue() -> Array:
	if not FileAccess.file_exists(CURRENT_PATH):
		return []
	var file := FileAccess.open(CURRENT_PATH, FileAccess.READ)
	if not file:
		return []
	var data = file.get_var()
	# 兼容旧格式：单 Dictionary → 转为数组
	if typeof(data) == TYPE_DICTIONARY:
		return [data]
	if typeof(data) == TYPE_ARRAY:
		return data
	return []

## 保存完整游戏队列（超过 3 个自动截断）
func save_queue(queue: Array) -> void:
	if queue.size() > 3:
		queue = queue.slice(0, 3)
	var file := FileAccess.open(CURRENT_PATH, FileAccess.WRITE)
	if file:
		file.store_var(queue)

## 获取队首（不删除）
func queue_front() -> Dictionary:
	var q := load_queue()
	if q.is_empty():
		return {}
	return q[0]

## 弹出队首并返回
func queue_pop_front() -> Dictionary:
	var q := load_queue()
	if q.is_empty():
		return {}
	var front: Dictionary = q.pop_front()
	save_queue(q)
	return front

## 更新/写入队首（自动存档用）
func queue_set_front(data: Dictionary) -> void:
	var q := load_queue()
	if q.is_empty():
		q = [data]
	else:
		q[0] = data
	save_queue(q)

## 向队首插入（用于新生成或历史重开）
func queue_push_front(data: Dictionary) -> void:
	var q := load_queue()
	q.push_front(data)
	save_queue(q)

## 向队尾追加（后台预填充）
func queue_push_back(data: Dictionary) -> void:
	var q := load_queue()
	q.append(data)
	save_queue(q)

## 队列是否为空
func queue_is_empty() -> bool:
	return load_queue().is_empty()

## 队列大小
func queue_size() -> int:
	return load_queue().size()

## 清空队列
func queue_clear() -> void:
	DirAccess.remove_absolute(CURRENT_PATH)

## 兼容旧名：清空当前对局
func clear_current_game() -> void:
	queue_clear()

## 兼容旧名：读取当前对局（返回队首）
func load_current_game() -> Dictionary:
	return queue_front()

## 兼容旧名：保存当前对局（更新队首）
func save_current_game(data: Dictionary) -> void:
	queue_set_front(data)

# ======================== 历史记录 ========================

## 追加历史记录
func append_history(entry: Dictionary) -> void:
	var history: Array[Dictionary] = load_history()
	history.push_front(entry)
	# 仅保留最近 20 局
	if history.size() > 20:
		history.resize(20)
	var file := FileAccess.open(HISTORY_PATH, FileAccess.WRITE)
	if file:
		file.store_var(history)

## 读取全部历史记录
func load_history() -> Array[Dictionary]:
	if not FileAccess.file_exists(HISTORY_PATH):
		return []
	var file := FileAccess.open(HISTORY_PATH, FileAccess.READ)
	if file:
		return file.get_var()
	return []
