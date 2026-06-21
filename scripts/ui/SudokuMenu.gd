extends Control
## SudokuMenu — 数独选单场景
## 独立于主界面的数独入口，包含继续上局、新游戏、历史记录选项
## 从 SudokuCard 点击导航至此，完成选择后跳转 SudokuGame

const SceneTransition := preload("res://scripts/ui/SceneTransition.gd")

@onready var bg: ColorRect = %Bg
@onready var back_btn: Button = %BackBtn
@onready var continue_btn: Button = %ContinueBtn
@onready var new_game_btn: Button = %NewGameBtn
@onready var history_btn: Button = %HistoryBtn

@onready var difficulty_overlay: ColorRect = %DifficultyOverlay
@onready var diff_panel: Panel = %DiffPanel
@onready var diff_slider: HSlider = %DiffSlider
@onready var diff_value: Label = %DiffValue

var _dialog_tween: Tween = null


func _ready() -> void:
	# 检查队列是否有存档
	continue_btn.disabled = SaveManager.queue_is_empty()

	# 信号连接（TSCN 中已连接了部分，这里补运行时需要的）
	_on_difficulty_changed(diff_slider.value)

	# 主题绑定
	ThemeManager.theme_changed.connect(_on_theme_changed)
	_on_theme_changed(ThemeManager.current_theme_name)

	# 入场动画
	_animate_show()


func _exit_tree() -> void:
	if _dialog_tween and _dialog_tween.is_valid():
		_dialog_tween.kill()


func _on_theme_changed(_name: String) -> void:
	bg.color = ThemeManager.get_color("background")
	var primary := ThemeManager.get_color("primary")
	back_btn.modulate = primary


# --------------------------------------------------------------------------
# 动画
# --------------------------------------------------------------------------

func _animate_show() -> void:
	var card := %CardPanel as Panel
	if _dialog_tween and _dialog_tween.is_valid():
		_dialog_tween.kill()
	_dialog_tween = DialogAnimator.show(card, self)


func _animate_show_dialog(panel: Panel) -> void:
	if _dialog_tween and _dialog_tween.is_valid():
		_dialog_tween.kill()
	_dialog_tween = DialogAnimator.show(panel, self)


func _animate_hide_dialog(panel: Panel) -> void:
	if _dialog_tween and _dialog_tween.is_valid():
		_dialog_tween.kill()
	_dialog_tween = DialogAnimator.hide(panel, self)


# --------------------------------------------------------------------------
# 导航
# --------------------------------------------------------------------------

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		SceneTransition.change_to("res://scenes/main/Main.tscn")


func _on_back_pressed() -> void:
	SceneTransition.change_to("res://scenes/main/Main.tscn")


func _on_continue_pressed() -> void:
	SceneParams.set_param("next_game", {"action": "continue"})
	SceneTransition.change_to("res://scenes/sudoku/SudokuLoading.tscn")


func _on_new_game_pressed() -> void:
	difficulty_overlay.show()
	_animate_show_dialog(diff_panel)


func _on_history_pressed() -> void:
	SceneTransition.change_to("res://scenes/sudoku/HistoryList.tscn")


# --------------------------------------------------------------------------
# 难度选择
# --------------------------------------------------------------------------

func _on_difficulty_changed(value: float) -> void:
	diff_value.text = str(int(value))


func _on_diff_confirm_pressed() -> void:
	var lvl := int(diff_slider.value)
	SceneParams.set_param("next_game", {"action": "new", "level": lvl})
	SceneTransition.change_to("res://scenes/sudoku/SudokuLoading.tscn")


func _on_diff_cancel_pressed() -> void:
	_animate_hide_dialog(diff_panel)
	await get_tree().create_timer(0.12).timeout
	difficulty_overlay.hide()
