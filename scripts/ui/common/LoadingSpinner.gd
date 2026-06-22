extends Control
## LoadingSpinner — 循环加载旋转动画组件
## 自管理旋转角度，无需父节点驱动（U5 优化）。
## 绘制 Material Design 风格旋转弧线指示器

var _angle: float = 0.0
var _speed: float = 240.0  # 度/秒


func _process(delta: float) -> void:
	_angle = fmod(_angle + delta * _speed, 360.0)
	queue_redraw()


func _draw() -> void:
	var color := ThemeManager.get_color("primary")
	if color.a < 0.01:
		return
	var center: Vector2 = size / 2
	var radius: float = min(size.x, size.y) / 2 - 8.0
	if radius <= 4:
		return

	# 淡色轨道
	var track_color := color * Color(1, 1, 1, 0.12)
	_draw_arc(center, radius, 0, 360, track_color, 3.0)

	# 旋转弧线（70度）
	var arc_len := 70.0
	_draw_arc(center, radius, _angle, _angle + arc_len, color, 3.5)

	# 端点圆点
	var a_start := deg_to_rad(_angle)
	var a_end := deg_to_rad(_angle + arc_len)
	draw_circle(center + Vector2(cos(a_start), sin(a_start)) * radius, 2.5, color)
	draw_circle(center + Vector2(cos(a_end), sin(a_end)) * radius, 2.5, color)


func _draw_arc(center: Vector2, radius: float, from_deg: float, to_deg: float, color: Color, width: float) -> void:
	var segments := maxi(int(radius * 0.4), 12)
	if segments < 3:
		return
	var da := deg_to_rad(to_deg - from_deg) / segments
	var a0 := deg_to_rad(from_deg)
	for i in segments:
		var a1 := a0 + da
		draw_line(
			center + Vector2(cos(a0), sin(a0)) * radius,
			center + Vector2(cos(a1), sin(a1)) * radius,
			color, width, true
		)
		a0 = a1
