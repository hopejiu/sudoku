extends Control
## Main — 游戏集合主界面
## 顶部标题栏 + 游戏卡片列表，整体布局与主题切换

@onready var bg: ColorRect = %Bg
@onready var title_label: Label = %TitleLabel  # U8: 改用 %UniqueName

func _ready() -> void:
	ThemeManager.theme_changed.connect(_apply_theme_colors)
	_apply_theme_colors()
	# 兼容 Godot 4.7（可能缺少 SVG 加载器）：生成兜底图标
	_generate_fallback_icon()


func _generate_fallback_icon() -> void:
	if %SettingsBtn.icon and %SettingsBtn.icon.get_size().x > 0:
		return
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0))
	for x in 32:
		for y in 32:
			var dx := x - 16.0
			var dy := y - 16.0
			var dist := sqrt(dx * dx + dy * dy)
			if dist > 4.0 and dist < 14.0 and int(x + y) % 4 < 3:
				img.set_pixel(x, y, Color(1, 1, 1, 1))
	%SettingsBtn.icon = ImageTexture.create_from_image(img)


func _apply_theme_colors() -> void:
	bg.color = ThemeManager.get_color("background")
	var primary := ThemeManager.get_color("primary")
	title_label.add_theme_color_override("font_color", primary)
	%SettingsBtn.modulate = primary


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		# 主界面不退出，做无操作（或提示）
		pass


func _on_settings_btn_pressed() -> void:
	if ThemeManager.current_theme_name == "classic":
		ThemeManager.set_theme("purple_light")
	else:
		ThemeManager.set_theme("classic")
