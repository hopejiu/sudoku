extends GutTest
## test_sudoku_board.gd — SudokuBoard 单元测试

const SudokuBoard := preload("res://scripts/game/board/SudokuBoard.gd")
const SudokuRules := preload("res://scripts/game/board/SudokuRules.gd")


var board: SudokuBoard


func before_each() -> void:
	board = SudokuBoard.new()


func after_each() -> void:
	board = null


func test_init_creates_empty_board() -> void:
	for r in 9:
		for c in 9:
			assert_eq(board.grid[r][c], 0)
			assert_false(board.given[r][c])
			assert_eq(board.notes[r][c], 0)
			assert_false(board.conflict[r][c])


func test_load_puzzle() -> void:
	var grid := _make_test_grid()
	var given := _make_test_given()
	var solution := _make_complete_grid()
	board.load_puzzle(grid, given, solution)
	assert_eq(board.grid[0][0], 5)
	assert_true(board.given[0][0])
	assert_eq(board.grid[0][4], 0)  # 非 given 格子


func test_set_cell_on_given_returns_false() -> void:
	var grid := _make_test_grid()
	var given := _make_test_given()
	var solution := _make_complete_grid()
	board.load_puzzle(grid, given, solution)
	# given 格子不可修改
	assert_false(board.set_cell(0, 0, 9))


func test_set_cell_success() -> void:
	var grid := _make_test_grid()
	var given := _make_test_given()
	var solution := _make_complete_grid()
	board.load_puzzle(grid, given, solution)
	# 在空格子填入数字
	assert_true(board.set_cell(0, 4, 6))
	assert_eq(board.grid[0][4], 6)


func test_set_cell_records_undo() -> void:
	var grid := _make_test_grid()
	var given := _make_test_given()
	var solution := _make_complete_grid()
	board.load_puzzle(grid, given, solution)
	var old_size := board.undo_stack.size()
	board.set_cell(0, 4, 6)
	assert_eq(board.undo_stack.size(), old_size + 1)
	var entry: Dictionary = board.undo_stack.back()
	assert_eq(entry.r, 0)
	assert_eq(entry.c, 4)
	assert_eq(entry.ov, 0)
	assert_eq(entry.nv, 6)


func test_undo() -> void:
	var grid := _make_test_grid()
	var given := _make_test_given()
	var solution := _make_complete_grid()
	board.load_puzzle(grid, given, solution)
	board.set_cell(0, 4, 6)
	assert_true(board.undo())
	assert_eq(board.grid[0][4], 0)


func test_undo_empty_stack_returns_false() -> void:
	assert_false(board.undo())


func test_is_victory_empty_board() -> void:
	assert_false(board.is_victory())


func test_is_victory_complete_valid() -> void:
	var grid := _make_complete_grid()
	var given := _make_all_given()
	board.load_puzzle(grid, given, grid)
	assert_true(board.is_victory())


func test_is_victory_with_conflict() -> void:
	var grid := _make_complete_grid()
	var given := _make_all_given()
	board.load_puzzle(grid, given, grid)
	# 制造冲突：手动修改非 given 格子
	# 先把一个格子设为非 given
	given[0][0] = false
	board.load_puzzle(grid, given, grid)
	board.set_cell(0, 0, 3)  # 与同行的 3 冲突
	assert_false(board.is_victory())


func test_toggle_note() -> void:
	board.toggle_note(0, 0, 5)
	assert_ne(board.notes[0][0], 0)
	# 再次切换应取消
	board.toggle_note(0, 0, 5)
	assert_eq(board.notes[0][0], 0)


func test_toggle_note_on_given_ignored() -> void:
	var grid := _make_test_grid()
	var given := _make_test_given()
	var solution := _make_complete_grid()
	board.load_puzzle(grid, given, solution)
	var old_notes: int = board.notes[0][0]
	board.toggle_note(0, 0, 5)  # given 格子
	assert_eq(board.notes[0][0], old_notes)


func test_update_conflicts() -> void:
	var grid := _make_test_grid()
	var given := _make_test_given()
	var solution := _make_complete_grid()
	board.load_puzzle(grid, given, solution)
	# 在 (0,4) 放入与 (0,0)=5 相同的数字
	board.set_cell(0, 4, 5)
	assert_true(board.conflict[0][4])
	assert_true(board.conflict[0][0])


func test_serialize_deserialize() -> void:
	var grid := _make_test_grid()
	var given := _make_test_given()
	var solution := _make_complete_grid()
	board.load_puzzle(grid, given, solution)
	board.set_cell(0, 4, 6)
	board.toggle_note(1, 1, 3)
	var data := board.serialize()
	var board2 := SudokuBoard.new()
	board2.deserialize(data)
	assert_eq(board2.grid[0][4], 6)
	assert_eq(board2.notes[1][1], 1 << 3)
	assert_eq(board2.hint_count, 0)


func test_get_hint() -> void:
	var grid := _make_test_grid()
	var given := _make_test_given()
	var solution := _make_complete_grid()
	board.load_puzzle(grid, given, solution)
	board.hint_cap = 999
	var correct: int = solution[0][4]
	var result := board.get_hint(0, 4)
	assert_eq(result, correct)
	assert_eq(board.grid[0][4], correct)
	assert_eq(board.hint_count, 1)


func test_get_hint_at_cap() -> void:
	var grid := _make_test_grid()
	var given := _make_test_given()
	var solution := _make_complete_grid()
	board.load_puzzle(grid, given, solution)
	board.hint_cap = 0
	var result := board.get_hint(0, 4)
	assert_eq(result, -1)


# ---- 辅助 ----

static func _make_test_grid() -> Array:
	var grid := _empty_grid()
	grid[0] = [5, 3, 0, 0, 0, 0, 0, 0, 0]
	grid[1] = [0, 0, 0, 0, 0, 0, 0, 0, 0]
	return grid


static func _make_test_given() -> Array:
	var given := []
	for r in 9:
		given.append([])
		for c in 9:
			given[r].append(false)
	given[0][0] = true  # 5
	given[0][1] = true  # 3
	return given


static func _make_all_given() -> Array:
	var given := []
	for r in 9:
		given.append([])
		for c in 9:
			given[r].append(true)
	return given


static func _empty_grid() -> Array:
	var grid := []
	for r in 9:
		grid.append([])
		for c in 9:
			grid[r].append(0)
	return grid


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
