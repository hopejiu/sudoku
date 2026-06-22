class_name SkillChainReveal
extends SkillBase
## 角色A — 连锁揭露
## 每完成一行/一列/一宫（该区域填满无冲突），自动揭露盘面上任意一个空格。
## 同一次填入触发多个完成条件也只算 1 次。


static func get_skill_name() -> String:
	return "连锁揭露"


static func get_skill_desc() -> String:
	return "每完成一行/一列/一宫，自动揭露 1 个空格"


func on_number_placed(board: SudokuBoard, row: int, col: int, _num: int, _old_val: int) -> Dictionary:
	# 检查行
	var row_done := true
	for c in 9:
		if board.grid[row][c] == 0:
			row_done = false
			break
	if row_done:
		return _do_reveal(board, row, 4)

	# 检查列
	var col_done := true
	for r in 9:
		if board.grid[r][col] == 0:
			col_done = false
			break
	if col_done:
		return _do_reveal(board, 4, col)

	# 检查宫
	var br := int(row / 3) * 3
	var bc := int(col / 3) * 3
	var box_done := true
	for r in range(br, br + 3):
		for c in range(bc, bc + 3):
			if board.grid[r][c] == 0:
				box_done = false
				break
		if not box_done:
			break
	if box_done:
		return _do_reveal(board, br + 1, bc + 1)

	return {}


static func _do_reveal(board: SudokuBoard, from_r: int, from_c: int) -> Dictionary:
	for r in 9:
		for c in 9:
			if board.grid[r][c] == 0:
				var correct: int = board.solution[r][c] if board.solution.size() > 0 else 0
				if correct > 0:
					return {
						"reveal": {"r": r, "c": c},
						"reveal_from": {"r": from_r, "c": from_c},
						"hint_text": "连锁揭露！",
						"dialogue": "skill_a_trigger",
					}
	return {}
