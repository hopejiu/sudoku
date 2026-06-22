extends Control
## HistoryDetail — 历史详情
## 只读显示历史对局的元数据，支持「重开」和「继续」

const SceneTransition := preload("res://scripts/ui/common/SceneTransition.gd")

var entry: Dictionary = {}

@onready var bg: ColorRect = %Bg
@onready var back_btn: Button = %BackBtn
@onready var info_label: Label = %InfoLabel
@onready var date_label: Label = %DateLabel
@onready var diff_label: Label = %DiffLabel
@onready var time_label: Label = %TimeLabel
@onready var replay_btn: Button = %ReplayBtn
@onready var continue_btn: Button = %ContinueBtn


func _ready() -> void:
	entry = SceneParams.get_param("history_entry", {})
	if entry.is_empty():
		info_label.text = "无数据"
		return

	back_btn.pressed.connect(_on_back_pressed)
	replay_btn.pressed.connect(_on_replay_pressed)
	continue_btn.pressed.connect(_on_continue_pressed)

	# 主题颜色绑定
	ThemeManager.theme_changed.connect(_on_theme_changed)
	_on_theme_changed(ThemeManager.current_theme_name)

	_refresh()


func _on_theme_changed(_name: String) -> void:
	bg.color = ThemeManager.get_color("background")
	var primary := ThemeManager.get_color("primary")
	back_btn.modulate = primary


func _refresh() -> void:
	var dt: Dictionary = entry.get("datetime", {})
	date_label.text = "日期: %04d-%02d-%02d" % [dt.get("year", 0), dt.get("month", 0), dt.get("day", 0)]
	diff_label.text = "难度: %d" % entry.get("level", "?")
	var total_sec: int = entry.get("time", 0)
	var m: int = int(total_sec / 60.0)
	var s: int = total_sec % 60
	time_label.text = "用时: %02d:%02d" % [m, s]
	var won: bool = entry.get("won", false)
	info_label.text = "通关" if won else "未完成"
	# 修正：已通关的局禁用「继续」按钮
	continue_btn.disabled = won


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		SceneTransition.change_to("res://scenes/sudoku/HistoryList.tscn")


func _on_back_pressed() -> void:
	SceneTransition.change_to("res://scenes/sudoku/HistoryList.tscn")


func _on_replay_pressed() -> void:
	var lvl: int = entry.get("level", 8)
	var snapshot: Dictionary = entry.get("board_snapshot", {})
	SceneParams.set_param("next_game", {
		"action": "history_replay",
		"level": lvl,
		"board_snapshot": snapshot,
	})
	SceneTransition.change_to("res://scenes/sudoku/SudokuLoading.tscn")


func _on_continue_pressed() -> void:
	SceneParams.set_param("next_game", {"action": "continue"})
	SceneTransition.change_to("res://scenes/sudoku/SudokuLoading.tscn")
