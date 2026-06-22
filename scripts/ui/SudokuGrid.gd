class_name SudokuGrid
extends Control
## SudokuGrid — 数独网格 _draw() 渲染
##
## 通过 render_state（GridRenderState）获取盘面数据。
## 功能增强：
## - 同数字高亮：选中已填数字格时，高亮所有相同数字的格
## - 选中格粗边框
## - 填入数字时短暂脉冲反馈

signal cell_selected(row: int, col: int)

const CELL_COUNT := 9
var cell_size: float = 0.0
var margin: float = 0.0
var draw_offset_x: float = 0.0

## 由 SudokuGame 注入的渲染状态
var render_state: GridRenderState = null

# ---- 脉冲动画状态（U3：Tween 驱动，无需 _process 追踪） ----
var _pulse_alpha: float = 0.0
var _pulse_r: int = -1
var _pulse_c: int = -1
var _pulse_tween: Tween = null


func _draw() -> void:
	if render_state == null:
		return
	if cell_size <= 0.0:
		_compute_cell_size()
	# 平移绘制坐标系，使九宫格在 Control 中居中
	if draw_offset_x != 0.0:
		draw_set_transform(Vector2(draw_offset_x, 0.0))
	_draw_backgrounds()
	_draw_same_number_highlight()
	_draw_grid_lines()
	_draw_numbers()
	_draw_notes()
	_draw_conflicts()
	_draw_selection()
	_draw_pulse()


func _compute_cell_size() -> void:
	var area: float = min(size.x, size.y)
	margin = area * 0.02
	cell_size = (area - margin * 2) / CELL_COUNT
	draw_offset_x = (size.x - area) / 2.0


## 绘制行/列/宫高亮 + 选中格背景
func _draw_backgrounds() -> void:
	# 行列宫高亮
	if render_state.selected_row >= 0:
		var color: Color = ThemeManager.get_color("highlight")
		# 行高亮
		_draw_rect(0, render_state.selected_row, CELL_COUNT, 1, color)
		# 列高亮
		_draw_rect(render_state.selected_col, 0, 1, CELL_COUNT, color)
		# 宫高亮
		var br := int(render_state.selected_row / 3.0) * 3
		var bc := int(render_state.selected_col / 3.0) * 3
		_draw_rect(bc, br, 3, 3, color)

	# 选中格背景
	if render_state.selected_row >= 0:
		var color: Color = ThemeManager.get_color("selected")
		_draw_rect(render_state.selected_col, render_state.selected_row, 1, 1, color)


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
	var font_size: int = maxi(1, int(cell_size * 0.6))
	var font: Font = get_theme_default_font()
	if not font:
		return

	var ascent: float = font.get_ascent(font_size)
	for r in CELL_COUNT:
		for c in CELL_COUNT:
			var val: int = render_state.grid[r][c]
			if val == 0:
				continue
			var color: Color = ThemeManager.get_color("user_number") if not render_state.given[r][c] else ThemeManager.get_color("given_number")
			var text: String = str(val)
			var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
			var x: float = margin + c * cell_size + (cell_size - text_size.x) / 2
			var y: float = margin + r * cell_size + (cell_size + ascent) / 2.0
			draw_string(font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


## 绘制笔记（候选数字，小号字体）
func _draw_notes() -> void:
	var font_size: int = maxi(1, int(cell_size * 0.25))
	var font: Font = get_theme_default_font()
	if not font:
		return

	var sub: float = cell_size / 3.0
	for r in CELL_COUNT:
		for c in CELL_COUNT:
			var mask: int = render_state.notes[r][c]
			if mask == 0:
				continue
			for n in range(1, 10):
				if mask & (1 << n):
					var sub_r: int = (n - 1) / 3
					var sub_c: int = (n - 1) % 3
					var text: String = str(n)
					var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
					var x: float = margin + c * cell_size + sub_c * sub + (sub - text_size.x) / 2
					var ascent: float = font.get_ascent(font_size)
					var y: float = margin + r * cell_size + sub_r * sub + (sub + ascent) / 2.0
					draw_string(font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ThemeManager.get_color("user_number"))


## 绘制选中格同数字高亮（半透明圆角矩形）
func _draw_same_number_highlight() -> void:
	if render_state.selected_row < 0:
		return
	var sel_val: int = render_state.grid[render_state.selected_row][render_state.selected_col]
	if sel_val == 0:
		return
	var color: Color = ThemeManager.get_color("highlight")
	for r in CELL_COUNT:
		for c in CELL_COUNT:
			if (r == render_state.selected_row and c == render_state.selected_col):
				continue
			if render_state.grid[r][c] == sel_val:
				_draw_rect(c, r, 1, 1, color)


## 绘制脉冲动画反馈（数字填入时短暂闪烁）
func _draw_pulse() -> void:
	if _pulse_alpha <= 0.0 or _pulse_r < 0:
		return
	var pulse_color := ThemeManager.get_color("primary")
	pulse_color.a = _pulse_alpha * 0.3
	_draw_rect(_pulse_c, _pulse_r, 1, 1, pulse_color)


## 触发脉冲动画（U3：Tween 驱动淡出，无需 SudokuGame 每帧调用 tick_pulse）
func trigger_pulse(row: int, col: int) -> void:
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_pulse_r = row
	_pulse_c = col
	_pulse_alpha = 1.0
	queue_redraw()
	_pulse_tween = create_tween().set_ease(Tween.EASE_OUT)
	_pulse_tween.tween_method(func(a): _pulse_alpha = a; queue_redraw(), 1.0, 0.0, 0.25)
	_pulse_tween.finished.connect(func():
		_pulse_alpha = 0.0
		_pulse_r = -1
		_pulse_c = -1
	, CONNECT_ONE_SHOT)


## 绘制冲突红框
func _draw_conflicts() -> void:
	var color: Color = ThemeManager.get_color("conflict")
	var w: float = max(1.5, cell_size / 40.0)
	for r in CELL_COUNT:
		for c in CELL_COUNT:
			if render_state.conflict[r][c]:
				var x: float = margin + c * cell_size
				var y: float = margin + r * cell_size
				draw_rect(Rect2(x, y, cell_size, cell_size), color, false, w)


## 绘制选中格边框
func _draw_selection() -> void:
	if render_state.selected_row < 0:
		return
	var color: Color = ThemeManager.get_color("primary")
	var w: float = max(2.0, cell_size / 25.0)
	var x: float = margin + render_state.selected_col * cell_size
	var y: float = margin + render_state.selected_row * cell_size
	draw_rect(Rect2(x, y, cell_size, cell_size), color, false, w)


func _gui_input(event: InputEvent) -> void:
	if render_state == null:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_pos: Vector2 = (event.position - Vector2(draw_offset_x + margin, margin))
		if local_pos.x >= 0 and local_pos.y >= 0:
			var col: int = int(local_pos.x / cell_size)
			var row: int = int(local_pos.y / cell_size)
			if row >= 0 and row < CELL_COUNT and col >= 0 and col < CELL_COUNT:
				cell_selected.emit(row, col)
				queue_redraw()


func _process(_delta: float) -> void:
	# 首次布局完成时初始化
	if cell_size <= 0.0 and size.x > 0 and size.y > 0:
		_compute_cell_size()
		queue_redraw()
		return
	# 响应窗口缩放
	if cell_size > 0:
		var area: float = min(size.x, size.y)
		var new_cell: float = (area - margin * 2) / CELL_COUNT
		if abs(new_cell - cell_size) > 1.0:
			cell_size = new_cell
			draw_offset_x = (size.x - area) / 2.0
			queue_redraw()
