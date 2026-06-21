class_name ConfettiEffect
extends CPUParticles2D
## ConfettiEffect — 胜利撒花粒子效果
##
## 纯代码创建，无外部资源依赖。
## 自包含：在首次 process 中定位并发射，响应窗口缩放。

var _emitted := false


func _ready() -> void:
	amount = 80
	lifetime = 2.5
	one_shot = true
	explosiveness = 0.8
	randomness = 0.3
	fixed_fps = 30  # 移动端优化
	emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	emission_rect_extents = Vector2(200, 20)

	direction = Vector2.DOWN
	spread = 60.0
	gravity = Vector2(0, 180)
	initial_velocity_min = 150
	initial_velocity_max = 350
	angular_velocity_min = -360
	angular_velocity_max = 360
	scale_amount_min = 0.6
	scale_amount_max = 1.2

	# 多彩颜色渐变（CPUParticles2D.color_ramp 接收 Gradient，非 GradientTexture1D）
	var gradient := Gradient.new()
	gradient.add_point(0.0, Color(1.0, 0.2, 0.2))   # 红
	gradient.add_point(0.25, Color(1.0, 0.8, 0.0))   # 黄
	gradient.add_point(0.5, Color(0.2, 0.8, 0.3))    # 绿
	gradient.add_point(0.75, Color(0.2, 0.5, 1.0))   # 蓝
	gradient.add_point(1.0, Color(0.8, 0.3, 1.0))    # 紫
	color_ramp = gradient

	# 方形粒子（类似纸片）
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	self.texture = ImageTexture.create_from_image(img)

	finished.connect(_on_finished)


func _process(_delta: float) -> void:
	if not _emitted:
		_emitted = true
		_update_position()
		emitting = true


func _update_position() -> void:
	var parent := get_parent()
	if parent:
		position = Vector2(parent.size.x / 2.0, -20)


func _on_finished() -> void:
	queue_free()
