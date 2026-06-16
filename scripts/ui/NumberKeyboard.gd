class_name NumberKeyboard
extends Control
## NumberKeyboard — 数字键盘
## 底部 3×3 数字键 + 删除键 + 笔记模式切换
## 按钮在 _ready() 中动态创建

signal number_pressed(num: int)
signal clear_pressed()
signal note_mode_toggled(enabled: bool)

var is_note_mode: bool = false

@onready var number_grid: GridContainer = %NumberGrid
@onready var note_toggle: Button = %NoteToggle
@onready var clear_btn: Button = %ClearBtn


func _ready() -> void:
	# 动态创建 1-9 数字按钮
	for i in range(9):
		var btn := Button.new()
		btn.text = str(i + 1)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var num := i + 1
		btn.pressed.connect(_on_number_button_pressed.bind(num))
		number_grid.add_child(btn)

	note_toggle.toggled.connect(_on_note_toggle_pressed)
	clear_btn.pressed.connect(_on_clear_button_pressed)


func _on_number_button_pressed(num: int) -> void:
	number_pressed.emit(num)


func _on_clear_button_pressed() -> void:
	clear_pressed.emit()


func _on_note_toggle_pressed(toggled_on: bool) -> void:
	is_note_mode = toggled_on
	note_mode_toggled.emit(is_note_mode)
