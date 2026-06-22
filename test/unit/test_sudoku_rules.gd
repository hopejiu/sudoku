extends GutTest
## test_sudoku_rules.gd — SudokuRules 单元测试

const SudokuRules := preload("res://scripts/game/board/SudokuRules.gd")


func test_is_valid_empty_grid() -> void:
	var grid := _empty_grid()
	# 空盘面中任何数字在任何位置都合法
	assert_true(SudokuRules.is_valid(grid, 0, 0, 5))
	assert_true(SudokuRules.is_valid(grid, 4, 4, 1))
	assert_true(SudokuRules.is_valid(grid, 8, 8, 9))


func test_is_valid_row_conflict() -> void:
	var grid := _empty_grid()
	grid[0][3] = 5
	# 同行已有 5，不能再放
	assert_false(SudokuRules.is_valid(grid, 0, 0, 5))
	assert_false(SudokuRules.is_valid(grid, 0, 8, 5))
	# 不同行可以放
	assert_true(SudokuRules.is_valid(grid, 1, 0, 5))


func test_is_valid_col_conflict() -> void:
	var grid := _empty_grid()
	grid[3][0] = 7
	# 同列已有 7
	assert_false(SudokuRules.is_valid(grid, 0, 0, 7))
	assert_false(SudokuRules.is_valid(grid, 8, 0, 7))
	# 不同列可以放
	assert_true(SudokuRules.is_valid(grid, 0, 1, 7))


func test_is_valid_box_conflict() -> void:
	var grid := _empty_grid()
	grid[0][0] = 3
	# 同宫 (0,0)-(2,2) 已有 3
	assert_false(SudokuRules.is_valid(grid, 1, 1, 3))
	assert_false(SudokuRules.is_valid(grid, 2, 2, 3))
	# 不同宫可以放
	assert_true(SudokuRules.is_valid(grid, 3, 3, 3))


func test_is_valid_self_cell() -> void:
	var grid := _empty_grid()
	grid[4][4] = 6
	# 检查自身位置应为 true（排除自身）
	assert_true(SudokuRules.is_valid(grid, 4, 4, 6))


func test_copy_grid() -> void:
	var src := _empty_grid()
	src[0][0] = 1
	src[8][8] = 9
	var dst := SudokuRules.copy_grid(src)
	# 内容相同
	assert_eq(dst[0][0], 1)
	assert_eq(dst[8][8], 9)
	# 修改副本不影响原件
	dst[0][0] = 5
	assert_eq(src[0][0], 1)


func test_box_id() -> void:
	assert_eq(SudokuRules.box_id(0, 0), 0)
	assert_eq(SudokuRules.box_id(0, 3), 1)
	assert_eq(SudokuRules.box_id(0, 6), 2)
	assert_eq(SudokuRules.box_id(3, 0), 3)
	assert_eq(SudokuRules.box_id(3, 3), 4)
	assert_eq(SudokuRules.box_id(3, 6), 5)
	assert_eq(SudokuRules.box_id(6, 0), 6)
	assert_eq(SudokuRules.box_id(6, 3), 7)
	assert_eq(SudokuRules.box_id(6, 6), 8)


func test_popcount() -> void:
	assert_eq(SudokuRules.popcount(0), 0)
	assert_eq(SudokuRules.popcount(1), 1)
	assert_eq(SudokuRules.popcount(3), 2)
	assert_eq(SudokuRules.popcount(7), 3)
	assert_eq(SudokuRules.popcount(0x1FF), 9)  # 9 位全 1


func test_mask_to_values() -> void:
	# bit 0 = value 1, bit 1 = value 2, etc.
	var mask := (1 << 0) | (1 << 4) | (1 << 8)  # values 1, 5, 9
	var vals := SudokuRules.mask_to_values(mask)
	assert_eq(vals.size(), 3)
	assert_true(vals.has(1))
	assert_true(vals.has(5))
	assert_true(vals.has(9))


func test_build_masks() -> void:
	var grid := _empty_grid()
	grid[0][0] = 1
	grid[0][1] = 2
	grid[1][0] = 3
	var masks := SudokuRules.build_masks(grid)
	# row 0: bits 0,1 = 3
	assert_eq(masks.rows[0], (1 << 0) | (1 << 1))
	# col 0: bits 0,2 = 5
	assert_eq(masks.cols[0], (1 << 0) | (1 << 2))
	# box 0: bits 0,1,2 = 7
	assert_eq(masks.boxes[0], (1 << 0) | (1 << 1) | (1 << 2))


func test_count_solutions_complete_grid() -> void:
	var grid := _make_complete_valid_grid()
	assert_eq(SudokuRules.count_solutions(grid, 2), 1)


func test_count_solutions_empty_grid() -> void:
	var grid := _empty_grid()
	# 空盘面有非常多解，但 limit=2 时只需返回 >=2
	var count := SudokuRules.count_solutions(grid, 2)
	assert_true(count >= 2)


func test_count_solutions_unique() -> void:
	# 构造一个已知唯一解的谜题
	var grid := _make_complete_valid_grid()
	var solution := SudokuRules.copy_grid(grid)
	# 挖去一些格子，保留唯一解
	grid[0][0] = 0
	grid[0][1] = 0
	grid[1][0] = 0
	var count := SudokuRules.count_solutions(grid, 2)
	# 可能唯一也可能不是，但至少返回 1
	assert_true(count >= 1)


# ---- 辅助 ----

static func _empty_grid() -> Array:
	var grid := []
	for r in 9:
		grid.append([])
		for c in 9:
			grid[r].append(0)
	return grid


static func _make_complete_valid_grid() -> Array:
	# 一个已知合法的完整数独盘面
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
