class_name SudokuGame
extends Control
## SudokuGame — 数独游戏主脚本
##
## 编排层，协调各子模块：
## - TimerController：计时
## - GridRenderState：网格渲染数据
## - DialogAnimator：弹窗动画（静态方法调用）
## - SceneParams：场景参数传递

var board: SudokuBoard
var render_state := GridRenderState.new()
var timer_controller := TimerController.new()

var selected_row: int = -1
var selected_col: int = -1
var is_note_mode: bool = false
var is_paused: bool = false
var level: int = 8
var is_game_over: bool = false

# 同难度连胜计数，达到 5 的倍数时触发鼓励
var _streak_win_count: int = 0

@onready var bg: ColorRect = %Bg
@onready var difficulty_label: Label = %DifficultyLabel
@onready var timer_label: Label = %TimerLabel
@onready var hint_label: Label = %HintLabel
@onready var undo_btn: Button = %UndoBtn
@onready var hint_btn: Button = %HintBtn
@onready var pause_btn: Button = %PauseBtn
@onready var grid_control: Control = %Grid
@onready var keyboard_node: Node = %NumberKeyboard
@onready var timer_toggle_btn: Button = %TimerToggleBtn
@onready var auto_btn: Button = %AutoBtn

@onready var pause_overlay: ColorRect = %PauseOverlay
@onready var pause_panel: Panel = %PausePanel
@onready var resume_btn: Button = %ResumeBtn
@onready var restart_btn: Button = %RestartBtn
@onready var main_menu_btn: Button = %MainMenuBtn
@onready var confirm_label: Label = %ConfirmLabel
@onready var confirm_yes: Button = %ConfirmYes
@onready var confirm_no: Button = %ConfirmNo
@onready var confirm_btn_row: CenterContainer = %ConfirmBtnRow

var _pending_confirm: Callable  # 确认后执行的函数

@onready var victory_overlay: ColorRect = %VictoryOverlay
@onready var v_time_label: Label = %VTimeLabel
@onready var v_hint_label: Label = %VHintLabel
@onready var v_streak_label: Label = %VStreakLabel
@onready var easy_btn: Button = %EasyBtn
@onready var same_btn: Button = %SameBtn
@onready var hard_btn: Button = %HardBtn

# 缓存的 Tween 引用，防止多个 Tween 冲突
var _dialog_tween: Tween = null


func _ready() -> void:
	push_warning("[SudokuGame] _ready() called")
	board = SudokuBoard.new()
	# 将 Grid 的 render_state 指向新建的 render_state
	(grid_control as SudokuGrid).render_state = render_state
	(grid_control as SudokuGrid).cell_selected.connect(_on_cell_selected)
	_load_game_params()
	_connect_signals()
	_bind_theme_colors()
	ThemeManager.theme_changed.connect(_on_theme_changed)
	push_warning("[SudokuGame] _ready() complete, grid_control=%s, grid_size=%s" % [grid_control, grid_control.size])


func _exit_tree() -> void:
	# 清理所有信号连接，防止lambda泄漏
	if _dialog_tween and _dialog_tween.is_valid():
		_dialog_tween.kill()


func _bind_theme_colors() -> void:
	var primary := ThemeManager.get_color("primary")
	difficulty_label.add_theme_color_override("font_color", primary)
	undo_btn.modulate = primary
	hint_btn.modulate = primary
	pause_btn.modulate = primary


func _on_theme_changed(_name: String) -> void:
	bg.color = ThemeManager.get_color("background")
	var primary := ThemeManager.get_color("primary")
	difficulty_label.add_theme_color_override("font_color", primary)
	undo_btn.modulate = primary
	hint_btn.modulate = primary
	pause_btn.modulate = primary


func _connect_signals() -> void:
	var keyboard: NumberKeyboard = keyboard_node as NumberKeyboard
	keyboard.number_pressed.connect(_on_number_pressed)
	keyboard.clear_pressed.connect(_on_clear_pressed)
	keyboard.note_mode_toggled.connect(_on_note_mode_toggled)

	undo_btn.pressed.connect(_on_undo_pressed)
	hint_btn.pressed.connect(_on_hint_pressed)
	pause_btn.pressed.connect(_on_pause_pressed)
	resume_btn.pressed.connect(_on_resume_pressed)
	restart_btn.pressed.connect(_on_restart_pressed)
	main_menu_btn.pressed.connect(_on_main_menu_pressed)
	confirm_yes.pressed.connect(_on_confirm_yes)
	confirm_no.pressed.connect(_on_confirm_no)
	timer_toggle_btn.pressed.connect(_on_timer_toggle_pressed)
	auto_btn.pressed.connect(_on_auto_fill_pressed)

	easy_btn.pressed.connect(_on_difficulty_choice.bind(level - 1))
	same_btn.pressed.connect(_on_difficulty_choice.bind(level))
	hard_btn.pressed.connect(_on_difficulty_choice.bind(level + 1))


# --------------------------------------------------------------------------
# 弹窗 Tween 动画
# --------------------------------------------------------------------------

func _animate_dialog_show(panel: Panel) -> void:
	if _dialog_tween and _dialog_tween.is_valid():
		_dialog_tween.kill()
	_dialog_tween = DialogAnimator.show(panel, self)


func _animate_dialog_hide(panel: Panel) -> void:
	if _dialog_tween and _dialog_tween.is_valid():
		_dialog_tween.kill()
	_dialog_tween = DialogAnimator.hide(panel, self)


# --------------------------------------------------------------------------
# 游戏参数加载
# --------------------------------------------------------------------------

func _load_game_params() -> void:
	var params: Dictionary = SceneParams.get_param("next_game", {})
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

	SceneParams.set("next_game", {})


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED and not is_game_over:
		_on_pause_pressed()


func _start_new_game(lvl: int) -> void:
	level = clampi(lvl, 1, 16)
	push_warning("[SudokuGame] _start_new_game level=%d" % level)
	var puzzle := SudokuGenerator.generate(level)
	board.load_puzzle(puzzle.grid, puzzle.given, puzzle.solution)
	selected_row = -1
	selected_col = -1
	timer_controller.reset()
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
	timer_controller.elapsed_time = data.get("elapsed_time", 0.0)
	_streak_win_count = data.get("streak", 0)
	is_game_over = false
	is_paused = false
	_update_ui()


## 从历史记录重开：加载该局原始题目（board_snapshot 中的 given 和 solution）
func _load_history_puzzle(params: Dictionary) -> void:
	var snapshot: Dictionary = params.get("board_snapshot", {})
	if snapshot.is_empty():
		var lvl: int = params.get("level", 8)
		_start_new_game(lvl)
		return

	board.deserialize(snapshot)
	var history_lvl: int = params.get("level", 8)
	level = history_lvl
	selected_row = -1
	selected_col = -1
	timer_controller.reset()
	_streak_win_count = 0
	is_game_over = false
	is_paused = false
	for r in 9:
		for c in 9:
			if not board.given[r][c]:
				board.grid[r][c] = 0
				board.notes[r][c] = 0
	board.undo_stack.clear()
	board.hint_count = 0
	board.update_conflicts()
	_update_ui()


func _process(delta: float) -> void:
	timer_controller.tick(delta, is_paused, is_game_over)
	timer_label.text = timer_controller.get_formatted_time()


func _update_ui() -> void:
	push_warning("[SudokuGame] _update_ui: grid_control.queue_redraw() called, grid_control.size=%s" % grid_control.size)
	# 同步渲染状态
	render_state.grid = board.grid
	render_state.given = board.given
	render_state.notes = board.notes
	render_state.conflict = board.conflict
	render_state.selected_row = selected_row
	render_state.selected_col = selected_col

	difficulty_label.text = "难度 " + str(level)
	timer_label.text = timer_controller.get_formatted_time()
	hint_label.text = ""
	grid_control.queue_redraw()


# --------------------------------------------------------------------------
# 网格选中回调
# --------------------------------------------------------------------------

func _on_cell_selected(row: int, col: int) -> void:
	selected_row = row
	selected_col = col
	render_state.selected_row = row
	render_state.selected_col = col
	grid_control.queue_redraw()


## 切换计时标签显隐
func _on_timer_toggle_pressed() -> void:
	timer_label.visible = not timer_label.visible


# --------------------------------------------------------------------------
# 键盘输入
# --------------------------------------------------------------------------

func _on_number_pressed(num: int) -> void:
	if selected_row < 0 or is_paused or is_game_over:
		push_warning("[SudokuGame] _on_number_pressed(%d) blocked: selected=%d paused=%s game_over=%s" % [num, selected_row, is_paused, is_game_over])
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
		# 使用方法引用替代 lambda，避免信号泄漏
		get_tree().create_timer(2.0).timeout.connect(_clear_hint)
		grid_control.queue_redraw()
		if board.is_victory():
			_on_victory()
			return
		_auto_save()


# 提示反馈清理（独立方法，信号自动断开）
func _clear_hint() -> void:
	if is_instance_valid(hint_label):
		hint_label.text = ""


## 自动填充所有唯一候选格
func _on_auto_fill_pressed() -> void:
	if is_game_over or is_paused:
		return
	var count := board.auto_fill_singles()
	if count > 0:
		_auto_save()
		_update_ui()
		if board.is_victory():
			_on_victory()


func _on_pause_pressed() -> void:
	is_paused = true
	pause_overlay.show()
	_animate_dialog_show(pause_panel)


func _on_resume_pressed() -> void:
	is_paused = false
	_hide_confirm()
	_animate_dialog_hide(pause_panel)
	await get_tree().create_timer(0.12).timeout
	pause_overlay.hide()


func _on_restart_pressed() -> void:
	_pending_confirm = _do_restart
	_show_confirm("确定重新开始？\n当前进度将丢失。")


func _on_main_menu_pressed() -> void:
	_pending_confirm = _do_main_menu
	_show_confirm("返回主界面？\n游戏将自动保存当前进度。")


func _do_restart() -> void:
	_animate_dialog_hide(pause_panel)
	await get_tree().create_timer(0.12).timeout
	pause_overlay.hide()
	_streak_win_count = 0
	_start_new_game(level)


func _do_main_menu() -> void:
	pause_overlay.hide()
	SceneParams.set("next_game", {})
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
	confirm_btn_row.show()


func _hide_confirm() -> void:
	confirm_label.hide()
	confirm_yes.hide()
	confirm_no.hide()
	confirm_btn_row.hide()
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

	# 重新绑定难度按钮
	easy_btn.pressed.disconnect(_on_difficulty_choice)
	same_btn.pressed.disconnect(_on_difficulty_choice)
	hard_btn.pressed.disconnect(_on_difficulty_choice)
	easy_btn.pressed.connect(_on_difficulty_choice.bind(level - 1))
	same_btn.pressed.connect(_on_difficulty_choice.bind(level))
	hard_btn.pressed.connect(_on_difficulty_choice.bind(level + 1))

	v_time_label.text = "用时: " + TimerController.format_time(timer_controller.elapsed_time)
	v_hint_label.text = "提示次数: %d" % board.hint_count

	same_btn.grab_focus()

	if _streak_win_count > 0 and _streak_win_count % 5 == 0:
		v_streak_label.text = "连续通关 %d 局！试试更高难度？" % _streak_win_count
	elif _streak_win_count > 1:
		v_streak_label.text = "同难度连胜 %d 局" % (_streak_win_count - 1)
	else:
		v_streak_label.text = ""

	victory_overlay.show()
	# 通关弹窗动画：获取胜利面板节点
	var victory_panel := victory_overlay.get_node("Center/Popup") as Panel
	if victory_panel:
		_animate_dialog_show(victory_panel)


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
		"time": int(timer_controller.elapsed_time),
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
		"elapsed_time": timer_controller.elapsed_time,
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
