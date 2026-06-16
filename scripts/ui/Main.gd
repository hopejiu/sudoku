extends Control
## Main — 主界面脚本
## 游戏集合首页，显示游戏卡片列表，弹出菜单、难度选择

@onready var sudoku_card: Panel = %SudokuCard
@onready var card_icon: TextureRect = %CardIcon

@onready var popup_overlay: ColorRect = %PopupOverlay
@onready var continue_btn: Button = %ContinueBtn
@onready var new_game_btn: Button = %NewGameBtn
@onready var history_btn: Button = %HistoryBtn

@onready var difficulty_overlay: ColorRect = %DifficultyOverlay
@onready var diff_slider: HSlider = %DiffSlider
@onready var diff_value: Label = %DiffValue
@onready var diff_confirm: Button = %DiffConfirm
@onready var diff_cancel: Button = %DiffCancel

@onready var settings_btn: Button = %SettingsBtn


func _ready() -> void:
	# 检测是否有未完成游戏
	var saved := SaveManager.load_current_game()
	continue_btn.disabled = saved.is_empty()

	# 数独卡片图标
	card_icon.texture = preload("res://assets/icons/icon_sudoku.svg")

	# 主题颜色绑定
	ThemeManager.theme_changed.connect(_on_theme_changed)
	_on_theme_changed(ThemeManager.current_theme_name)

	# 信号连接
	sudoku_card.gui_input.connect(_on_card_input)
	continue_btn.pressed.connect(_on_continue_pressed)
	new_game_btn.pressed.connect(_on_new_game_pressed)
	history_btn.pressed.connect(_on_history_pressed)
	diff_slider.value_changed.connect(_on_difficulty_changed)
	diff_confirm.pressed.connect(_on_diff_confirm_pressed)
	diff_cancel.pressed.connect(_on_diff_cancel_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)

	_on_difficulty_changed(diff_slider.value)


func _on_theme_changed(theme_name: String) -> void:
	var primary := ThemeManager.get_color("primary")
	card_icon.modulate = primary


# --------------------------------------------------------------------------
# 卡片点击
# --------------------------------------------------------------------------

func _on_card_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		popup_overlay.visible = not popup_overlay.visible


# --------------------------------------------------------------------------
# 弹出菜单按钮
# --------------------------------------------------------------------------

func _on_continue_pressed() -> void:
	popup_overlay.hide()
	SaveManager.set_temp("next_game", {"action": "continue"})
	get_tree().change_scene_to_file("res://scenes/sudoku/SudokuGame.tscn")


func _on_new_game_pressed() -> void:
	popup_overlay.hide()
	difficulty_overlay.show()


func _on_history_pressed() -> void:
	popup_overlay.hide()
	get_tree().change_scene_to_file("res://scenes/sudoku/HistoryList.tscn")


# --------------------------------------------------------------------------
# 难度选择
# --------------------------------------------------------------------------

func _on_difficulty_changed(value: float) -> void:
	diff_value.text = str(int(value))


func _on_diff_confirm_pressed() -> void:
	var lvl := int(diff_slider.value)
	SaveManager.set_temp("next_game", {"action": "new", "level": lvl})
	get_tree().change_scene_to_file("res://scenes/sudoku/SudokuGame.tscn")


func _on_diff_cancel_pressed() -> void:
	difficulty_overlay.hide()
	popup_overlay.show()


# --------------------------------------------------------------------------
# 设置（主题切换）
# --------------------------------------------------------------------------

func _on_settings_pressed() -> void:
	if ThemeManager.current_theme_name == "classic":
		ThemeManager.set_theme("purple_light")
	else:
		ThemeManager.set_theme("classic")
