class_name SudokuGrid
extends Control
## SudokuGrid — 数独网格 _draw() 渲染
##
## 通过 render_state（GridRenderState）获取盘面数据。
## 增强功能：
## - 同数字高亮
## - 选中格粗边框
## - 触发脉冲反馈
## - 炸弹瞄准模式（拖动选择 3×3 宫）
## - 炸弹揭露特效

signal cell_selected(row: int, col: int)
signal bomb_target_selected(box_row: int, box_col: int)

const CELL_COUNT := 9
var cell_size: float = 0.0
var margin: float = 0.0
var draw_offset_x: float = 0.0

## 由 SudokuGame 注入的渲染状态
var render_state: GridRenderState = null

# ---- 脉冲动画状态 ----
var _pulse_alpha: float = 0.0
var _pulse_r: int = -1
var _pulse_c: int = -1
var _pulse_tween: Tween = null

# ---- 闪光动画状态 ----
var _flash_alpha: float = 0.0
var _flash_tween: Tween = null

# ---- 炸弹瞄准模式 ----
var _bomb_mode: bool = false
var _bomb_hover_box_r: int = -1  # 3×3 宫行索引 (0,3,6)
var _bomb_hover_box_c: int = -1

# ---- 炸弹揭露特效 ----
var _bomb_effect_alpha: float = 0.0
var _bomb_effect_r: int = -1
var _bomb_effect_c: int = -1
var _bomb_effect_tween: Tween = null

# ---- 技能揭露连线动画 ----
var _reveal_line_alpha: float = 0.0
var _reveal_from_r: int = -1
var _reveal_from_c: int = -1
var _reveal_to_r: int = -1
var _reveal_to_c: int = -1
var _reveal_line_tween: Tween = null

# ---- 技能揭露目标高亮（强力脉冲） ----
var _reveal_highlight_alpha: float = 0.0
var _reveal_highlight_r: int = -1
var _reveal_highlight_c: int = -1
var _reveal_highlight_tween: Tween = null


func _draw() -> void:
	if render_state == null:
		return
	if cell_size <= 0.0:
		_compute_cell_size()
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
	_draw_flash()
	_draw_bomb_hover()
	_draw_bomb_effect()
	_draw_reveal_line()
	_draw_reveal_highlight()


func _compute_cell_size() -> void:
	var area: float = min(size.x, size.y)
	margin = area * 0.02
	cell_size = (area - margin * 2) / CELL_COUNT
	draw_offset_x = (size.x - area) / 2.0


func _draw_backgrounds() -> void:
	if render_state.selected_row >= 0:
		var color: Color = ThemeManager.get_color("highlight")
		_draw_rect(0, render_state.selected_row, CELL_COUNT, 1, color)
		_draw_rect(render_state.selected_col, 0, 1, CELL_COUNT, color)
		var br := int(render_state.selected_row / 3.0) * 3
		var bc := int(render_state.selected_col / 3.0) * 3
		_draw_rect(bc, br, 3, 3, color)
	if render_state.selected_row >= 0:
		var color: Color = ThemeManager.get_color("selected")
		_draw_rect(render_state.selected_col, render_state.selected_row, 1, 1, color)


func _draw_rect(col: float, row: float, w: int, h: int, color: Color) -> void:
	var x: float = margin + col * cell_size
	var y: float = margin + row * cell_size
	draw_rect(Rect2(x, y, w * cell_size, h * cell_size), color, true)


func _draw_box_outline(row: int, col: int, w: int, h: int, color: Color, thickness: float) -> void:
	var x: float = margin + col * cell_size
	var y: float = margin + row * cell_size
	var bw: float = w * cell_size
	var bh: float = h * cell_size
	draw_line(Vector2(x, y), Vector2(x + bw, y), color, thickness)
	draw_line(Vector2(x + bw, y), Vector2(x + bw, y + bh), color, thickness)
	draw_line(Vector2(x + bw, y + bh), Vector2(x, y + bh), color, thickness)
	draw_line(Vector2(x, y + bh), Vector2(x, y), color, thickness)


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


func _draw_pulse() -> void:
	if _pulse_alpha <= 0.0 or _pulse_r < 0:
		return
	var pulse_color := ThemeManager.get_color("primary")
	pulse_color.a = _pulse_alpha * 0.3
	_draw_rect(_pulse_c, _pulse_r, 1, 1, pulse_color)


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


# ---- 闪光特效（放大镜使用反馈） ----

func trigger_flash() -> void:
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash_alpha = 1.0
	queue_redraw()
	_flash_tween = create_tween().set_ease(Tween.EASE_OUT)
	_flash_tween.tween_method(func(a): _flash_alpha = a; queue_redraw(), 1.0, 0.0, 0.4)
	_flash_tween.finished.connect(func():
		_flash_alpha = 0.0
	, CONNECT_ONE_SHOT)


func _draw_flash() -> void:
	if _flash_alpha <= 0.0:
		return
	var white := Color.WHITE
	white.a = _flash_alpha * 0.35
	_draw_rect(0, 0, CELL_COUNT, CELL_COUNT, white)


# ---- 技能揭露连线动画 ----

## 触发连线动画：从区域中心 → 目标格子
func trigger_reveal_line(from_row: int, from_col: int, to_row: int, to_col: int) -> void:
	if _reveal_line_tween and _reveal_line_tween.is_valid():
		_reveal_line_tween.kill()
	_reveal_from_r = from_row
	_reveal_from_c = from_col
	_reveal_to_r = to_row
	_reveal_to_c = to_col
	_reveal_line_alpha = 0.0
	queue_redraw()
	_reveal_line_tween = create_tween().set_ease(Tween.EASE_OUT)
	_reveal_line_tween.tween_method(func(a): _reveal_line_alpha = a; queue_redraw(), 0.0, 1.0, 0.35)
	_reveal_line_tween.finished.connect(func():
		_reveal_line_alpha = 0.0
		_reveal_from_r = -1
		_reveal_from_c = -1
		_reveal_to_r = -1
		_reveal_to_c = -1
	, CONNECT_ONE_SHOT)


func _draw_reveal_line() -> void:
	if _reveal_line_alpha <= 0.0 or _reveal_from_r < 0:
		return
	var color := ThemeManager.get_color("primary")
	color.a = _reveal_line_alpha * 0.7
	var w: float = max(1.5, cell_size / 35.0)
	# 计算起点（区域中心）和终点（目标格中心）
	var x1: float = margin + (_reveal_from_c + 0.5) * cell_size * (3 if _reveal_from_c < 9 else 1)
	var y1: float = margin + (_reveal_from_r + 0.5) * cell_size * (3 if _reveal_from_r < 9 else 1)
	var x2: float = margin + (_reveal_to_c + 0.5) * cell_size
	var y2: float = margin + (_reveal_to_r + 0.5) * cell_size
	draw_line(Vector2(x1, y1), Vector2(x2, y2), color, w, true)


# ---- 技能揭露目标高亮（强力脉冲） ----

func trigger_reveal_highlight(row: int, col: int) -> void:
	if _reveal_highlight_tween and _reveal_highlight_tween.is_valid():
		_reveal_highlight_tween.kill()
	_reveal_highlight_r = row
	_reveal_highlight_c = col
	_reveal_highlight_alpha = 1.0
	queue_redraw()
	_reveal_highlight_tween = create_tween().set_ease(Tween.EASE_OUT)
	_reveal_highlight_tween.tween_method(func(a): _reveal_highlight_alpha = a; queue_redraw(), 1.0, 0.0, 0.6)
	_reveal_highlight_tween.finished.connect(func():
		_reveal_highlight_alpha = 0.0
		_reveal_highlight_r = -1
		_reveal_highlight_c = -1
	, CONNECT_ONE_SHOT)


func _draw_reveal_highlight() -> void:
	if _reveal_highlight_alpha <= 0.0 or _reveal_highlight_r < 0:
		return
	# 外发光
	var glow := ThemeManager.get_color("primary")
	glow.a = _reveal_highlight_alpha * 0.25
	var expand := (1.0 - _reveal_highlight_alpha) * 0.1
	var x: float = margin + _reveal_highlight_c * cell_size - expand * cell_size / 2.0
	var y: float = margin + _reveal_highlight_r * cell_size - expand * cell_size / 2.0
	var w: float = cell_size * (1.0 + expand)
	draw_rect(Rect2(x, y, w, w), glow, true)
	# 边框高亮
	var border_color := ThemeManager.get_color("primary")
	border_color.a = _reveal_highlight_alpha * 0.8
	var bw: float = max(2.5, cell_size / 20.0)
	_draw_cell_outline(_reveal_highlight_r, _reveal_highlight_c, border_color, bw)


func _draw_cell_outline(row: int, col: int, color: Color, thickness: float) -> void:
	var x: float = margin + col * cell_size
	var y: float = margin + row * cell_size
	draw_line(Vector2(x, y), Vector2(x + cell_size, y), color, thickness)
	draw_line(Vector2(x + cell_size, y), Vector2(x + cell_size, y + cell_size), color, thickness)
	draw_line(Vector2(x + cell_size, y + cell_size), Vector2(x, y + cell_size), color, thickness)
	draw_line(Vector2(x, y + cell_size), Vector2(x, y), color, thickness)


# ---- 炸弹瞄准模式 ----

func enter_bomb_mode() -> void:
	_bomb_mode = true
	_bomb_hover_box_r = -1
	_bomb_hover_box_c = -1


func exit_bomb_mode() -> void:
	_bomb_mode = false
	_bomb_hover_box_r = -1
	_bomb_hover_box_c = -1
	queue_redraw()


func _draw_bomb_hover() -> void:
	if not _bomb_mode or _bomb_hover_box_r < 0:
		return
	var red := Color(1, 0, 0, 0.35)
	_draw_rect(_bomb_hover_box_c, _bomb_hover_box_r, 3, 3, red)
	var border_red := Color(1, 0.2, 0.2, 0.8)
	_draw_box_outline(_bomb_hover_box_r, _bomb_hover_box_c, 3, 3, border_red, max(2.5, cell_size / 20.0))


# ---- 炸弹揭露特效 ----

func trigger_bomb_effect(box_row: int, box_col: int) -> void:
	_bomb_effect_r = box_row
	_bomb_effect_c = box_col
	_bomb_mode = false  # 退出瞄准
	_bomb_hover_box_r = -1
	_bomb_hover_box_c = -1
	if _bomb_effect_tween and _bomb_effect_tween.is_valid():
		_bomb_effect_tween.kill()
	_bomb_effect_alpha = 1.0
	queue_redraw()
	_bomb_effect_tween = create_tween().set_ease(Tween.EASE_OUT)
	_bomb_effect_tween.tween_method(func(a): _bomb_effect_alpha = a; queue_redraw(), 1.0, 0.0, 0.6)
	_bomb_effect_tween.finished.connect(func():
		_bomb_effect_alpha = 0.0
		_bomb_effect_r = -1
		_bomb_effect_c = -1
	, CONNECT_ONE_SHOT)


func _draw_bomb_effect() -> void:
	if _bomb_effect_alpha <= 0.0 or _bomb_effect_r < 0:
		return
	# 爆炸膨胀效果
	var expand := (1.0 - _bomb_effect_alpha) * 0.15  # 膨胀 15%
	var color := Color(1.0, 0.5, 0.0, _bomb_effect_alpha * 0.4)  # 橙红
	var x: float = margin + _bomb_effect_c * cell_size - expand * cell_size * 3 / 2
	var y: float = margin + _bomb_effect_r * cell_size - expand * cell_size * 3 / 2
	var w: float = cell_size * 3 * (1 + expand * 2)
	var h: float = cell_size * 3 * (1 + expand * 2)
	draw_rect(Rect2(x, y, w, h), color, true)
	# 边框闪光
	var flash := Color(1.0, 0.8, 0.2, _bomb_effect_alpha * 0.7)
	_draw_box_outline(_bomb_effect_r, _bomb_effect_c, 3, 3, flash, max(3.0, cell_size / 15.0))


# ---- 冲突红框 ----

func _draw_conflicts() -> void:
	var color: Color = ThemeManager.get_color("conflict")
	var w: float = max(1.5, cell_size / 40.0)
	for r in CELL_COUNT:
		for c in CELL_COUNT:
			if render_state.conflict[r][c]:
				var x: float = margin + c * cell_size
				var y: float = margin + r * cell_size
				draw_rect(Rect2(x, y, cell_size, cell_size), color, false, w)


func _draw_selection() -> void:
	if render_state.selected_row < 0:
		return
	# 炸弹模式下不绘制普通选中边框（避免干扰红色高亮）
	if _bomb_mode:
		return
	var color: Color = ThemeManager.get_color("primary")
	var w: float = max(2.0, cell_size / 25.0)
	var x: float = margin + render_state.selected_col * cell_size
	var y: float = margin + render_state.selected_row * cell_size
	draw_rect(Rect2(x, y, cell_size, cell_size), color, false, w)


func _gui_input(event: InputEvent) -> void:
	if render_state == null:
		return

	# ---- 炸弹瞄准模式 ----
	if _bomb_mode:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# 点击/释放 → 确认炸弹目标
			if _bomb_hover_box_r >= 0:
				var box_r: int = _bomb_hover_box_r
				var box_c: int = _bomb_hover_box_c
				exit_bomb_mode()
				bomb_target_selected.emit(box_r, box_c)
			return
		if event is InputEventMouseMotion:
			var local_pos: Vector2 = (event.position - Vector2(draw_offset_x + margin, margin))
			if local_pos.x >= 0 and local_pos.y >= 0:
				var col: int = int(local_pos.x / cell_size)
				var row: int = int(local_pos.y / cell_size)
				if row >= 0 and row < CELL_COUNT and col >= 0 and col < CELL_COUNT:
					# 计算 3×3 宫
					var box_r: int = int(row / 3) * 3
					var box_c: int = int(col / 3) * 3
					if box_r != _bomb_hover_box_r or box_c != _bomb_hover_box_c:
						_bomb_hover_box_r = box_r
						_bomb_hover_box_c = box_c
						queue_redraw()
			return
		# 炸弹模式下吃掉所有事件
		return

	# ---- 普通模式 ----
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_pos: Vector2 = (event.position - Vector2(draw_offset_x + margin, margin))
		if local_pos.x >= 0 and local_pos.y >= 0:
			var col: int = int(local_pos.x / cell_size)
			var row: int = int(local_pos.y / cell_size)
			if row >= 0 and row < CELL_COUNT and col >= 0 and col < CELL_COUNT:
				cell_selected.emit(row, col)
				queue_redraw()


func _process(_delta: float) -> void:
	if cell_size <= 0.0 and size.x > 0 and size.y > 0:
		_compute_cell_size()
		queue_redraw()
		return
	if cell_size > 0:
		var area: float = min(size.x, size.y)
		var new_cell: float = (area - margin * 2) / CELL_COUNT
		if abs(new_cell - cell_size) > 1.0:
			cell_size = new_cell
			draw_offset_x = (size.x - area) / 2.0
			queue_redraw()
