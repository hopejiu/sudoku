extends Node
## GameQueueManager — 后台谜题生成队列管理器 (Autoload)
##
## 统一管理 SudokuLoading 和 SudokuGame 中的批量生成逻辑、
## Thread 生命周期和队列填充。消除两个场景间的重复代码。
##
## 使用方法：
##   1. ensure_filled(level, needed) — 确保队列中有足够匹配难度的条目
##   2. poll_generation() — 在 _process 中轮询生成是否完成
##   3. consume_next(level) — 获取匹配难度的条目
##   4. 场景切换时不需要清理线程（管理器自动处理）

signal queue_filled
signal generation_started

const MAX_QUEUE_SIZE := 3
const SudokuGenerator := preload("res://scripts/game/board/SudokuGenerator.gd")

var _generate_thread: Thread = null
var _is_generating: bool = false
var _pending_level: int = 8
var _pending_count: int = 0
var _generated_results: Array = []


## 确保队列中至少有 needed 个匹配 level 难度的条目。
## 如果不足，自动启动后台线程生成。
## 返回 true 表示队列已满足，false 表示正在生成需要等待。
func ensure_filled(level: int, needed: int) -> bool:
	var queue := SaveManager.load_queue()
	var match_count := 0
	for entry in queue:
		if entry.get("level") == level:
			match_count += 1
	if match_count >= needed:
		return true

	# 计算需要生成的数量
	var to_generate: int = max(needed - match_count, MAX_QUEUE_SIZE - queue.size())
	to_generate = max(1, to_generate)
	_start_generation(level, to_generate)
	return false


## 检查后台线程是否完成，如果完成则自动写入 SaveManager 队列
## 在场景的 _process 中调用。返回 true 表示本次轮询处理了完成事件。
func poll_generation() -> bool:
	if not _is_generating or not _generate_thread:
		return false
	if not _generate_thread.is_alive():
		_generated_results = _generate_thread.wait_to_finish()
		_generate_thread = null
		_is_generating = false
		_apply_results()
		return true
	return false


## 从队列中取出一个匹配指定难度的条目（移到队首后返回）
## 如果队列中没有匹配条目，返回空 Dictionary
func consume_next(level: int) -> Dictionary:
	var queue := SaveManager.load_queue()
	for i in queue.size():
		if queue[i].get("level") == level:
			var entry: Dictionary = queue[i]
			queue.remove_at(i)
			queue.push_front(entry)
			SaveManager.save_queue(queue)
			return entry
	return {}


## 是否正在生成中
func is_busy() -> bool:
	return _is_generating


## Autoload 生命周期结束（游戏退出）时清理线程
func _exit_tree() -> void:
	_cleanup()


## 强制清理线程
func cleanup() -> void:
	_cleanup()


func _cleanup() -> void:
	if _generate_thread and _generate_thread.is_alive():
		_generate_thread.wait_to_finish()
	_generate_thread = null
	_is_generating = false
	_generated_results = []


func _start_generation(level: int, count: int) -> void:
	if _is_generating:
		return
	_is_generating = true
	_pending_level = level
	_pending_count = count
	_generated_results = []
	generation_started.emit()
	_generate_thread = Thread.new()
	_generate_thread.start(_generate_batch.bind(level, count))


static func _generate_batch(level: int, count: int) -> Array:
	var results = []
	for i in count:
		results.append(SudokuGenerator.generate(level))
	return results


func _apply_results() -> void:
	if _generated_results.is_empty():
		return
	var queue := SaveManager.load_queue()
	for i in _generated_results.size():
		var entry := _make_entry(_generated_results[i], _pending_level)
		if i == 0:
			queue.push_front(entry)
		else:
			queue.append(entry)
	SaveManager.save_queue(queue)
	_generated_results = []
	queue_filled.emit()


static func _make_entry(result: Dictionary, lvl: int) -> Dictionary:
	var notes := []
	for r in 9:
		notes.append([])
		for c in 9:
			notes[r].append(0)
	return {
		"board": {
			"grid": result.grid,
			"given": result.given,
			"notes": notes,
			"undo_stack": [],
			"hint_count": 0,
			"solution": result.solution,
		},
		"level": lvl,
		"elapsed_time": 0.0,
		"streak": 0,
	}
