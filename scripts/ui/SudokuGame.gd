class_name SudokuGame
extends Control
## SudokuGame — 数独游戏主脚本
##
## 编排层，协调各子模块：
## - TimerController：计时
## - GridRenderState：网格渲染数据
## - DialogAnimator：弹窗动画（静态方法调用）
## - SceneParams：场景参数传递
##
## 后台队列生成由 GameQueueManager Autoload 统一管理。

const SceneTransition := preload("res://scripts/ui/SceneTransition.gd")

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

# 各数字已填入数量（1-9），用于键盘高亮
var _number_count: Array[int] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

# 标志位：首次布局完成
var _ready_called := false

# 标志位：是否正在队列填充
var _queue_refilling: bool = false

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
	var data := SaveManager.load_current_game()
	if data.is_empty():
		# 没有存档数据，重定向到加载页面
		push_warning("[SudokuGame] no saved data, redirecting to loading")
		SceneTransition.change_to("res://scenes/sudoku/SudokuLoading.tscn")
		return

	board = SudokuBoard.new()
	var grid: SudokuGrid = grid_control as SudokuGrid
	grid.render_state = render_state
	grid.cell_selected.connect(_on_cell_selected)
	_connect_signals()
	_restore_from_save(data)
	ThemeManager.theme_changed.connect(_apply_theme_colors)
	_apply_theme_colors()
	_ready_called = true
	push_warning("[SudokuGame] _ready() complete, grid_control=%s, grid_size=%s" % [grid_control, grid_control.size])


func _exit_tree() -> void:
	# 清理所有信号连接，防止lambda泄漏
	if _dialog_tween and _dialog_tween.is_valid():
		_dialog_tween.kill()


func _apply_theme_colors() -> void:
	## U1 优化：合并 _bind_theme_colors 与 _on_theme_changed，消除重复
	bg.color = ThemeManager.get_color("background")
	var primary := ThemeManager.get_color("primary")
	difficulty_label.add_theme_color_override("font_color", primary)
	undo_btn.modulate = primary
	hint_btn.modulate = primary
	pause_btn.modulate = primary
	timer_toggle_btn.modulate = primary
	auto_btn.modulate = primary


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
# 游戏加载
# --------------------------------------------------------------------------

## 从 current.save 恢复游戏状态
func _restore_from_save(data: Dictionary) -> void:
	board.deserialize(data.get("board", {}))
	level = data.get("level", 8)
	timer_controller.elapsed_time = data.get("elapsed_time", 0.0)
	_streak_win_count = data.get("streak", 0)
	selected_row = -1
	selected_col = -1
	is_game_over = false
	is_paused = false
	_count_numbers()
	_update_ui()
	# 触发后台队列填充（由 GameQueueManager 统一管理，维持队列至 MAX_QUEUE_SIZE）
	var queue := SaveManager.load_queue()
	var needed := 3 - queue.size()
	_queue_refilling = not GameQueueManager.ensure_filled(level, max(1, needed))


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED and not is_game_over:
		_on_pause_pressed()
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if is_paused and confirm_btn_row.visible:
			# 确认框可见 → 取消确认（相当于按取消）
			_on_confirm_no()
		elif not is_paused and not is_game_over:
			# 游戏进行中 → 暂停
			_on_pause_pressed()
		elif is_paused:
			# 已暂停 → 返回主界面（带确认）
			_on_main_menu_pressed()


func _process(delta: float) -> void:
	timer_controller.tick(delta, is_paused, is_game_over)
	timer_label.text = timer_controller.get_formatted_time()

	# 检查 GameQueueManager 后台队列填充完成
	if _queue_refilling and GameQueueManager.poll_generation():
		_queue_refilling = false


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


## 统计盘面上每个数字的出现次数（用于键盘高亮）
func _count_numbers() -> void:
	_number_count = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	for r in 9:
		for c in 9:
			var v: int = board.grid[r][c]
			if v > 0:
				_number_count[v] += 1
	(keyboard_node as NumberKeyboard).update_number_counts(_number_count)


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
		var old_val: int = board.grid[selected_row][selected_col]
		board.set_cell(selected_row, selected_col, num)
		if old_val != num:
			# 触发脉冲反馈
			(grid_control as SudokuGrid).trigger_pulse(selected_row, selected_col)
			# 更新数字计数
			if old_val > 0:
				_number_count[old_val] -= 1
			if num > 0:
				_number_count[num] += 1
			# 同步键盘高亮
			(keyboard_node as NumberKeyboard).update_number_counts(_number_count)
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
		var old_val: int = board.grid[selected_row][selected_col]
		board.set_cell(selected_row, selected_col, 0)
		if old_val > 0:
			_number_count[old_val] -= 1
			(keyboard_node as NumberKeyboard).update_number_counts(_number_count)
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
	_count_numbers()
	(keyboard_node as NumberKeyboard).update_number_counts(_number_count)
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
		# 提示时脉冲反馈 + 计数更新
		(grid_control as SudokuGrid).trigger_pulse(r, c)
		_count_numbers()
		(keyboard_node as NumberKeyboard).update_number_counts(_number_count)
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
		_count_numbers()
		(keyboard_node as NumberKeyboard).update_number_counts(_number_count)
		_auto_save()
		_update_ui()
		if board.is_victory():
			_on_victory()


func _on_pause_pressed() -> void:
	is_paused = true
	DialogAnimator.show_overlay(pause_overlay, self)
	_animate_dialog_show(pause_panel)


func _on_resume_pressed() -> void:
	is_paused = false
	_hide_confirm()
	_animate_dialog_hide(pause_panel)
	await get_tree().create_timer(0.12).timeout
	DialogAnimator.hide_overlay(pause_overlay, self)


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
	SaveManager.queue_pop_front()
	SceneParams.set_param("next_game", {"action": "new", "level": level})
	SceneTransition.change_to("res://scenes/sudoku/SudokuLoading.tscn")


func _do_main_menu() -> void:
	pause_overlay.hide()
	SceneParams.set("next_game", {})
	SceneTransition.change_to("res://scenes/main/Main.tscn")


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
	SaveManager.queue_pop_front()

	_streak_win_count += 1

	var level_up := level < 16
	var level_down := level > 1

	easy_btn.disabled = not level_down
	hard_btn.disabled = not level_up
	same_btn.disabled = false

	# 主按钮（维持难度）与其他按钮视觉区分
	same_btn.theme_type_variation = &"PrimaryAction"
	easy_btn.theme_type_variation = &"DialogAction"
	hard_btn.theme_type_variation = &"DialogAction"

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

	# 撒花庆祝效果（作为 victory_overlay 的子节点，确保渲染在弹窗上方，C4 修复）
	var confetti := ConfettiEffect.new()
	victory_overlay.add_child(confetti)

	# 通关弹窗动画
	DialogAnimator.show_overlay(victory_overlay, self)
	var victory_panel := victory_overlay.get_node("Center/Popup") as Panel
	if victory_panel:
		_animate_dialog_show(victory_panel)


func _on_difficulty_choice(new_level: int) -> void:
	new_level = clampi(new_level, 1, 16)
	victory_overlay.hide()
	# 通关时已弹出队首，直接跳转加载页
	SceneParams.set_param("next_game", {"action": "new", "level": new_level})
	SceneTransition.change_to("res://scenes/sudoku/SudokuLoading.tscn")


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
	SaveManager.queue_set_front(data)
