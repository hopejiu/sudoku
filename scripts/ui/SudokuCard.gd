extends Panel
## SudokuCard — 游戏集合卡片
## 点击后导航到对应游戏的入口场景（SudokuMenu）

const SceneTransition := preload("res://scripts/ui/SceneTransition.gd")

@onready var card_icon: TextureRect = %CardIcon


func _ready() -> void:
	# 兼容 Godot 4.7（可能缺少 SVG 加载器）
	if ResourceLoader.exists("res://assets/icons/icon_sudoku.svg"):
		card_icon.texture = ResourceLoader.load("res://assets/icons/icon_sudoku.svg")
	else:
		# 兜底：生成纯色图标
		var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.1, 0.2, 0.5, 0.8))
		card_icon.texture = ImageTexture.create_from_image(img)
	ThemeManager.theme_changed.connect(_on_theme_changed)
	_on_theme_changed(ThemeManager.current_theme_name)


func _on_theme_changed(_theme_name: String) -> void:
	var primary := ThemeManager.get_color("primary")
	card_icon.modulate = primary


func _on_card_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_navigate_to_sudoku()


func _navigate_to_sudoku() -> void:
	SceneTransition.change_to("res://scenes/sudoku/SudokuMenu.tscn")
