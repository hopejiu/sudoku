extends Control
## LoadingSpinner — 循环加载旋转动画组件
## 绘制 Material Design 风格旋转弧线指示器

var angle: float = 0.0
var line_color: Color = Color.WHITE

func _draw() -> void:
	if line_color.a < 0.01:
		return
	var center: Vector2 = size / 2
	var radius: float = min(size.x, size.y) / 2 - 8.0
	if radius <= 4:
		return

	# 淡色轨道
	var track_color := line_color * Color(1, 1, 1, 0.12)
	_draw_arc(center, radius, 0, 360, track_color, 3.0)

	# 旋转弧线（70度）
	var arc_len := 70.0
	_draw_arc(center, radius, angle, angle + arc_len, line_color, 3.5)

	# 端点圆点（让弧线两端圆润）
	var a_start := deg_to_rad(angle)
	var a_end := deg_to_rad(angle + arc_len)
	draw_circle(center + Vector2(cos(a_start), sin(a_start)) * radius, 2.5, line_color)
	draw_circle(center + Vector2(cos(a_end), sin(a_end)) * radius, 2.5, line_color)


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
