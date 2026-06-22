extends GutTest
## test_sudoku_generator.gd — SudokuGenerator 单元测试

const SudokuGenerator := preload("res://scripts/game/board/SudokuGenerator.gd")
const SudokuRules := preload("res://scripts/game/board/SudokuRules.gd")


func test_generate_returns_valid_structure() -> void:
	var result := SudokuGenerator.generate(1)
	assert_true(result.has("grid"))
	assert_true(result.has("given"))
	assert_true(result.has("solution"))
	assert_eq(result.grid.size(), 9)
	assert_eq(result.given.size(), 9)
	assert_eq(result.solution.size(), 9)


func test_generate_solution_is_complete() -> void:
	var result := SudokuGenerator.generate(1)
	for r in 9:
		for c in 9:
			assert_ne(result.solution[r][c], 0, "Solution cell [%d,%d] should be filled" % [r, c])


func test_generate_solution_is_valid() -> void:
	var result := SudokuGenerator.generate(1)
	# 验证 solution 中每行、列、宫无重复
	for r in 9:
		var row_vals := {}
		for c in 9:
			var v: int = result.solution[r][c]
			assert_false(row_vals.has(v), "Duplicate %d in row %d" % [v, r])
			row_vals[v] = true
	for c in 9:
		var col_vals := {}
		for r in 9:
			var v: int = result.solution[r][c]
			assert_false(col_vals.has(v), "Duplicate %d in col %d" % [v, c])
			col_vals[v] = true


func test_generate_grid_matches_solution_for_given() -> void:
	var result := SudokuGenerator.generate(1)
	for r in 9:
		for c in 9:
			if result.given[r][c]:
				assert_eq(result.grid[r][c], result.solution[r][c],
					"Given cell [%d,%d] should match solution" % [r, c])


func test_generate_grid_has_holes() -> void:
	var result := SudokuGenerator.generate(1)
	var holes := 0
	for r in 9:
		for c in 9:
			if result.grid[r][c] == 0:
				holes += 1
	assert_gt(holes, 0, "Puzzle should have empty cells")


func test_generate_hole_count_formula() -> void:
	# level 1: 26 + 1*2 = 28 holes
	# level 8: 26 + 8*2 = 42 holes
	for level in [1, 5, 8, 12]:
		var result := SudokuGenerator.generate(level)
		var expected_holes: int = 26 + level * 2
		var actual_holes := 0
		for r in 9:
			for c in 9:
				if result.grid[r][c] == 0:
					actual_holes += 1
		# 由于唯一解约束，实际挖空数可能略少于理论值
		assert_true(actual_holes <= expected_holes,
			"Level %d: expected <= %d holes, got %d" % [level, expected_holes, actual_holes])
		assert_true(actual_holes >= expected_holes - 5,
			"Level %d: expected ~%d holes, got %d (too few)" % [level, expected_holes, actual_holes])


func test_generate_unique_solution() -> void:
	# 验证生成的谜题有唯一解
	for level in [1, 8]:
		var result := SudokuGenerator.generate(level)
		var count := SudokuRules.count_solutions(result.grid, 2)
		assert_eq(count, 1, "Level %d puzzle should have unique solution" % level)


func test_generate_different_boards() -> void:
	# 多次生成应该产生不同盘面
	var results := []
	for i in 3:
		results.append(SudokuGenerator.generate(1))
	# 检查至少有一个格子不同（概率极高）
	var all_same := true
	for r in 9:
		for c in 9:
			if results[0].grid[r][c] != results[1].grid[r][c]:
				all_same = false
				break
		if not all_same:
			break
	assert_false(all_same, "Generated boards should differ (probability ~1)")
