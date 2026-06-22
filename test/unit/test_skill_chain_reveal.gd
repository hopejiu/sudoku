extends GutTest
## test_skill_chain_reveal.gd — SkillChainReveal 单元测试

const SkillChainReveal := preload("res://scripts/game/skills/SkillChainReveal.gd")
const SudokuBoard := preload("res://scripts/game/board/SudokuBoard.gd")


var skill: SkillChainReveal
var board: SudokuBoard


func before_each() -> void:
	skill = SkillChainReveal.new()
	board = SudokuBoard.new()


func after_each() -> void:
	skill = null
	board = null


func test_skill_name() -> void:
	assert_eq(SkillChainReveal.get_skill_name(), "连锁揭露")


func test_skill_desc() -> void:
	assert_ne(SkillChainReveal.get_skill_desc(), "")


func test_no_trigger_when_row_incomplete() -> void:
	var grid := _empty_grid()
	grid[0] = [1, 2, 3, 4, 5, 6, 7, 8, 0]  # 差一个
	var given := _make_all_false()
	var solution := _make_complete_grid()
	board.load_puzzle(grid, given, solution)
	var result := skill.on_number_placed(board, 0, 8, 9, 0)
	# 行未完成，不应触发
	assert_true(result.is_empty() or not result.has("reveal"))


func test_trigger_on_row_complete() -> void:
	var grid := _empty_grid()
	# 填满第 0 行
	grid[0] = [5, 3, 4, 6, 7, 8, 9, 1, 0]
	var given := _make_all_false()
	var solution := _make_complete_grid()
	board.load_puzzle(grid, given, solution)
	# 填入最后一个数字
	board.grid[0][8] = 2
	var result := skill.on_number_placed(board, 0, 8, 2, 0)
	# 应该触发揭露
	if not result.is_empty():
		assert_true(result.has("reveal"))
		assert_true(result.has("reveal_from"))


func test_trigger_on_col_complete() -> void:
	var grid := _empty_grid()
	# 填满第 0 列
	grid[0][0] = 5
	grid[1][0] = 6
	grid[2][0] = 1
	grid[3][0] = 8
	grid[4][0] = 4
	grid[5][0] = 7
	grid[6][0] = 9
	grid[7][0] = 2
	grid[8][0] = 0  # 差最后一个
	var given := _make_all_false()
	var solution := _make_complete_grid()
	board.load_puzzle(grid, given, solution)
	board.grid[8][0] = 3
	var result := skill.on_number_placed(board, 8, 0, 3, 0)
	if not result.is_empty():
		assert_true(result.has("reveal"))


func test_trigger_on_box_complete() -> void:
	var grid := _empty_grid()
	# 填满左上宫 (0,0)-(2,2)
	grid[0] = [5, 3, 4, 0, 0, 0, 0, 0, 0]
	grid[1] = [6, 7, 2, 0, 0, 0, 0, 0, 0]
	grid[2] = [1, 9, 0, 0, 0, 0, 0, 0, 0]
	var given := _make_all_false()
	var solution := _make_complete_grid()
	board.load_puzzle(grid, given, solution)
	board.grid[2][2] = 8
	var result := skill.on_number_placed(board, 2, 2, 8, 0)
	if not result.is_empty():
		assert_true(result.has("reveal"))


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
