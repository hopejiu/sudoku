extends Control
## Shop — 道具商店
## 使用积分购买道具。积分来自 PlayerManager，购买后道具进入背包。

const SceneTransition := preload("res://scripts/ui/common/SceneTransition.gd")

var _items: Array = []  # 道具定义列表

@onready var bg: ColorRect = %Bg
@onready var back_btn: Button = %BackBtn
@onready var coins_label: Label = %CoinsLabel
@onready var item_container: VBoxContainer = %ItemContainer
@onready var empty_hint: Label = %EmptyHint


func _ready() -> void:
	back_btn.pressed.connect(_on_back_pressed)

	ThemeManager.theme_changed.connect(_on_theme_changed)
	_on_theme_changed(ThemeManager.current_theme_name)

	_refresh()


func _on_theme_changed(_name: String) -> void:
	bg.color = ThemeManager.get_color("background")
	var primary := ThemeManager.get_color("primary")
	back_btn.modulate = primary


func _refresh() -> void:
	# 清空旧条目
	for child in item_container.get_children():
		child.queue_free()

	_items = PlayerManager.get_all_item_defs()
	coins_label.text = "积分: %d" % PlayerManager.coins
	empty_hint.visible = _items.is_empty()

	for item in _items:
		var item_id: StringName = item.get("id", &"")
		var name_str: String = item.get("display_name", "?")
		var desc: String = item.get("description", "")
		var price: int = item.get("price", 0)
		var owned: int = PlayerManager.get_item_count(item_id)

		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 64)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var title := Label.new()
		title.text = "%s  (拥有: %d)" % [name_str, owned]
		title.add_theme_font_size_override("font_size", 18)
		info.add_child(title)

		var desc_label := Label.new()
		desc_label.text = desc
		desc_label.add_theme_font_size_override("font_size", 14)
		desc_label.theme_override_colors/font_color = Color(0.6, 0.6, 0.6, 1)
		info.add_child(desc_label)

		row.add_child(info)

		var buy_btn := Button.new()
		buy_btn.text = "%d 积分" % price
		buy_btn.theme_type_variation = &"DialogAction"
		buy_btn.custom_minimum_size = Vector2(100, 44)
		buy_btn.disabled = not PlayerManager.has_coins(price)
		buy_btn.pressed.connect(_on_buy_pressed.bind(item_id, price))
		row.add_child(buy_btn)

		item_container.add_child(row)

		# 分隔线
		var sep := HSeparator.new()
		item_container.add_child(sep)


func _on_buy_pressed(item_id: StringName, price: int) -> void:
	if not PlayerManager.spend_coins(price):
		return
	PlayerManager.add_item(item_id, 1)
	PlayerManager.save()
	_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_back_pressed()


func _on_back_pressed() -> void:
	SceneTransition.change_to("res://scenes/sudoku/SudokuMenu.tscn")
