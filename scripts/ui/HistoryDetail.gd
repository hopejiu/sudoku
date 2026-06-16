extends Control
## HistoryDetail — 历史详情
## 只读显示历史对局的元数据，支持「重开」和「继续」

var entry: Dictionary = {}

@onready var back_btn: Button = %BackBtn
@onready var info_label: Label = %InfoLabel
@onready var date_label: Label = %DateLabel
@onready var diff_label: Label = %DiffLabel
@onready var time_label: Label = %TimeLabel
@onready var replay_btn: Button = %ReplayBtn
@onready var continue_btn: Button = %ContinueBtn


func _ready() -> void:
	entry = SaveManager.get_temp("history_entry", {})
	if entry.is_empty():
		info_label.text = "无数据"
		return

	back_btn.pressed.connect(_on_back_pressed)
	replay_btn.pressed.connect(_on_replay_pressed)
	continue_btn.pressed.connect(_on_continue_pressed)
	_refresh()


func _refresh() -> void:
	var dt: Dictionary = entry.get("datetime", {})
	date_label.text = "日期: %04d-%02d-%02d" % [dt.get("year", 0), dt.get("month", 0), dt.get("day", 0)]
	diff_label.text = "难度: %d" % entry.get("level", "?")
	var total_sec: int = entry.get("time", 0)
	var m: int = total_sec / 60
	var s: int = total_sec % 60
	time_label.text = "用时: %02d:%02d" % [m, s]
	info_label.text = "通关" if entry.get("won", false) else "未完成"
	continue_btn.disabled = not entry.get("won", false) == false


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/sudoku/HistoryList.tscn")


func _on_replay_pressed() -> void:
	var lvl: int = entry.get("level", 8)
	SaveManager.set_temp("next_game", {"action": "new", "level": lvl})
	get_tree().change_scene_to_file("res://scenes/sudoku/SudokuGame.tscn")


func _on_continue_pressed() -> void:
	SaveManager.set_temp("next_game", {"action": "continue"})
	get_tree().change_scene_to_file("res://scenes/sudoku/SudokuGame.tscn")
