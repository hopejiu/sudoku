extends Node
## ThemeManager — 主题管理器 (Autoload)
## 管理全局主题切换。标准 UI 通过 Godot Theme 资源驱动，
## 数独网格专用颜色通过此管理器获取。

signal theme_changed(theme_name: String)

const THEMES := {
	"classic": {
		"background": Color("#F8FAFC"),
		"card_grid": Color("#FFFFFF"),
		"primary": Color("#1E3A8A"),
		"given_number": Color("#1E293B"),
		"user_number": Color("#2563EB"),
		"grid_line": Color("#CBD5E1"),
		"box_line": Color("#64748B"),
		"highlight": Color(0.145, 0.388, 0.922, 0.08),
		"selected": Color(0.145, 0.388, 0.922, 0.15),
		"conflict": Color("#EF4444"),
	},
	"purple_light": {
		"background": Color("#FAF5FF"),
		"card_grid": Color("#FFFFFF"),
		"primary": Color("#7C3AED"),
		"given_number": Color("#4C1D95"),
		"user_number": Color("#8B5CF6"),
		"grid_line": Color("#E5D9F2"),
		"box_line": Color("#C4B5E3"),
		"highlight": Color(0.486, 0.227, 0.929, 0.08),
		"selected": Color(0.486, 0.227, 0.929, 0.15),
		"conflict": Color("#EF4444"),
	},
}

var current_theme_name: String = "classic"


func _ready() -> void:
	# 从存档恢复主题选择
	var settings := SaveManager.load_settings()
	if settings.has("theme"):
		current_theme_name = settings["theme"]


## 获取当前主题中的颜色
func get_color(name: String) -> Color:
	return THEMES[current_theme_name].get(name, Color.WHITE)


## 切换主题
func set_theme(name: String) -> void:
	if not THEMES.has(name) or name == current_theme_name:
		return
	current_theme_name = name
	SaveManager.save_settings({"theme": name})
	theme_changed.emit(name)
