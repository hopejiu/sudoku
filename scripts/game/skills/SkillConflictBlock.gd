class_name SkillConflictBlock
extends SkillBase
## 角色B — 冲突屏蔽
## 选中空格时，数字键盘自动禁用所有会导致冲突的数字。
## 即键盘只会显示该格可用的候选数字。


var _first_trigger := false


static func get_skill_name() -> String:
	return "冲突屏蔽"


static func get_skill_desc() -> String:
	return "选中空格时，键盘自动禁用冲突数字"


func on_cell_selected(board: SudokuBoard, row: int, col: int, _prev_row: int, _prev_col: int) -> Dictionary:
	if board.grid[row][col] != 0:
		return {"disable_keys": []}  # 已填格不屏蔽

	var disabled := _calc_disabled(board, row, col)
	var result: Dictionary = {"disable_keys": disabled}
	if not _first_trigger and not disabled.is_empty():
		_first_trigger = true
		result["dialogue"] = "skill_b_block"
	return result


func on_number_placed(board: SudokuBoard, _row: int, _col: int, _num: int, _old_val: int) -> Dictionary:
	# 填入后恢复键盘正常状态
	return {}


func on_undo(_board: SudokuBoard) -> Dictionary:
	return {}


static func _calc_disabled(board: SudokuBoard, row: int, col: int) -> Array:
	var disabled := []
	for n in range(1, 10):
		if not _is_valid(board, row, col, n):
			disabled.append(n)
	return disabled


static func _is_valid(board: SudokuBoard, row: int, col: int, num: int) -> bool:
	for cc in 9:
		if cc != col and board.grid[row][cc] == num:
			return false
	for rr in 9:
		if rr != row and board.grid[rr][col] == num:
			return false
	var br := int(row / 3) * 3
	var bc := int(col / 3) * 3
	for rr in range(br, br + 3):
		for cc in range(bc, bc + 3):
			if (rr != row or cc != col) and board.grid[rr][cc] == num:
				return false
	return true
