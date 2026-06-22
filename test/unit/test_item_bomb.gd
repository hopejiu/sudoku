extends GutTest
## test_item_bomb.gd — ItemBomb 单元测试

const ItemBomb := preload("res://scripts/game/items/ItemBomb.gd")
const SudokuBoard := preload("res://scripts/game/board/SudokuBoard.gd")


var item: ItemBomb
var board: SudokuBoard


func before_each() -> void:
	item = ItemBomb.new()
	board = SudokuBoard.new()


func after_each() -> void:
	item = null
	board = null


func test_item_id() -> void:
	assert_eq(item.get_item_id(), &"bomb")


func test_display_name() -> void:
	assert_eq(item.get_display_name(), "炸弹")


func test_price() -> void:
	assert_eq(item.get_price(), 100)


func test_can_use_always_true() -> void:
	assert_true(item.can_use(board, 0, 0))


func test_use_fills_box() -> void:
	# 加载一个谜题
	var grid := _make_test_grid()
	var given := _make_test_given()
	var solution := _make_complete_grid()
	board.load_puzzle(grid, given, solution)

	# 使用炸弹在左上宫 (0,0)
	var result := item.use(board, 0, 0, {"box_row": 0, "box_col": 0})
	assert_true(result.has("bomb_effect"))
	assert_eq(result.bomb_effect.r, 0)
	assert_eq(result.bomb_effect.c, 0)

	# 验证左上宫被填满
	for r in range(0, 3):
		for c in range(0, 3):
			assert_ne(board.grid[r][c], 0, "Cell [%d,%d] should be filled by bomb" % [r, c])


func test_use_returns_dialogue() -> void:
	var grid := _make_test_grid()
	var given := _make_test_given()
	var solution := _make_complete_grid()
	board.load_puzzle(grid, given, solution)
	var result := item.use(board, 0, 0, {"box_row": 0, "box_col": 0})
	assert_true(result.has("dialogue"))
	assert_eq(result.dialogue, "item_bomb")


# ---- 辅助 ----

static func _empty_grid() -> Array:
	var grid := []
	for r in 9:
		grid.append([])
		for c in 9:
			grid[r].append(0)
	return grid


static func _make_test_grid() -> Array:
	var grid := _empty_grid()
	grid[0] = [5, 3, 0, 0, 0, 0, 0, 0, 0]
	return grid


static func _make_test_given() -> Array:
	var given := []
	for r in 9:
		given.append([])
		for c in 9:
			given[r].append(false)
	given[0][0] = true
	given[0][1] = true
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
