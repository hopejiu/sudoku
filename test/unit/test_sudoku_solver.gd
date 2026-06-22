extends GutTest
## test_sudoku_solver.gd — SudokuSolver 单元测试

const SudokuSolver := preload("res://scripts/game/board/SudokuSolver.gd")
const SudokuRules := preload("res://scripts/game/board/SudokuRules.gd")


func test_solve_complete_grid() -> void:
	var grid := _make_complete_valid_grid()
	var result := SudokuSolver.solve(grid)
	# 已完整的盘面返回自身（深拷贝）
	assert_eq(result.size(), 9)
	assert_eq(result[0][0], 5)


func test_solve_solvable_puzzle() -> void:
	var grid := _make_complete_valid_grid()
	# 挖几个格子
	grid[0][0] = 0
	grid[0][1] = 0
	grid[1][0] = 0
	var result := SudokuSolver.solve(grid)
	# 解出的盘面应该完整
	assert_eq(result.size(), 9)
	for r in 9:
		for c in 9:
			assert_ne(result[r][c], 0, "Cell [%d,%d] should be filled" % [r, c])


func test_solve_returns_correct_solution() -> void:
	var solution := _make_complete_valid_grid()
	var puzzle := SudokuRules.copy_grid(solution)
	puzzle[0][0] = 0
	puzzle[4][4] = 0
	puzzle[8][8] = 0
	var solved := SudokuSolver.solve(puzzle)
	assert_eq(solved[0][0], solution[0][0])
	assert_eq(solved[4][4], solution[4][4])
	assert_eq(solved[8][8], solution[8][8])


func test_is_unique_valid_puzzle() -> void:
	var grid := _make_complete_valid_grid()
	grid[0][0] = 0
	grid[0][1] = 0
	grid[1][0] = 0
	var unique := SudokuSolver.is_unique(grid)
	assert_true(unique, "Puzzle with 3 holes in this known grid should be unique")


func test_solve_unsolvable_returns_empty() -> void:
	# 构造一个无解盘面：第一行全是 1
	var grid := _empty_grid()
	for c in 9:
		grid[0][c] = 1
	var result := SudokuSolver.solve(grid)
	assert_true(result.is_empty(), "Unsolvable grid should return empty array")


func test_does_not_modify_input() -> void:
	var grid := _make_complete_valid_grid()
	grid[0][0] = 0
	var original := SudokuRules.copy_grid(grid)
	var _result := SudokuSolver.solve(grid)
	# 输入不应被修改
	assert_eq(grid[0][0], 0, "Input grid should not be modified")
	assert_eq(grid[0][1], original[0][1])


# ---- 辅助 ----

static func _empty_grid() -> Array:
	var grid := []
	for r in 9:
		grid.append([])
		for c in 9:
			grid[r].append(0)
	return grid


static func _make_complete_valid_grid() -> Array:
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
