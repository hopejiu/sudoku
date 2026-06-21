class_name NumberKeyboard
extends Control
## NumberKeyboard — 数字键盘
## 底部 3×3 数字键 + 删除键 + 笔记模式切换
## 按钮在 _ready() 中动态创建，使用 NumberKey 主题变体

signal number_pressed(num: int)
signal clear_pressed()
signal note_mode_toggled(enabled: bool)

var is_note_mode: bool = false
var note_toggle: Button
var clear_btn: Button

@onready var number_grid: GridContainer = %NumberGrid


func _ready() -> void:
	push_warning("[NumberKeyboard] _ready() called, number_grid=%s parent=%s" % [number_grid, get_parent()])
	# 动态创建 1-9 数字按钮（MD 风格 NumberKey）
	for i in range(9):
		var btn := Button.new()
		btn.text = str(i + 1)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		btn.theme_type_variation = &"NumberKey"
		btn.custom_minimum_size = Vector2(48, 48)
		var num := i + 1
		btn.pressed.connect(_on_number_button_pressed.bind(num))
		number_grid.add_child(btn)

	# 笔记/删除按钮放在 GridContainer 第 4 行（跟数字按钮统一尺寸）
	note_toggle = Button.new()
	note_toggle.text = "笔记"
	note_toggle.toggle_mode = true
	note_toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	note_toggle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	note_toggle.custom_minimum_size = Vector2(48, 48)
	note_toggle.theme_type_variation = &"FuncButton"
	note_toggle.toggled.connect(_on_note_toggle_pressed)
	number_grid.add_child(note_toggle)

	# 第 4 行中间留空（占位符，使 删除 位于 col 2）
	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_PASS
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	number_grid.add_child(spacer)

	clear_btn = Button.new()
	clear_btn.text = "  删除  "
	clear_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clear_btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	clear_btn.custom_minimum_size = Vector2(48, 48)
	clear_btn.theme_type_variation = &"FuncButton"
	clear_btn.pressed.connect(_on_clear_button_pressed)
	number_grid.add_child(clear_btn)

	push_warning("[NumberKeyboard] _ready(): created 9 number keys + note + spacer + clear, grid child_count=%d" % number_grid.get_child_count())

	# 主题颜色同步
	ThemeManager.theme_changed.connect(_on_theme_changed)
	_on_theme_changed(ThemeManager.current_theme_name)


func _on_theme_changed(_name: String) -> void:
	var primary := ThemeManager.get_color("primary")
	var disabled_color := Color("#94A3B8")

	# clear_btn 始终使用 primary 文字色
	clear_btn.add_theme_color_override("font_color", primary)
	clear_btn.add_theme_color_override("font_hover_color", primary)
	clear_btn.add_theme_color_override("font_pressed_color", primary)
	clear_btn.add_theme_color_override("font_disabled_color", disabled_color)

	# note_toggle 根据模式：开启时用 on_primary（白），关闭时用 primary
	_update_note_font_colors()


func _on_number_button_pressed(num: int) -> void:
	number_pressed.emit(num)


func _on_clear_button_pressed() -> void:
	clear_pressed.emit()


func _on_note_toggle_pressed(toggled_on: bool) -> void:
	is_note_mode = toggled_on
	note_mode_toggled.emit(is_note_mode)
	# 切换时更新按钮样式反馈
	if toggled_on:
		note_toggle.theme_type_variation = &"DialogAction"
	else:
		note_toggle.theme_type_variation = &"FuncButton"
	_update_note_font_colors()


## 根据 note_toggle 当前状态更新字体颜色
## 开启：使用 on_primary（白色，配合 DialogAction 深色背景）
## 关闭：使用 primary（配合 FuncButton 浅色背景）
func _update_note_font_colors() -> void:
	var primary := ThemeManager.get_color("primary")
	var on_primary := ThemeManager.get_color("on_primary")
	var disabled_color := Color("#94A3B8")
	var c := on_primary if is_note_mode else primary
	note_toggle.add_theme_color_override("font_color", c)
	note_toggle.add_theme_color_override("font_hover_color", c)
	note_toggle.add_theme_color_override("font_pressed_color", c)
	note_toggle.add_theme_color_override("font_disabled_color", disabled_color)
