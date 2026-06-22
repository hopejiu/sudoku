class_name SkillComboReveal
extends SkillBase
## 角色C — 连击馈赠
## 每连续正确填入 5 个数字（无冲突、不覆盖），自动揭露 1 个空格。
## 中间有回撤或错误填入则连击中断归零。


var _combo_count: int = 0


static func get_skill_name() -> String:
	return "连击馈赠"


static func get_skill_desc() -> String:
	return "每连续正确填入 5 个数字，自动揭露 1 个空格"


func on_number_placed(board: SudokuBoard, _row: int, _col: int, num: int, old_val: int) -> Dictionary:
	# 判断是否"正确填入"
	var is_correct := num > 0 and old_val != num

	if is_correct:
		_combo_count += 1
		if _combo_count >= 5:
			_combo_count = 0
			var reveal := _find_reveal(board)
			if not reveal.is_empty():
				return {
					"reveal": reveal,
					"combo_count": _combo_count,
					"combo_reset": true,
					"hint_text": "Combo 5! 揭露！",
					"dialogue": "skill_c_combo",
				}
			return {"combo_count": 0, "combo_reset": true}
		return {"combo_count": _combo_count, "hint_text": "Combo %d!" % _combo_count}
	else:
		_combo_count = 0
		return {"combo_count": 0, "combo_reset": true, "hint_text": "Combo 中断！", "dialogue": "skill_c_break"}


func on_undo(_board: SudokuBoard) -> Dictionary:
	# 回撤打断连击
	if _combo_count > 0:
		_combo_count = 0
		return {"combo_count": 0, "combo_reset": true}
	return {}


func get_combo_count() -> int:
	return _combo_count


static func _find_reveal(board: SudokuBoard) -> Dictionary:
	for r in 9:
		for c in 9:
			if board.grid[r][c] == 0:
				var correct: int = board.solution[r][c] if board.solution.size() > 0 else 0
				if correct > 0:
					return {"r": r, "c": c}
	return {}
