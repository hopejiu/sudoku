class_name SudokuGame
extends Control
## SudokuGame — 数独游戏主脚本
## 管理顶部栏、网格、键盘、计时器、暂停、通关、自动存档

var board: SudokuBoard
var selected_row: int = -1
var selected_col: int = -1
var is_note_mode: bool = false
var is_paused: bool = false
var level: int = 8
var elapsed_time: float = 0.0
var is_game_over: bool = false

# 同难度连胜计数，达到 5 的倍数时触发鼓励
var _streak_win_count: int = 0

@onready var difficulty_label: Label = %DifficultyLabel
@onready var timer_label: Label = %TimerLabel
@onready var hint_label: Label = %HintLabel
@onready var undo_btn: Button = %UndoBtn
@onready var hint_btn: Button = %HintBtn
@onready var pause_btn: Button = %PauseBtn
@onready var menu_btn: Button = %MenuBtn
@onready var grid_control: Control = %Grid
@onready var keyboard_node: Node = %NumberKeyboard

@onready var pause_overlay: ColorRect = %PauseOverlay
@onready var resume_btn: Button = %ResumeBtn
@onready var restart_btn: Button = %RestartBtn
@onready var main_menu_btn: Button = %MainMenuBtn
@onready var confirm_label: Label = %ConfirmLabel
@onready var confirm_yes: Button = %ConfirmYes
@onready var confirm_no: Button = %ConfirmNo

var _pending_confirm: Callable  # 确认后执行的函数

@onready var victory_overlay: ColorRect = %VictoryOverlay
@onready var v_time_label: Label = %VTimeLabel
@onready var v_hint_label: Label = %VHintLabel
@onready var v_streak_label: Label = %VStreakLabel
@onready var easy_btn: Button = %EasyBtn
@onready var same_btn: Button = %SameBtn
@onready var hard_btn: Button = %HardBtn


func _ready() -> void:
	board = SudokuBoard.new()
	_load_game_params()
	_connect_signals()


func _connect_signals() -> void:
	var keyboard: NumberKeyboard = keyboard_node as NumberKeyboard
	keyboard.number_pressed.connect(_on_number_pressed)
	keyboard.clear_pressed.connect(_on_clear_pressed)
	keyboard.note_mode_toggled.connect(_on_note_mode_toggled)

	undo_btn.pressed.connect(_on_undo_pressed)
	hint_btn.pressed.connect(_on_hint_pressed)
	pause_btn.pressed.connect(_on_pause_pressed)
	menu_btn.pressed.connect(_on_pause_pressed)
	resume_btn.pressed.connect(_on_resume_pressed)
	restart_btn.pressed.connect(_on_restart_pressed)
	main_menu_btn.pressed.connect(_on_main_menu_pressed)
	confirm_yes.pressed.connect(_on_confirm_yes)
	confirm_no.pressed.connect(_on_confirm_no)

	easy_btn.pressed.connect(_on_difficulty_choice.bind(level - 1))
	same_btn.pressed.connect(_on_difficulty_choice.bind(level))
	hard_btn.pressed.connect(_on_difficulty_choice.bind(level + 1))


func _load_game_params() -> void:
	var params: Dictionary = SaveManager.get_temp("next_game", {})
	if params.is_empty():
		_start_new_game(8)
		return

	var action: String = params.get("action", "new")
	match action:
		"continue":
			_load_saved_game()
		"history_replay":
			_load_history_puzzle(params)
		_:
			_start_new_game(params.get("level", 8))

	SaveManager.set_temp("next_game", {})


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED and not is_game_over:
		_on_pause_pressed()


func _start_new_game(lvl: int) -> void:
	level = clampi(lvl, 1, 16)
	var puzzle := SudokuGenerator.generate(level)
	board.load_puzzle(puzzle.grid, puzzle.given, puzzle.solution)
	selected_row = -1
	selected_col = -1
	elapsed_time = 0.0
	is_game_over = false
	is_paused = false
	_update_ui()
	_auto_save()


func _load_saved_game() -> void:
	var data: Dictionary = SaveManager.load_current_game()
	if data.is_empty():
		_start_new_game(8)
		return
	board.deserialize(data.get("board", {}))
	level = data.get("level", 8)
	elapsed_time = data.get("elapsed_time", 0.0)
	_streak_win_count = data.get("streak", 0)
	is_game_over = false
	is_paused = false
	_update_ui()


func _load_history_puzzle(params: Dictionary) -> void:
	var level_from_history: int = params.get("level", 8)
	var puzzle := SudokuGenerator.generate(level_from_history)
	board.load_puzzle(puzzle.grid, puzzle.given, puzzle.solution)
	selected_row = -1
	selected_col = -1
	elapsed_time = 0.0
	_streak_win_count = 0
	is_game_over = false
	is_paused = false
	level = level_from_history
	_update_ui()


func _process(delta: float) -> void:
	if not is_paused and not is_game_over:
		elapsed_time += delta
		timer_label.text = _format_time(elapsed_time)


func _update_ui() -> void:
	difficulty_label.text = "难度 " + str(level)
	timer_label.text = _format_time(elapsed_time)
	hint_label.text = ""
	grid_control.queue_redraw()


static func _format_time(seconds: float) -> String:
	var total := int(seconds)
	var m := total / 60
	var s := total % 60
	return "%02d:%02d" % [m, s]


# --------------------------------------------------------------------------
# 键盘输入
# --------------------------------------------------------------------------

func _on_number_pressed(num: int) -> void:
	if selected_row < 0 or is_paused or is_game_over:
		return
	if is_note_mode:
		board.toggle_note(selected_row, selected_col, num)
	else:
		board.set_cell(selected_row, selected_col, num)
		if board.is_victory():
			_on_victory()
			return
	grid_control.queue_redraw()
	_auto_save()


func _on_clear_pressed() -> void:
	if selected_row < 0 or is_paused or is_game_over:
		return
	if is_note_mode:
		board.notes[selected_row][selected_col] = 0
	else:
		board.set_cell(selected_row, selected_col, 0)
	grid_control.queue_redraw()
	_auto_save()


func _on_note_mode_toggled(enabled: bool) -> void:
	is_note_mode = enabled


# --------------------------------------------------------------------------
# 顶部栏按钮
# --------------------------------------------------------------------------

func _on_undo_pressed() -> void:
	if is_game_over:
		return
	board.undo()
	grid_control.queue_redraw()
	_auto_save()


func _on_hint_pressed() -> void:
	if is_game_over:
		return
	var r := selected_row
	var c := selected_col
	if r < 0:
		# 自动找第一个空格
		for rr in 9:
			for cc in 9:
				if board.grid[rr][cc] == 0:
					r = rr
					c = cc
					break
			if r >= 0:
				break
	if r >= 0:
		selected_row = r
		selected_col = c
		board.get_hint(r, c)
		hint_label.text = "提示 %d 次" % board.hint_count
		# 2 秒后自动隐藏提示反馈
		get_tree().create_timer(2.0).timeout.connect(
			func(): 
				if is_instance_valid(hint_label):
					hint_label.text = ""
		)
		grid_control.queue_redraw()
		if board.is_victory():
			_on_victory()
			return
		_auto_save()


func _on_pause_pressed() -> void:
	is_paused = true
	pause_overlay.show()


func _on_resume_pressed() -> void:
	is_paused = false
	_hide_confirm()
	pause_overlay.hide()


func _on_restart_pressed() -> void:
	_pending_confirm = _do_restart
	_show_confirm("确定重新开始？当前进度将丢失。")


func _on_main_menu_pressed() -> void:
	_pending_confirm = _do_main_menu
	_show_confirm("返回主界面？游戏将自动保存当前进度。")


func _do_restart() -> void:
	pause_overlay.hide()
	_streak_win_count = 0
	_start_new_game(level)


func _do_main_menu() -> void:
	pause_overlay.hide()
	SaveManager.set_temp("next_game", {})
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")


# --------------------------------------------------------------------------
# 确认对话框
# --------------------------------------------------------------------------

func _show_confirm(message: String) -> void:
	confirm_label.text = message
	resume_btn.hide()
	restart_btn.hide()
	main_menu_btn.hide()
	confirm_label.show()
	confirm_yes.show()
	confirm_no.show()
	confirm_yes.get_parent().show()


func _hide_confirm() -> void:
	confirm_label.hide()
	confirm_yes.hide()
	confirm_no.hide()
	confirm_yes.get_parent().hide()
	resume_btn.show()
	restart_btn.show()
	main_menu_btn.show()


func _on_confirm_yes() -> void:
	_hide_confirm()
	if _pending_confirm.is_valid():
		_pending_confirm.call()


func _on_confirm_no() -> void:
	_hide_confirm()


# --------------------------------------------------------------------------
# 通关
# --------------------------------------------------------------------------

func _on_victory() -> void:
	is_game_over = true
	_record_history()
	SaveManager.clear_current_game()

	_streak_win_count += 1

	var level_up := level < 16
	var level_down := level > 1

	easy_btn.disabled = not level_down
	hard_btn.disabled = not level_up
	same_btn.disabled = false

	# 重新绑定（因为 level 没变，但按钮存的是创建时的值）
	easy_btn.pressed.disconnect(_on_difficulty_choice)
	same_btn.pressed.disconnect(_on_difficulty_choice)
	hard_btn.pressed.disconnect(_on_difficulty_choice)
	easy_btn.pressed.connect(_on_difficulty_choice.bind(level - 1))
	same_btn.pressed.connect(_on_difficulty_choice.bind(level))
	hard_btn.pressed.connect(_on_difficulty_choice.bind(level + 1))

	v_time_label.text = "用时: " + _format_time(elapsed_time)
	v_hint_label.text = "提示次数: %d" % board.hint_count

	# "维持难度"默认高亮
	same_btn.grab_focus()

	if _streak_win_count > 0 and _streak_win_count % 5 == 0:
		v_streak_label.text = "🎉 连续通关 %d 局！试试更高难度？" % _streak_win_count
	elif _streak_win_count > 1:
		v_streak_label.text = "同难度连胜 %d 局" % (_streak_win_count - 1)
	else:
		v_streak_label.text = ""

	victory_overlay.show()


func _on_difficulty_choice(new_level: int) -> void:
	new_level = clampi(new_level, 1, 16)
	victory_overlay.hide()
	if new_level != level:
		_streak_win_count = 0
	elif _streak_win_count % 5 == 0:
		_streak_win_count = 0
	_start_new_game(new_level)


func _record_history() -> void:
	var entry := {
		"datetime": Time.get_datetime_dict_from_system(),
		"level": level,
		"time": int(elapsed_time),
		"won": true,
		"hint_count": board.hint_count,
		"board_snapshot": board.serialize(),
	}
	SaveManager.append_history(entry)


# --------------------------------------------------------------------------
# 自动存档
# --------------------------------------------------------------------------

func _auto_save() -> void:
	var data := {
		"board": board.serialize(),
		"level": level,
		"elapsed_time": elapsed_time,
		"streak": _streak_win_count,
	}
	SaveManager.save_current_game(data)


# --------------------------------------------------------------------------
# 物理键盘输入
# --------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key: int = event.keycode
		if key >= KEY_1 and key <= KEY_9:
			_on_number_pressed(key - KEY_1 + 1)
		elif key == KEY_BACKSPACE or key == KEY_DELETE:
			_on_clear_pressed()
		elif key == KEY_ESCAPE:
			_on_pause_pressed()
		elif key == KEY_LEFT or key == KEY_A:
			_move_selection(0, -1)
		elif key == KEY_RIGHT or key == KEY_D:
			_move_selection(0, 1)
		elif key == KEY_UP or key == KEY_W:
			_move_selection(-1, 0)
		elif key == KEY_DOWN or key == KEY_S:
			_move_selection(1, 0)


func _move_selection(dr: int, dc: int) -> void:
	if selected_row < 0:
		selected_row = 4
		selected_col = 4
	else:
		selected_row = clampi(selected_row + dr, 0, 8)
		selected_col = clampi(selected_col + dc, 0, 8)
	grid_control.queue_redraw()
