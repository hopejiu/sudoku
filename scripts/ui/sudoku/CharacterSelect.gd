extends Control
## CharacterSelect — 角色选择界面
## 3 个角色卡片，点击选中后进入难度选择。

const SceneTransition := preload("res://scripts/ui/common/SceneTransition.gd")

var _selected_id: StringName = &""
var _card_buttons: Array[Button] = []

@onready var bg: ColorRect = %Bg
@onready var back_btn: Button = %BackBtn
@onready var card_container: VBoxContainer = %CardContainer
@onready var confirm_btn: Button = %ConfirmBtn
@onready var title_label: Label = %TitleLabel

@onready var difficulty_overlay: ColorRect = %DifficultyOverlay
@onready var diff_panel: Panel = %DiffPanel
@onready var diff_slider: HSlider = %DiffSlider
@onready var diff_value: Label = %DiffValue

var _dialog_tween: Tween = null


func _ready() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	confirm_btn.pressed.connect(_on_confirm_pressed)
	confirm_btn.disabled = true

	diff_slider.value_changed.connect(_on_difficulty_changed)
	diff_slider.min_value = 1
	diff_slider.max_value = 20
	diff_slider.value = 8
	_on_difficulty_changed(diff_slider.value)

	ThemeManager.theme_changed.connect(_on_theme_changed)
	_on_theme_changed(ThemeManager.current_theme_name)

	_build_cards()


func _on_theme_changed(_name: String) -> void:
	bg.color = ThemeManager.get_color("background")
	var primary := ThemeManager.get_color("primary")
	back_btn.modulate = primary
	confirm_btn.add_theme_color_override("font_color", primary)


func _build_cards() -> void:
	for child in card_container.get_children():
		child.queue_free()

	var char_ids := CharacterManager.get_all_char_ids()
	for cid in char_ids:
		var def := CharacterManager.get_char_def(cid)
		var card := _make_card(cid, def)
		card_container.add_child(card)


func _make_card(char_id: StringName, def: Dictionary) -> Button:
	var card := Button.new()
	card.custom_minimum_size = Vector2(0, 80)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.theme_type_variation = &"GameCard"
	card.toggle_mode = true

	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.mouse_filter = Control.MOUSE_FILTER_PASS
	hbox.add_theme_constant_override("separation", 16)

	# 头像（预留，加载失败用占位色块）
	var avatar := TextureRect.new()
	avatar.custom_minimum_size = Vector2(64, 64)
	avatar.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar.mouse_filter = Control.MOUSE_FILTER_PASS
	# 尝试加载头像资源
	var avatar_path: String = def.get("avatar", "")
	if avatar_path and ResourceLoader.exists(avatar_path):
		avatar.texture = ResourceLoader.load(avatar_path)
	else:
		# 无资源时用圆角色块占位
		avatar.modulate = ThemeManager.get_color("primary")
		avatar.mouse_filter = Control.MOUSE_FILTER_PASS
	hbox.add_child(avatar)

	# 文字信息
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.mouse_filter = Control.MOUSE_FILTER_PASS

	var name_label := Label.new()
	name_label.text = def.get("name", "?")
	name_label.theme_override_font_sizes/font_size = 20
	name_label.mouse_filter = Control.MOUSE_FILTER_PASS
	info.add_child(name_label)

	var skill_label := Label.new()
	var skill_name: String = def.get("skill_name", "")
	var skill_desc: String = def.get("skill_desc", "")
	skill_label.text = "【%s】%s" % [skill_name, skill_desc]
	skill_label.theme_override_font_sizes/font_size = 13
	skill_label.theme_override_colors/font_color = Color(0.5, 0.5, 0.5, 1)
	skill_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	skill_label.mouse_filter = Control.MOUSE_FILTER_PASS
	info.add_child(skill_label)

	hbox.add_child(info)
	card.add_child(hbox)

	card.pressed.connect(_on_card_pressed.bind(char_id, card))
	_card_buttons.append(card)

	# 如果已选中的角色，高亮
	if char_id == CharacterManager.current_char_id:
		card.button_pressed = true
		_selected_id = char_id
		confirm_btn.disabled = false

	return card


func _on_card_pressed(char_id: StringName, card: Button) -> void:
	# 取消其他选中
	for btn in _card_buttons:
		if btn != card:
			btn.button_pressed = false

	_selected_id = char_id
	confirm_btn.disabled = false


func _on_confirm_pressed() -> void:
	if _selected_id == &"":
		return
	CharacterManager.set_character(_selected_id)
	# 显示难度选择
	difficulty_overlay.show()
	_animate_show_dialog(diff_panel)


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


func _animate_show_dialog(panel: Panel) -> void:
	if _dialog_tween and _dialog_tween.is_valid():
		_dialog_tween.kill()
	_dialog_tween = DialogAnimator.show(panel, self)


func _animate_hide_dialog(panel: Panel) -> void:
	if _dialog_tween and _dialog_tween.is_valid():
		_dialog_tween.kill()
	_dialog_tween = DialogAnimator.hide(panel, self)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_back_pressed()


func _on_back_pressed() -> void:
	SceneTransition.change_to("res://scenes/sudoku/SudokuMenu.tscn")
