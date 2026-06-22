class_name ItemBomb
extends ItemBase
## 炸弹道具：揭露指定 3×3 宫的所有正确答案
##
## UI 交互（拖拽瞄准）由 SudokuGame/SudokuGrid 处理，
## use() 在交互完成后被调用，box_row/box_col 通过 args 传入。


func get_item_id() -> StringName:
	return &"bomb"


func get_display_name() -> String:
	return "炸弹"


func get_description() -> String:
	return "揭露指定 3×3 宫的所有正确答案"


func get_price() -> int:
	return 100


func can_use(_board: SudokuBoard, _selected_row: int, _selected_col: int) -> bool:
	return true


func use(board: SudokuBoard, _selected_row: int, _selected_col: int, args: Dictionary = {}) -> Dictionary:
	var box_row: int = args.get("box_row", 0)
	var box_col: int = args.get("box_col", 0)

	var filled := 0
	for r in range(box_row, box_row + 3):
		for c in range(box_col, box_col + 3):
			if board.grid[r][c] == 0 and not board.given[r][c]:
				var correct: int = board.solution[r][c] if board.solution.size() > 0 else 0
				if correct > 0:
					board.grid[r][c] = correct
					filled += 1
	board.update_conflicts()

	return {
		"dialogue": "item_bomb",
		"bomb_effect": {"r": box_row, "c": box_col},
	}
