extends Panel
## SudokuCard — 游戏集合卡片
## 点击后导航到对应游戏的入口场景（SudokuMenu）

@onready var card_icon: TextureRect = %CardIcon


func _ready() -> void:
	card_icon.texture = preload("res://assets/icons/icon_sudoku.svg")
	ThemeManager.theme_changed.connect(_on_theme_changed)
	_on_theme_changed(ThemeManager.current_theme_name)


func _on_theme_changed(_theme_name: String) -> void:
	var primary := ThemeManager.get_color("primary")
	card_icon.modulate = primary


func _on_card_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_navigate_to_sudoku()


func _navigate_to_sudoku() -> void:
	get_tree().change_scene_to_file("res://scenes/sudoku/SudokuMenu.tscn")
