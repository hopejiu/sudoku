extends Control
## Main — 游戏集合主界面
## 顶部标题栏 + 游戏卡片列表，整体布局与主题切换

@onready var bg: ColorRect = %Bg

func _ready() -> void:
	ThemeManager.theme_changed.connect(_on_theme_changed)
	_on_theme_changed(ThemeManager.current_theme_name)


func _on_theme_changed(_name: String) -> void:
	bg.color = ThemeManager.get_color("background")
	var primary := ThemeManager.get_color("primary")
	%TopBar.get_node("TopHBox/TitleLabel").add_theme_color_override("font_color", primary)
	%SettingsBtn.modulate = primary


func _on_settings_btn_pressed() -> void:
	if ThemeManager.current_theme_name == "classic":
		ThemeManager.set_theme("purple_light")
	else:
		ThemeManager.set_theme("classic")
