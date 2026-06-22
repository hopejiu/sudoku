extends GutTest
## test_item_magnifier.gd — ItemMagnifier 单元测试

const ItemMagnifier := preload("res://scripts/game/items/ItemMagnifier.gd")
const SudokuBoard := preload("res://scripts/game/board/SudokuBoard.gd")


var item: ItemMagnifier
var board: SudokuBoard


func before_each() -> void:
	item = ItemMagnifier.new()
	board = SudokuBoard.new()


func after_each() -> void:
	item = null
	board = null


func test_item_id() -> void:
	assert_eq(item.get_item_id(), &"magnifier")


func test_display_name() -> void:
	assert_eq(item.get_display_name(), "放大镜")


func test_description() -> void:
	assert_ne(item.get_description(), "")


func test_price() -> void:
	assert_eq(item.get_price(), 20)


func test_can_use_always_true() -> void:
	assert_true(item.can_use(board, 0, 0))
	assert_true(item.can_use(board, 4, 4))


func test_use_returns_hint_bonus() -> void:
	var result := item.use(board, 0, 0)
	assert_true(result.has("hint_bonus"))
	assert_eq(result.hint_bonus, 1)


func test_use_returns_flash() -> void:
	var result := item.use(board, 0, 0)
	assert_true(result.has("flash"))
	assert_true(result.flash)


func test_use_returns_dialogue() -> void:
	var result := item.use(board, 0, 0)
	assert_true(result.has("dialogue"))
	assert_eq(result.dialogue, "item_magnifier")


func test_use_returns_hint_text() -> void:
	var result := item.use(board, 0, 0)
	assert_true(result.has("hint_text"))
	assert_ne(result.hint_text, "")
