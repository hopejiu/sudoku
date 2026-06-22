extends Node
## ThemeManager — 主题管理器 (Autoload)
## 管理全局主题切换，生成 Material Design 风格的 Godot Theme 资源。
## 标准 UI 通过 Godot Theme 资源驱动，数独网格专用颜色通过此管理器获取。

signal theme_changed(theme_name: String)

const THEMES := {
	"classic": {
		"background": Color("#F8FAFC"),
		"surface": Color("#FFFFFF"),
		"card_grid": Color("#FFFFFF"),
		"primary": Color("#1E3A8A"),
		"primary_container": Color("#DBEAFE"),
		"on_primary": Color("#FFFFFF"),
		"given_number": Color("#1E293B"),
		"user_number": Color("#2563EB"),
		"grid_line": Color("#CBD5E1"),
		"box_line": Color("#64748B"),
		"highlight": Color(0.145, 0.388, 0.922, 0.08),
		"selected": Color(0.145, 0.388, 0.922, 0.15),
		"conflict": Color("#EF4444"),
		"shadow": Color(0, 0, 0, 0.12),
		"divider": Color("#E2E8F0"),
	},
	"purple_light": {
		"background": Color("#FAF5FF"),
		"surface": Color("#FFFFFF"),
		"card_grid": Color("#FFFFFF"),
		"primary": Color("#7C3AED"),
		"primary_container": Color("#EDE9FE"),
		"on_primary": Color("#FFFFFF"),
		"given_number": Color("#4C1D95"),
		"user_number": Color("#8B5CF6"),
		"grid_line": Color("#E5D9F2"),
		"box_line": Color("#C4B5E3"),
		"highlight": Color(0.486, 0.227, 0.929, 0.08),
		"selected": Color(0.486, 0.227, 0.929, 0.15),
		"conflict": Color("#EF4444"),
		"shadow": Color(0.486, 0.227, 0.929, 0.12),
		"divider": Color("#EDE9FE"),
	},
}

var current_theme_name: String = "classic"

# 缓存字体
var _font: Font = null
var _font_bold: Font = null


func _ready() -> void:
	# 拦截 Android 返回键/手势，不直接退出
	if get_tree():
		get_tree().set_quit_on_go_back(false)

	# 使用系统字体（不嵌入任何字体文件，APK 体积显著减小）
	_font = SystemFont.new()
	_font_bold = SystemFont.new()
	push_warning("[ThemeManager] using system fonts")

	# 从存档恢复主题选择
	var settings: Dictionary = SaveManager.load_settings()
	if settings.has("theme"):
		current_theme_name = settings["theme"]

	push_warning("[ThemeManager] _ready: loading theme '%s'" % current_theme_name)
	# 生成并应用 MD 主题
	_apply_material_theme(current_theme_name)


## 获取当前主题中的颜色
func get_color(color_name: String) -> Color:
	return THEMES[current_theme_name].get(color_name, Color.WHITE)


## 切换主题
func set_theme(theme_name: String) -> void:
	if not THEMES.has(theme_name) or theme_name == current_theme_name:
		return
	current_theme_name = theme_name
	SaveManager.save_settings({"theme": theme_name})
	_apply_material_theme(theme_name)
	theme_changed.emit(name)


## 创建 StyleBoxFlat 样式盒
func _make_stylebox(bg_color: Color, radius: int = 0, shadow: int = 0, border_width: int = 0, border_color: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.set_corner_radius_all(radius)
	sb.shadow_size = shadow
	sb.shadow_color = get_color("shadow")
	if border_width > 0:
		sb.set_border_width_all(border_width)
		sb.border_color = border_color
	return sb


# ==============================================================================
# 数据驱动按钮变体注册（C3：消除重复的 set_stylebox/set_color 模式）
# ==============================================================================

## 注册轮廓型按钮（填充背景 + 边框，如 NumberKey、FuncButton）
func _register_outlined_buttons(theme: Theme, colors: Dictionary) -> void:
	var configs := [
		{ "type": "NumberKey", "bg": colors.card_grid, "fg": colors.given_number, "fs": 24 },
		{ "type": "FuncButton", "bg": colors.card_grid, "fg": colors.primary, "fs": 24 },
		{ "type": "SecondaryAction", "bg": Color.TRANSPARENT, "fg": colors.primary, "fs": 20,
		  "radius": 10, "shadow": 0, "disabled_bg": Color.TRANSPARENT },
	]
	for cfg in configs:
		var bg: Color = cfg.get("bg", colors.card_grid)
		var fg: Color = cfg.get("fg", colors.given_number)
		var fs: int = cfg.get("fs", 24)
		var radius: int = cfg.get("radius", 14)
		var shadow: int = cfg.get("shadow", 4)
		var border: int = cfg.get("border", 1)
		var border_color: Color = cfg.get("border_color", colors.divider)
		var disabled_bg: Color = cfg.get("disabled_bg", Color("#F1F5F9"))

		theme.set_stylebox("normal", cfg.type, _make_stylebox(bg, radius, shadow, border, border_color))
		theme.set_stylebox("hover", cfg.type, _make_stylebox(colors.primary_container, radius, shadow + 2, border, colors.primary))
		theme.set_stylebox("pressed", cfg.type, _make_stylebox(colors.primary_container.darkened(0.05), radius, max(0, shadow - 2), border, colors.primary))
		theme.set_stylebox("disabled", cfg.type, _make_stylebox(disabled_bg, radius, 0, border, border_color))
		theme.set_color("font_color", cfg.type, fg)
		theme.set_color("font_hover_color", cfg.type, fg)
		theme.set_color("font_pressed_color", cfg.type, fg)
		theme.set_color("font_disabled_color", cfg.type, Color("#94A3B8"))
		theme.set_font_size("font_size", cfg.type, fs)


## 注册填充型按钮（实色背景，如 DialogAction、PrimaryAction）
func _register_filled_buttons(theme: Theme, colors: Dictionary) -> void:
	var configs := [
		{ "type": "DialogAction", "bg": colors.primary, "fg": colors.on_primary, "fs": 24,
		  "radius": 10, "shadow": 4, "hover": colors.primary.lightened(0.15), "pressed": colors.primary.darkened(0.1) },
		{ "type": "PrimaryAction", "bg": colors.primary.lightened(0.2), "fg": colors.on_primary, "fs": 20,
		  "radius": 10, "shadow": 6, "hover": colors.primary.lightened(0.3), "pressed": colors.primary.lightened(0.1) },
	]
	for cfg in configs:
		var bg: Color = cfg.get("bg", colors.primary)
		var fg: Color = cfg.get("fg", colors.on_primary)
		var fs: int = cfg.get("fs", 24)
		var radius: int = cfg.get("radius", 10)
		var shadow: int = cfg.get("shadow", 4)
		var hover: Color = cfg.get("hover", bg.lightened(0.15))
		var pressed: Color = cfg.get("pressed", bg.darkened(0.1))

		theme.set_stylebox("normal", cfg.type, _make_stylebox(bg, radius, shadow))
		theme.set_stylebox("hover", cfg.type, _make_stylebox(hover, radius, shadow + 2))
		theme.set_stylebox("pressed", cfg.type, _make_stylebox(pressed, radius, max(0, shadow - 2)))
		theme.set_stylebox("disabled", cfg.type, _make_stylebox(Color("#E2E8F0"), radius, 0))
		theme.set_color("font_color", cfg.type, fg)
		theme.set_color("font_hover_color", cfg.type, fg)
		theme.set_color("font_pressed_color", cfg.type, fg)
		theme.set_color("font_disabled_color", cfg.type, Color("#94A3B8"))
		theme.set_font_size("font_size", cfg.type, fs)


## 注册文本按钮（透明底 + hover 高亮，如 TextButton）
func _register_text_buttons(theme: Theme, colors: Dictionary) -> void:
	var configs := [
		{ "type": "TextButton", "fg": colors.primary, "fs": 24 },
	]
	for cfg in configs:
		var fg: Color = cfg.get("fg", colors.primary)
		var fs: int = cfg.get("fs", 24)
		var radius: int = cfg.get("radius", 8)

		theme.set_stylebox("normal", cfg.type, _make_stylebox(Color.TRANSPARENT, radius, 0))
		theme.set_stylebox("hover", cfg.type, _make_stylebox(colors.primary_container, radius, 0))
		theme.set_stylebox("pressed", cfg.type, _make_stylebox(colors.primary_container.darkened(0.05), radius, 0))
		theme.set_color("font_color", cfg.type, fg)
		theme.set_color("font_hover_color", cfg.type, fg)
		theme.set_color("font_pressed_color", cfg.type, fg)
		theme.set_font_size("font_size", cfg.type, fs)


## 注册图标按钮（透明底 + 纯色 hover 高亮，无文字样式，如 IconButton）
func _register_icon_buttons(theme: Theme, colors: Dictionary) -> void:
	var configs := [
		{ "type": "IconButton", "radius": 8 },
	]
	for cfg in configs:
		var radius: int = cfg.get("radius", 8)

		theme.set_stylebox("normal", cfg.type, _make_stylebox(Color.TRANSPARENT, radius, 0))
		theme.set_stylebox("hover", cfg.type, _make_stylebox(colors.primary_container, radius, 0))
		theme.set_stylebox("pressed", cfg.type, _make_stylebox(colors.primary_container.darkened(0.05), radius, 0))


## 生成 Material Design 主题并应用到项目
func _apply_material_theme(theme_name: String) -> void:
	var colors: Dictionary = THEMES[theme_name]
	var theme := Theme.new()
	push_warning("[ThemeManager] _apply_material_theme: '%s', colors loaded, default_font=%s" % [theme_name, _font != null])

	# ======== 全局默认 ========
	if _font:
		theme.default_font = _font
		theme.default_font_size = 16

	# ======== 注册 theme_type_variation 继承关系 ========
	theme.set_type_variation("TopBarPanel", "Panel")
	theme.set_type_variation("DialogPanel", "Panel")
	theme.set_type_variation("GameCard", "Panel")
	theme.set_type_variation("FuncButton", "Button")
	theme.set_type_variation("NumberKey", "Button")
	theme.set_type_variation("TextButton", "Button")
	theme.set_type_variation("DialogAction", "Button")
	theme.set_type_variation("PrimaryAction", "Button")
	theme.set_type_variation("SecondaryAction", "Button")
	theme.set_type_variation("IconButton", "Button")

	# ======== Panel 基础 ========
	theme.set_stylebox("panel", "Panel", _make_stylebox(colors.surface, 16, 8))
	theme.set_stylebox("panel", "PanelContainer", _make_stylebox(colors.surface, 16, 8))

	# ======== TopBar Panel ========
	theme.set_stylebox("panel", "TopBarPanel", _make_stylebox(colors.surface, 0, 6))

	# ======== Dialog Panel（大圆角） ========
	theme.set_stylebox("panel", "DialogPanel", _make_stylebox(colors.surface, 20, 16))

	# ======== GameCard Panel（中等圆角，明显阴影） ========
	theme.set_stylebox("panel", "GameCard", _make_stylebox(colors.surface, 16, 12))

	# ======== Button — Contained (Primary) ========
	theme.set_stylebox("normal", "Button", _make_stylebox(colors.primary, 10, 4))
	theme.set_stylebox("hover", "Button", _make_stylebox(colors.primary.lightened(0.15), 10, 6))
	theme.set_stylebox("pressed", "Button", _make_stylebox(colors.primary.darkened(0.1), 10, 2))
	theme.set_stylebox("disabled", "Button", _make_stylebox(Color("#E2E8F0"), 10, 0))
	theme.set_color("font_color", "Button", colors.on_primary)
	theme.set_color("font_hover_color", "Button", colors.on_primary)
	theme.set_color("font_pressed_color", "Button", colors.on_primary)
	theme.set_color("font_disabled_color", "Button", Color("#94A3B8"))
	theme.set_constant("h_separation", "Button", 8)
	theme.set_constant("minimum_width", "Button", 48)

	# ======== 数据驱动按钮变体注册 ========
	_register_outlined_buttons(theme, colors)
	_register_filled_buttons(theme, colors)
	_register_text_buttons(theme, colors)
	_register_icon_buttons(theme, colors)

	# ======== HSlider ========
	var slider_sb := StyleBoxFlat.new()
	slider_sb.bg_color = colors.divider
	slider_sb.set_corner_radius_all(6)
	slider_sb.content_margin_top = 14
	slider_sb.content_margin_bottom = 14

	var garea_sb := StyleBoxFlat.new()
	garea_sb.bg_color = colors.primary
	garea_sb.set_corner_radius_all(6)
	garea_sb.content_margin_top = 14
	garea_sb.content_margin_bottom = 14

	# grabber — 无 content_margin，仅圆角 12px（最小尺寸 24×24）
	var grabber_sb := StyleBoxFlat.new()
	grabber_sb.bg_color = colors.primary
	grabber_sb.set_corner_radius_all(12)

	# grabber_highlight — hover/focus 时变深，避免引擎提亮
	var ghigh_sb := StyleBoxFlat.new()
	ghigh_sb.bg_color = colors.primary.darkened(0.15)
	ghigh_sb.set_corner_radius_all(12)

	# focus 样式透明，排除白色 focus 环
	var focus_empty := StyleBoxFlat.new()
	focus_empty.bg_color = Color.TRANSPARENT
	for t in ["HSlider", "Slider"]:
		theme.set_stylebox("slider", t, slider_sb)
		theme.set_stylebox("grabber_area", t, garea_sb)
		theme.set_stylebox("grabber", t, grabber_sb)
		theme.set_stylebox("grabber_highlight", t, ghigh_sb)
		theme.set_stylebox("focus", t, focus_empty)
	push_warning("[ThemeManager] HSlider styles set: track=%s filled=%s grabber=%s" % [
		colors.divider.to_html(false), colors.primary.to_html(false), colors.primary.to_html(false)])

	# ======== Label ========
	theme.set_color("font_color", "Label", colors.given_number)
	theme.set_constant("line_spacing", "Label", 4)

	# ======== CheckBox (笔记模式切换) ========
	theme.set_stylebox("normal", "CheckBox", _make_stylebox(Color.TRANSPARENT, 6, 0, 2, colors.divider))
	theme.set_stylebox("pressed", "CheckBox", _make_stylebox(colors.primary_container, 6, 0, 2, colors.primary))
	theme.set_stylebox("hover", "CheckBox", _make_stylebox(Color.TRANSPARENT, 6, 0, 2, colors.divider))
	theme.set_stylebox("hover_pressed", "CheckBox", _make_stylebox(colors.primary_container, 6, 0, 2, colors.primary))
	theme.set_stylebox("disabled", "CheckBox", _make_stylebox(Color.TRANSPARENT, 6, 0, 2, colors.divider))
	theme.set_color("font_color", "CheckBox", colors.primary)

	# ======== GridContainer ========
	theme.set_constant("v_separation", "GridContainer", 6)
	theme.set_constant("h_separation", "GridContainer", 6)

	# ======== ScrollContainer ========
	theme.set_stylebox("bg", "ScrollContainer", _make_stylebox(Color.TRANSPARENT, 0, 0))

	# ======== 全局间距 ========
	theme.set_constant("h_separation", "HBoxContainer", 10)
	theme.set_constant("v_separation", "VBoxContainer", 12)
	theme.set_constant("margin_left", "MarginContainer", 20)
	theme.set_constant("margin_top", "MarginContainer", 20)
	theme.set_constant("margin_right", "MarginContainer", 20)
	theme.set_constant("margin_bottom", "MarginContainer", 20)

	# 设置引擎窗口清除色（场景背景）
	RenderingServer.set_default_clear_color(colors.background)

	# 应用移动端安全区域（notch/状态栏 padding）
	_apply_safe_area()

	# 应用到当前场景树的根 Viewport
	if get_tree() and get_tree().root:
		get_tree().root.theme = theme
		# 使用线性滤波使图标缩放平滑，消除 SVG 锯齿
		get_tree().root.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
		push_warning("[ThemeManager] theme + linear filter applied to root viewport")
	else:
		push_warning("[ThemeManager] WARN: no tree/root yet, theme NOT applied")


## 检测并应用安全区域偏移（挖孔屏/状态栏 padding）
## 通过设置 Theme 的 MarginContainer.margin_top 实现，
## 消除递归场景树遍历的脆弱性（C6 改进）。
func _apply_safe_area() -> void:
	if not get_tree() or not get_tree().root:
		return
	var safe_area := DisplayServer.get_display_safe_area()
	# 仅在顶部有安全区域时才调整（桌面端 safe_area 等于全屏，不调整）
	var top_inset := safe_area.position.y
	if top_inset <= 0:
		return
	# 推迟到 theme 已应用后执行
	await get_tree().process_frame
	if not get_tree() or not get_tree().root or not get_tree().root.theme:
		return
	var existing := get_tree().root.theme.get_constant("margin_top", "MarginContainer")
	var new_top := maxi(top_inset, existing)
	get_tree().root.theme.set_constant("margin_top", "MarginContainer", new_top)
