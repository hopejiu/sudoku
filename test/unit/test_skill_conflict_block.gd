extends GutTest
## test_skill_conflict_block.gd — SkillConflictBlock 单元测试

const SkillConflictBlock := preload("res://scripts/game/skills/SkillConflictBlock.gd")
const SudokuBoard := preload("res://scripts/game/board/SudokuBoard.gd")


var skill: SkillConflictBlock
var board: SudokuBoard


func before_each() -> void:
	skill = SkillConflictBlock.new()
	board = SudokuBoard.new()


func after_each() -> void:
	skill = null
	board = null


func test_skill_name() -> void:
	assert_eq(SkillConflictBlock.get_skill_name(), "冲突屏蔽")


func test_selecting_filled_cell_returns_empty_disabled() -> void:
	var grid := _empty_grid()
	grid[0][0] = 5
	var given := _make_all_false()
	var solution := _make_complete_grid()
	board.load_puzzle(grid, given, solution)
	var result := skill.on_cell_selected(board, 0, 0, -1, -1)
	assert_true(result.has("disable_keys"))
	assert_true(result.disable_keys.is_empty())


func test_selecting_empty_cell_disables_conflicts() -> void:
	var grid := _empty_grid()
	grid[0][0] = 5  # 同行有 5
	grid[1][1] = 3  # 同宫有 3
	var given := _make_all_false()
	var solution := _make_complete_grid()
	board.load_puzzle(grid, given, solution)
	# 选中 (0,1)，应该禁用 5（同行）和 3（同宫）
	var result := skill.on_cell_selected(board, 0, 1, -1, -1)
	assert_true(result.has("disable_keys"))
	var disabled: Array = result.disable_keys
	assert_true(disabled.has(5), "5 should be disabled (row conflict)")
	assert_true(disabled.has(3), "3 should be disabled (box conflict)")


func test_no_disabled_keys_for_open_cell() -> void:
	var grid := _empty_grid()
	var given := _make_all_false()
	var solution := _make_complete_grid()
	board.load_puzzle(grid, given, solution)
	# 空盘面选中任意格子，不应禁用任何数字
	var result := skill.on_cell_selected(board, 4, 4, -1, -1)
	assert_true(result.has("disable_keys"))
	assert_true(result.disable_keys.is_empty())


func test_on_number_placed_returns_empty() -> void:
	var grid := _empty_grid()
	var given := _make_all_false()
	var solution := _make_complete_grid()
	board.load_puzzle(grid, given, solution)
	var result := skill.on_number_placed(board, 0, 0, 5, 0)
	assert_true(result.is_empty())


func test_on_undo_returns_empty() -> void:
	var result := skill.on_undo(board)
	assert_true(result.is_empty())


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
