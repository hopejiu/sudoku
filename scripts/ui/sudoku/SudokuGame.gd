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
## 玩家等级/经验/积分由 PlayerManager Autoload 管理。

const SceneTransition := preload("res://scripts/ui/common/SceneTransition.gd")

var _status_display: StatusDisplay

var board: SudokuBoard
var render_state := GridRenderState.new()
var timer_controller := TimerController.new()

var selected_row: int = -1
var selected_col: int = -1
var is_note_mode: bool = false
var is_paused: bool = false
var level: int = 8  # 游戏难度 1~16
var is_game_over: bool = false

# 同难度连胜计数，达到 5 的倍数时触发鼓励
var _streak_win_count: int = 0

# 各数字已填入数量（1-9），用于键盘高亮
var _number_count: Array[int] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

# 标志位：是否正在队列填充
var _queue_refilling: bool = false

# 道具面板展开状态
var _items_panel_visible: bool = false

# 升级跟踪
var _leveled_up_this_round: bool = false
var _pending_next_game: Dictionary = {}

# ---- 角色技能状态（委托 SkillBase） ----
var _char_id: StringName = &""
var _skill: SkillBase = null

@onready var bg: ColorRect = %Bg
@onready var difficulty_label: Label = %DifficultyLabel
@onready var timer_label: Label = %TimerLabel
@onready var hint_label: Label = %HintLabel
@onready var undo_btn: Button = %UndoBtn
@onready var hint_btn: Button = %HintBtn
@onready var hint_count_badge: Label = %HintBtn/HintCount
@onready var pause_btn: Button = %PauseBtn
@onready var grid_control: Control = %Grid
@onready var keyboard_node: Node = %NumberKeyboard
@onready var timer_toggle_btn: Button = %TimerToggleBtn
@onready var items_btn: Button = %ItemsBtn
@onready var items_panel: Control = %ItemsPanel
@onready var char_panel: Control = %CharacterPanel
@onready var portrait_rect: TextureRect = %PortraitRect
@onready var char_name_label: Label = %CharNameLabel
@onready var speech_bubble: Label = %SpeechBubble
@onready var skill_name_label: Label = %SkillNameLabel
@onready var combo_dots: HBoxContainer = %ComboDots
@onready var magnifier_btn: Button = %MagnifierBtn
@onready var bomb_btn: Button = %BombBtn
@onready var item_coins_label: Label = %ItemCoinsLabel

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
@onready var v_xp_label: Label = %VXpLabel
@onready var v_coins_label: Label = %VCoinsLabel
@onready var easy_btn: Button = %EasyBtn
@onready var same_btn: Button = %SameBtn
@onready var hard_btn: Button = %HardBtn

@onready var level_up_overlay: ColorRect = %LevelUpOverlay
@onready var lu_level_label: Label = %LuLevelLabel
@onready var lu_ok_btn: Button = %LuOkBtn

# 缓存的 Tween 引用，防止多个 Tween 冲突
var _dialog_tween: Tween = null


func _ready() -> void:
	push_warning("[SudokuGame] _ready() called")
	var data := SaveManager.load_current_game()
	if data.is_empty():
		push_warning("[SudokuGame] no saved data, redirecting to loading")
		SceneTransition.change_to("res://scenes/sudoku/SudokuLoading.tscn")
		return

	board = SudokuBoard.new()
	var grid: SudokuGrid = grid_control as SudokuGrid
	grid.render_state = render_state
	grid.cell_selected.connect(_on_cell_selected)
	grid.bomb_target_selected.connect(_on_bomb_target_selected)
	_connect_signals()
	_restore_from_save(data)
	ThemeManager.theme_changed.connect(_apply_theme_colors)
	_apply_theme_colors()

	# 初始化状态显示服务 + 键盘盘面引用
	_status_display = StatusDisplay.new()
	_status_display.setup(hint_label)

	# 初始化角色展示 + 技能
	_char_id = CharacterManager.current_char_id
	_skill = CharacterManager.create_skill()
	CharacterManager.load_dialogue()
	_init_character_display()
	# 开场台词（延迟一下等 UI 稳定）
	get_tree().create_timer(0.5).timeout.connect(func(): _show_dialogue("game_start"))

	push_warning("[SudokuGame] _ready() complete")


func _exit_tree() -> void:
	if _dialog_tween and _dialog_tween.is_valid():
		_dialog_tween.kill()


func _apply_theme_colors() -> void:
	bg.color = ThemeManager.get_color("background")
	var primary := ThemeManager.get_color("primary")
	difficulty_label.add_theme_color_override("font_color", primary)
	undo_btn.modulate = primary
	hint_btn.modulate = primary
	pause_btn.modulate = primary
	timer_toggle_btn.modulate = primary
	items_btn.modulate = primary


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

	items_btn.pressed.connect(_on_items_btn_pressed)
	magnifier_btn.pressed.connect(_on_magnifier_pressed)
	bomb_btn.pressed.connect(_on_bomb_pressed)
	lu_ok_btn.pressed.connect(_on_level_up_ok)

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

func _restore_from_save(data: Dictionary) -> void:
	board.deserialize(data.get("board", {}))
	level = data.get("level", 8)
	timer_controller.elapsed_time = data.get("elapsed_time", 0.0)
	_streak_win_count = data.get("streak", 0)
	# 恢复本局提示加成（放大镜效果）
	PlayerManager.reset_game_bonus()
	var saved_bonus: int = data.get("hint_bonus", 0)
	if saved_bonus > 0:
		PlayerManager.set_hint_bonus(saved_bonus)
	board.hint_cap = PlayerManager.get_hint_cap(PlayerManager.level)
	selected_row = -1
	selected_col = -1
	is_game_over = false
	is_paused = false
	_count_numbers()
	_update_ui()
	# 触发后台队列填充
	var queue := SaveManager.load_queue()
	var needed := 3 - queue.size()
	_queue_refilling = not GameQueueManager.ensure_filled(level, max(1, needed))
	_items_panel_visible = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED and not is_game_over:
		_on_pause_pressed()
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if is_paused and confirm_btn_row.visible:
			_on_confirm_no()
		elif not is_paused and not is_game_over:
			_on_pause_pressed()
		elif is_paused:
			_on_main_menu_pressed()


func _process(delta: float) -> void:
	timer_controller.tick(delta, is_paused, is_game_over)
	timer_label.text = timer_controller.get_formatted_time()

	if _queue_refilling and GameQueueManager.poll_generation():
		_queue_refilling = false


func _update_ui() -> void:
	render_state.grid = board.grid
	render_state.given = board.given
	render_state.notes = board.notes
	render_state.conflict = board.conflict
	render_state.selected_row = selected_row
	render_state.selected_col = selected_col

	difficulty_label.text = "难度 " + str(level)
	timer_label.text = timer_controller.get_formatted_time()
	_status_display.clear()

	# 提示按钮徽章：显示剩余次数
	var remaining := maxi(0, board.hint_cap - board.hint_count)
	var is_unlimited := board.hint_cap >= 999
	hint_count_badge.text = str(remaining)
	hint_count_badge.visible = not is_unlimited
	hint_btn.disabled = (board.hint_count >= board.hint_cap)

	# 道具面板：更新可用数量
	magnifier_btn.text = "×" + str(PlayerManager.get_item_count(&"magnifier"))
	bomb_btn.text = "×" + str(PlayerManager.get_item_count(&"bomb"))
	item_coins_label.text = "积分: %d" % PlayerManager.coins

	grid_control.queue_redraw()


# --------------------------------------------------------------------------
# 网格选中回调
# --------------------------------------------------------------------------

func _on_cell_selected(row: int, col: int) -> void:
	var prev_row := selected_row
	var prev_col := selected_col
	selected_row = row
	selected_col = col
	render_state.selected_row = row
	render_state.selected_col = col
	# 技能委托
	if _skill:
		var result := _skill.on_cell_selected(board, row, col, prev_row, prev_col)
		_apply_skill_result(result)
	grid_control.queue_redraw()


func _count_numbers() -> void:
	_number_count = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	for r in 9:
		for c in 9:
			var v: int = board.grid[r][c]
			if v > 0:
				_number_count[v] += 1
	(keyboard_node as NumberKeyboard).update_number_counts(_number_count)


func _on_timer_toggle_pressed() -> void:
	timer_label.visible = not timer_label.visible


# --------------------------------------------------------------------------
# 角色展示
# --------------------------------------------------------------------------

## 初始化角色立绘/头像/名称（资源缺失时静默跳过）
func _init_character_display() -> void:
	var def := CharacterManager.get_current_def()
	char_name_label.text = def.get("name", "")

	# 显示技能名称
	var skill_name: String = def.get("skill_name", "")
	var skill_desc: String = def.get("skill_desc", "")
	skill_name_label.text = "%s: %s" % [skill_name, skill_desc]

	# 角色C显示连击圆点，其他隐藏
	combo_dots.visible = (_char_id == &"char_c")
	_reset_combo_dots()

	# 加载立绘
	var portrait_path: String = def.get("portrait", "")
	if portrait_path and ResourceLoader.exists(portrait_path):
		var tex := ResourceLoader.load(portrait_path)
		if tex:
			portrait_rect.texture = tex
	# 加载失败则留空色块，不崩溃


## 在气泡中显示角色台词（资源缺失时静默跳过）
func _show_dialogue(trigger_id: String) -> void:
	var line := CharacterManager.get_random_line(_char_id, trigger_id)
	if line.is_empty():
		return
	speech_bubble.text = line
	speech_bubble.modulate = Color(1, 1, 1, 0)
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(speech_bubble, "modulate", Color.WHITE, 0.3)
	# 3 秒后淡出
	get_tree().create_timer(3.0).timeout.connect(_clear_speech)


func _clear_speech() -> void:
	if is_instance_valid(speech_bubble):
		var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(speech_bubble, "modulate:a", 0.0, 0.5)


# --------------------------------------------------------------------------
# 键盘输入
# --------------------------------------------------------------------------

func _on_number_pressed(num: int) -> void:
	if selected_row < 0 or is_paused or is_game_over:
		return
	if is_note_mode:
		board.toggle_note(selected_row, selected_col, num)
		return
	var old_val: int = board.grid[selected_row][selected_col]
	if old_val != num:
		var is_correct: bool = (board.solution.size() > 0 and board.solution[selected_row][selected_col] == num)
		board.set_cell(selected_row, selected_col, num)
		(grid_control as SudokuGrid).trigger_pulse(selected_row, selected_col)
		if old_val > 0:
			_number_count[old_val] -= 1
		if num > 0:
			_number_count[num] += 1
		(keyboard_node as NumberKeyboard).update_number_counts(_number_count)

		# 对话
		if is_correct:
			_show_dialogue("number_placed")
		else:
			_show_dialogue("number_conflict")

		# 技能委托
		if _skill:
			var result := _skill.on_number_placed(board, selected_row, selected_col, num, old_val)
			_apply_skill_result(result)

		if board.is_victory():
			_on_victory()
			return

	grid_control.queue_redraw()
	_auto_save()

	if old_val == num and old_val > 0:
		_show_dialogue("cell_already_filled")


## 将技能/道具的返回结果应用为 UI 效果
func _apply_skill_result(result: Dictionary) -> void:
	if result.is_empty():
		return

	# 揭示格子
	var reveal: Dictionary = result.get("reveal", {})
	if reveal.has("r") and reveal.has("c"):
		var r: int = reveal.r
		var c: int = reveal.c
		var correct: int = board.solution[r][c] if board.solution.size() > 0 else 0
		if correct > 0:
			board.grid[r][c] = correct
		board.update_conflicts()
		(grid_control as SudokuGrid).trigger_pulse(r, c)
		var grid_ctrl := grid_control as SudokuGrid
		# 连线动画
		var from: Dictionary = result.get("reveal_from", {})
		if from.has("r") and from.has("c"):
			grid_ctrl.trigger_reveal_line(from.r, from.c, r, c)
		grid_ctrl.trigger_reveal_highlight(r, c)

	# 文本
	var status_text: String = result.get("hint_text", "")
	if status_text:
		_status_display.show(status_text, 2.0)

	# 对话
	var dialogue: String = result.get("dialogue", "")
	if dialogue:
		_show_dialogue(dialogue)

	# 闪光
	if result.get("flash", false):
		(grid_control as SudokuGrid).trigger_flash()

	# 禁用键（角色B）
	var disable_keys: Array = result.get("disable_keys", [])
	if disable_keys != null:
		var keyboard: NumberKeyboard = keyboard_node as NumberKeyboard
		var counts := _number_count.duplicate()
		for n in disable_keys:
			if counts[n] < 9:
				counts[n] = 9  # 标记禁用
		if disable_keys.is_empty():
			keyboard.update_number_counts(_number_count)
		else:
			keyboard.update_number_counts(counts)

	# Combo
	var combo_count: int = result.get("combo_count", -1)
	if combo_count >= 0:
		_update_combo_dots(combo_count)
	if result.get("combo_reset", false):
		_reset_combo_dots()

	# 提示加成
	var hint_bonus: int = result.get("hint_bonus", 0)
	if hint_bonus > 0:
		PlayerManager.set_hint_bonus(PlayerManager.get_hint_bonus() + hint_bonus)
		board.hint_cap = PlayerManager.get_hint_cap(PlayerManager.level)

	# 炸弹特效（由 SudokuGame 触发 UI 特效，不是由这里重复触发）
	# bomb_effect 仅供传递坐标信息，实际 trigger_bomb_effect 已在 _on_bomb_target_selected 中调用

	# 重新计数
	_count_numbers()
	(keyboard_node as NumberKeyboard).update_number_counts(_number_count)
	grid_control.queue_redraw()
	_auto_save()

	if board.is_victory():
		_on_victory()


## 更新连击圆点
func _update_combo_dots(count: int) -> void:
	for i in range(5):
		var dot := combo_dots.get_child(i) as ColorRect if i < combo_dots.get_child_count() else null
		if dot:
			var c := ThemeManager.get_color("primary") if i < count else Color(0.8, 0.8, 0.8, 0.3)
			dot.color = c


## 重置连击圆点
func _reset_combo_dots() -> void:
	for i in range(5):
		var dot := combo_dots.get_child(i) as ColorRect if i < combo_dots.get_child_count() else null
		if dot:
			dot.color = Color(0.8, 0.8, 0.8, 0.3)


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
	if _skill:
		var result := _skill.on_undo(board)
		_apply_skill_result(result)
	grid_control.queue_redraw()
	_auto_save()


func _on_hint_pressed() -> void:
	if is_game_over:
		return
	if board.hint_count >= board.hint_cap:
		return  # 已达上限
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
		var result := board.get_hint(r, c)
		if result <= 0:
			return  # 无提示可达或已达上限
		(grid_control as SudokuGrid).trigger_pulse(r, c)
		_count_numbers()
		(keyboard_node as NumberKeyboard).update_number_counts(_number_count)
		_status_display.show("提示 %d / %d 次" % [board.hint_count, board.hint_cap], 2.0)
		grid_control.queue_redraw()
		if board.is_victory():
			_on_victory()
			return
		_auto_save()
	_update_ui()


func _clear_hint() -> void:
	_status_display.clear()


# --------------------------------------------------------------------------
# 道具系统
# --------------------------------------------------------------------------

func _on_items_btn_pressed() -> void:
	_items_panel_visible = not _items_panel_visible
	items_panel.visible = _items_panel_visible
	if _items_panel_visible:
		_update_ui()


func _on_magnifier_pressed() -> void:
	if is_game_over or is_paused:
		return
	if not items_panel.visible:
		return
	if PlayerManager.get_item_count(&"magnifier") <= 0:
		return

	# 使用暂停弹窗进行确认
	items_panel.visible = false
	_items_panel_visible = false
	DialogAnimator.show_overlay(pause_overlay, self)
	_animate_dialog_show(pause_panel)
	_pending_confirm = _use_magnifier
	_show_confirm("使用放大镜？\n增加本局提示上限 +1（剩余 %d 个）" % PlayerManager.get_item_count(&"magnifier"))


func _use_magnifier() -> void:
	if not PlayerManager.remove_item(&"magnifier"):
		return
	var item := PlayerManager.create_item(&"magnifier")
	if item:
		var result := item.use(board, selected_row, selected_col)
		_animate_dialog_hide(pause_panel)
		await get_tree().create_timer(0.12).timeout
		DialogAnimator.hide_overlay(pause_overlay, self)
		_apply_skill_result(result)
	_update_ui()


func _on_bomb_pressed() -> void:
	if is_game_over or is_paused:
		return
	if not items_panel.visible:
		return
	if PlayerManager.get_item_count(&"bomb") <= 0:
		return
	if selected_row < 0 or selected_col < 0:
		_status_display.show("请先选中一个格子来选择宫！", 2.0)
		return

	# 进入炸弹瞄准模式
	(grid_control as SudokuGrid).enter_bomb_mode()
	_status_display.show("拖动选择要揭露的 3×3 宫", 0, _status_display.Priority.HIGH)
	items_panel.visible = false
	_items_panel_visible = false


func _on_bomb_target_selected(box_row: int, box_col: int) -> void:
	if not PlayerManager.remove_item(&"bomb"):
		return
	var item := PlayerManager.create_item(&"bomb")
	if item:
		var result := item.use(board, 0, 0, {"box_row": box_row, "box_col": box_col})
		_apply_skill_result(result)
	# 炸弹特效在业务逻辑之后由 _apply_skill_result 的 bomb_effect 触发
	(grid_control as SudokuGrid).trigger_bomb_effect(box_row, box_col)
	_update_ui()
	_auto_save()
	if board.is_victory():
		_on_victory()


# --------------------------------------------------------------------------
# 暂停/确认
# --------------------------------------------------------------------------

func _on_pause_pressed() -> void:
	is_paused = true
	if items_panel.visible:
		items_panel.visible = false
		_items_panel_visible = false
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
	# 如果不在暂停模式（道具确认弹窗），关闭遮罩
	if not is_paused:
		_animate_dialog_hide(pause_panel)
		await get_tree().create_timer(0.12).timeout
		DialogAnimator.hide_overlay(pause_overlay, self)


# --------------------------------------------------------------------------
# 通关
# --------------------------------------------------------------------------

func _on_victory() -> void:
	_show_dialogue("victory")
	is_game_over = true
	_record_history()
	SaveManager.queue_pop_front()

	_streak_win_count += 1

	# ---- 发放奖励 ----
	var reward_xp: int = level + 10
	var reward_coins: int = level + 10
	PlayerManager.add_coins(reward_coins)
	var leveled_up := PlayerManager.add_xp(reward_xp)
	PlayerManager.save()  # 持久化玩家数据
	_leveled_up_this_round = leveled_up
	_pending_next_game = {}

	# ---- 通关弹窗 UI ----
	var level_up := level < 20
	var level_down := level > 1

	easy_btn.disabled = not level_down
	hard_btn.disabled = not level_up
	same_btn.disabled = false

	same_btn.theme_type_variation = &"PrimaryAction"
	easy_btn.theme_type_variation = &"DialogAction"
	hard_btn.theme_type_variation = &"DialogAction"

	easy_btn.pressed.disconnect(_on_difficulty_choice)
	same_btn.pressed.disconnect(_on_difficulty_choice)
	hard_btn.pressed.disconnect(_on_difficulty_choice)
	easy_btn.pressed.connect(_on_difficulty_choice.bind(level - 1))
	same_btn.pressed.connect(_on_difficulty_choice.bind(level))
	hard_btn.pressed.connect(_on_difficulty_choice.bind(level + 1))

	v_time_label.text = "用时: " + TimerController.format_time(timer_controller.elapsed_time)
	v_hint_label.text = "提示: %d / %d" % [board.hint_count, board.hint_cap]
	v_xp_label.text = "+%d 经验" % reward_xp
	v_coins_label.text = "+%d 积分" % reward_coins

	same_btn.grab_focus()

	if _streak_win_count > 0 and _streak_win_count % 5 == 0:
		v_streak_label.text = "连续通关 %d 局！试试更高难度？" % _streak_win_count
	elif _streak_win_count > 1:
		v_streak_label.text = "同难度连胜 %d 局" % (_streak_win_count - 1)
	else:
		v_streak_label.text = ""

	# 撒花效果
	var confetti := ConfettiEffect.new()
	victory_overlay.add_child(confetti)

	DialogAnimator.show_overlay(victory_overlay, self)
	var victory_panel := victory_overlay.get_node("Center/Popup") as Panel
	if victory_panel:
		_animate_dialog_show(victory_panel)


func _on_difficulty_choice(new_level: int) -> void:
	new_level = clampi(new_level, 1, 20)
	victory_overlay.hide()

	if _leveled_up_this_round:
		_leveled_up_this_round = false
		_pending_next_game = {"action": "new", "level": new_level}
		_show_level_up()
		return

	SceneParams.set_param("next_game", {"action": "new", "level": new_level})
	SceneTransition.change_to("res://scenes/sudoku/SudokuLoading.tscn")


## 升级通知弹窗（由通关弹窗选择后触发）
func _show_level_up() -> void:
	lu_level_label.text = "恭喜升级！\n当前等级: %d" % PlayerManager.level
	DialogAnimator.show_overlay(level_up_overlay, self)
	var panel := level_up_overlay.get_node("Center/Panel") as Panel
	if panel:
		_animate_dialog_show(panel)


func _on_level_up_ok() -> void:
	var panel := level_up_overlay.get_node("Center/Panel") as Panel
	if panel:
		_animate_dialog_hide(panel)
	await get_tree().create_timer(0.12).timeout
	DialogAnimator.hide_overlay(level_up_overlay, self)

	if not _pending_next_game.is_empty():
		var params: Dictionary = _pending_next_game
		_pending_next_game = {}
		SceneParams.set_param("next_game", params)
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
		"hint_bonus": PlayerManager.get_hint_bonus(),
	}
	SaveManager.queue_set_front(data)
