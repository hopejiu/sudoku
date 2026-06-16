extends Control
## HistoryList — 历史记录列表
## 按时间倒序展示最近 20 局，点击进入详情，顶部显示统计摘要

@onready var back_btn: Button = %BackBtn
@onready var item_list: VBoxContainer = %ItemList
@onready var empty_hint: Label = %EmptyHint
@onready var stats_label: Label = %StatsLabel


func _ready() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	_refresh_list()


func _refresh_list() -> void:
	# 清空旧条目
	for child in item_list.get_children():
		child.queue_free()

	var history: Array[Dictionary] = SaveManager.load_history()
	empty_hint.visible = history.is_empty()

	# 统计摘要
	stats_label.text = _compute_stats(history)

	# 列表
	for i in history.size():
		var entry: Dictionary = history[i]
		var btn := Button.new()
		btn.text = _format_entry(entry)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var index := i
		btn.pressed.connect(_on_entry_pressed.bind(index, entry))
		item_list.add_child(btn)


static func _format_time(seconds: int) -> String:
	var m := seconds / 60
	var s := seconds % 60
	return "%02d:%02d" % [m, s]


static func _compute_stats(history: Array[Dictionary]) -> String:
	var total := history.size()
	if total == 0:
		return ""

	var won := 0
	var best_times := {}  # level -> min time
	var sum_times := {}   # level -> total time (for avg)
	var level_counts := {}  # level -> count

	for entry in history:
		var lvl: int = entry.get("level", 0)
		level_counts[lvl] = level_counts.get(lvl, 0) + 1

		if not entry.get("won", false):
			continue
		won += 1
		var t: int = entry.get("time", 0)
		sum_times[lvl] = sum_times.get(lvl, 0) + t
		if not best_times.has(lvl) or t < best_times[lvl]:
			best_times[lvl] = t

	var rate := float(won) / total * 100.0
	var lines: PackedStringArray = []
	lines.append("总场次: %d  通关: %d  通关率: %.0f%%" % [total, won, rate])

	# 各难度详情（按难度排序）
	var sorted_levels := level_counts.keys()
	sorted_levels.sort()
	for lvl in sorted_levels:
		var cnt := level_counts[lvl]
		if best_times.has(lvl):
			lines.append("难度%d: %d局  最佳 %s  平均 %s" % [
				lvl, cnt,
				_format_time(best_times[lvl]),
				_format_time(sum_times[lvl] / cnt),
			])
		else:
			lines.append("难度%d: %d局" % [lvl, cnt])

	return "\n".join(lines)


static func _format_entry(entry: Dictionary) -> String:
	var dt := entry.get("datetime", {})
	var date_str := "%04d-%02d-%02d" % [dt.get("year", 0), dt.get("month", 0), dt.get("day", 0)]
	var total_sec := entry.get("time", 0)
	var m := total_sec / 60
	var s := total_sec % 60
	var won := "✓" if entry.get("won", false) else "✗"
	return "%s  难度%s  %02d:%02d  %s" % [date_str, entry.get("level", "?"), m, s, won]


func _on_entry_pressed(index: int, entry: Dictionary) -> void:
	SaveManager.set_temp("history_entry", entry)
	get_tree().change_scene_to_file("res://scenes/sudoku/HistoryDetail.tscn")


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")
