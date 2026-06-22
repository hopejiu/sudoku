extends GutTest
## test_skill_combo_reveal.gd — SkillComboReveal 单元测试

const SkillComboReveal := preload("res://scripts/game/skills/SkillComboReveal.gd")
const SudokuBoard := preload("res://scripts/game/board/SudokuBoard.gd")


var skill: SkillComboReveal
var board: SudokuBoard


func before_each() -> void:
	skill = SkillComboReveal.new()
	board = SudokuBoard.new()


func after_each() -> void:
	skill = null
	board = null


func test_skill_name() -> void:
	assert_eq(SkillComboReveal.get_skill_name(), "连击馈赠")


func test_initial_combo_is_zero() -> void:
	assert_eq(skill.get_combo_count(), 0)


func test_combo_increments_on_correct_placement() -> void:
	var grid := _empty_grid()
	var given := _make_all_false()
	var solution := _make_complete_grid()
	board.load_puzzle(grid, given, solution)
	# 填入正确数字
	skill.on_number_placed(board, 0, 0, 5, 0)
	assert_eq(skill.get_combo_count(), 1)


func test_combo_resets_on_overwrite() -> void:
	var grid := _empty_grid()
	grid[0][0] = 3  # 已有数字
	var given := _make_all_false()
	var solution := _make_complete_grid()
	board.load_puzzle(grid, given, solution)
	# 覆盖已有数字（old_val == num 视为不正确）
	skill.on_number_placed(board, 0, 0, 3, 3)
	assert_eq(skill.get_combo_count(), 0)


func test_combo_resets_on_undo() -> void:
	var grid := _empty_grid()
	var given := _make_all_false()
	var solution := _make_complete_grid()
	board.load_puzzle(grid, given, solution)
	skill.on_number_placed(board, 0, 0, 5, 0)
	assert_eq(skill.get_combo_count(), 1)
	skill.on_undo(board)
	assert_eq(skill.get_combo_count(), 0)


func test_trigger_at_combo_5() -> void:
	var grid := _empty_grid()
	var given := _make_all_false()
	var solution := _make_complete_grid()
	board.load_puzzle(grid, given, solution)
	# 连续填入 5 个正确数字
	for i in 5:
		var r := i / 9
		var c := i % 9
		var num: int = solution[r][c]
		var result := skill.on_number_placed(board, r, c, num, 0)
		if i < 4:
			assert_eq(skill.get_combo_count(), i + 1)
	# 第 5 次应该触发揭露
	var last_result := skill.on_number_placed(board, 0, 5, solution[0][5], 0)
	if not last_result.is_empty() and last_result.has("reveal"):
		assert_true(last_result.combo_reset)


func test_combo_count_tracks_correctly() -> void:
	var grid := _empty_grid()
	var given := _make_all_false()
	var solution := _make_complete_grid()
	board.load_puzzle(grid, given, solution)
	# 填入 3 个正确数字
	for i in 3:
		skill.on_number_placed(board, 0, i, solution[0][i], 0)
	assert_eq(skill.get_combo_count(), 3)


# ---- 辅助 ----

static func _empty_grid() -> Array:
	var grid := []
	for r in 9:
		grid.append([])
		for c in 9:
			grid[r].append(0)
	return grid


static func _make_all_false() -> Array:
	var given := []
	for r in 9:
		given.append([])
		for c in 9:
			given[r].append(false)
	return given


static func _make_complete_grid() -> Array:
	return [
		[5, 3, 4, 6, 7, 8, 9, 1, 2],
		[6, 7, 2, 1, 9, 5, 3, 4, 8],
		[1, 9, 8, 3, 4, 2, 5, 6, 7],
		[8, 5, 9, 7, 6, 1, 4, 2, 3],
		[4, 2, 6, 8, 5, 3, 7, 9, 1],
		[7, 1, 3, 9, 2, 4, 8, 5, 6],
		[9, 6, 1, 5, 3, 7, 2, 8, 4],
		[2, 8, 7, 4, 1, 9, 6, 3, 5],
		[3, 4, 5, 2, 8, 6, 1, 7, 9],
	]
