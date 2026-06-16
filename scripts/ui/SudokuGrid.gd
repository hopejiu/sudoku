extends Control
## SudokuGrid — 数独网格 _draw() 渲染
## 附着在 SudokuGame.tscn 中的网格节点上。
## 通过 parent (SudokuGame.gd) 访问 board 数据。

const CELL_COUNT := 9
var cell_size: float = 0.0
var margin: float = 0.0

@onready var game: SudokuGame = owner as SudokuGame


func _draw() -> void:
	if cell_size <= 0.0:
		_compute_cell_size()
	_draw_backgrounds()
	_draw_grid_lines()
	_draw_numbers()
	_draw_notes()
	_draw_conflicts()
	_draw_selection()


func _compute_cell_size() -> void:
	var area: float = min(size.x, size.y)
	margin = area * 0.02
	cell_size = (area - margin * 2) / CELL_COUNT


## 绘制行/列/宫高亮 + 选中格背景
func _draw_backgrounds() -> void:
	# 行列宫高亮
	if game.selected_row >= 0:
		var color: Color = ThemeManager.get_color("highlight")
		# 行高亮
		_draw_rect(0, game.selected_row, CELL_COUNT, 1, color)
		# 列高亮
		_draw_rect(game.selected_col, 0, 1, CELL_COUNT, color)
		# 宫高亮
		var br: float = (game.selected_row / 3) * 3
		var bc: float = (game.selected_col / 3) * 3
		_draw_rect(bc, br, 3, 3, color)

	# 选中格背景
	if game.selected_row >= 0:
		var color: Color = ThemeManager.get_color("selected")
		_draw_rect(game.selected_col, game.selected_row, 1, 1, color)


func _draw_rect(col: float, row: float, w: int, h: int, color: Color) -> void:
	var x: float = margin + col * cell_size
	var y: float = margin + row * cell_size
	draw_rect(Rect2(x, y, w * cell_size, h * cell_size), color, true)


## 绘制网格线
func _draw_grid_lines() -> void:
	var line_color: Color = ThemeManager.get_color("grid_line")
	var box_color: Color = ThemeManager.get_color("box_line")
	var thin: float = max(1.0, cell_size / 60.0)
	var thick: float = max(2.0, cell_size / 30.0)

	for i in range(CELL_COUNT + 1):
		var w: float = thick if i % 3 == 0 else thin
		var x: float = margin + i * cell_size
		var y1: float = margin
		var y2: float = margin + CELL_COUNT * cell_size
		draw_line(Vector2(x, y1), Vector2(x, y2), box_color if i % 3 == 0 else line_color, w)

	for i in range(CELL_COUNT + 1):
		var w: float = thick if i % 3 == 0 else thin
		var y: float = margin + i * cell_size
		var x1: float = margin
		var x2: float = margin + CELL_COUNT * cell_size
		draw_line(Vector2(x1, y), Vector2(x2, y), box_color if i % 3 == 0 else line_color, w)


## 绘制数字
func _draw_numbers() -> void:
	var font_size: int = int(cell_size * 0.6)
	var theme: Theme = ThemeDB.get_project_theme()
	var font: Font = theme.default_font if theme else null
	if not font:
		return

	for r in CELL_COUNT:
		for c in CELL_COUNT:
			var val: int = game.board.grid[r][c]
			if val == 0:
				continue
			var color: Color = ThemeManager.get_color("user_number") if not game.board.given[r][c] else ThemeManager.get_color("given_number")
			var text: String = str(val)
			var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
			var x: float = margin + c * cell_size + (cell_size - text_size.x) / 2
			var y: float = margin + r * cell_size + (cell_size + text_size.y) / 2
			draw_string(font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


## 绘制笔记（候选数字，小号字体）
func _draw_notes() -> void:
	var font_size: int = int(cell_size * 0.25)
	var theme: Theme = ThemeDB.get_project_theme()
	var font: Font = theme.default_font if theme else null
	if not font:
		return

	var sub: float = cell_size / 3.0
	for r in CELL_COUNT:
		for c in CELL_COUNT:
			var mask: int = game.board.notes[r][c]
			if mask == 0:
				continue
			for n in range(1, 10):
				if mask & (1 << n):
					var sub_r: float = (n - 1) / 3
					var sub_c: int = (n - 1) % 3
					var text: String = str(n)
					var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
					var x: float = margin + c * cell_size + sub_c * sub + (sub - text_size.x) / 2
					var y: float = margin + r * cell_size + sub_r * sub + (sub + text_size.y) / 2
					draw_string(font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ThemeManager.get_color("user_number"))


## 绘制冲突红框
func _draw_conflicts() -> void:
	var color: Color = ThemeManager.get_color("conflict")
	var w: float = max(1.5, cell_size / 40.0)
	for r in CELL_COUNT:
		for c in CELL_COUNT:
			if game.board.conflict[r][c]:
				var x: float = margin + c * cell_size
				var y: float = margin + r * cell_size
				draw_rect(Rect2(x, y, cell_size, cell_size), color, false, w)


## 绘制选中格边框
func _draw_selection() -> void:
	if game.selected_row < 0:
		return
	var color: Color = ThemeManager.get_color("primary")
	var w: float = max(2.0, cell_size / 25.0)
	var x: float = margin + game.selected_col * cell_size
	var y: float = margin + game.selected_row * cell_size
	draw_rect(Rect2(x, y, cell_size, cell_size), color, false, w)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_pos: Vector2 = (event.position - Vector2(margin, margin))
		if local_pos.x >= 0 and local_pos.y >= 0:
			var col: int = int(local_pos.x / cell_size)
			var row: int = int(local_pos.y / cell_size)
			if row >= 0 and row < CELL_COUNT and col >= 0 and col < CELL_COUNT:
				game.selected_row = row
				game.selected_col = col
				queue_redraw()


func _process(_delta: float) -> void:
	# 响应窗口缩放
	if cell_size > 0:
		var area: float = min(size.x, size.y)
		var new_cell: float = (area - margin * 2) / CELL_COUNT
		if abs(new_cell - cell_size) > 1.0:
			cell_size = new_cell
			queue_redraw()
