class_name ItemMagnifier
extends ItemBase
## 放大镜道具：永久增加本局提示次数上限 +1


func get_item_id() -> StringName:
	return &"magnifier"


func get_display_name() -> String:
	return "放大镜"


func get_description() -> String:
	return "永久增加本局提示次数上限 +1"


func get_price() -> int:
	return 20


func can_use(_board: SudokuBoard, _selected_row: int, _selected_col: int) -> bool:
	return true


func use(_board: SudokuBoard, _selected_row: int, _selected_col: int, _args: Dictionary = {}) -> Dictionary:
	return {
		"hint_bonus": 1,
		"flash": true,
		"dialogue": "item_magnifier",
		"hint_text": "放大镜生效！提示上限 +1",
	}
