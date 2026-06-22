class_name DialogAnimator
## DialogAnimator — 弹窗 Tween 动画工具
##
## 纯静态方法，提供统一的弹窗显示/隐藏动画。
## - 显示：TRANS_BACK 弹性缓入 + 缩放 + 淡入
## - 隐藏：TRANS_CUBIC 缓出 + 缩放收缩 + 淡出
## Tween 绑定到 SceneTree，避免场景卸载时悬挂引用（U2 优化）。

## 弹出弹窗（弹性缓入 + 缩放 + 淡入）
static func show(panel: Panel, node: Node) -> Tween:
	if not is_instance_valid(panel) or not is_instance_valid(node):
		return null
	var tree := node.get_tree()
	var tween: Tween
	if tree:
		tween = tree.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		tween = node.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	panel.scale = Vector2(0.82, 0.82)
	panel.modulate.a = 0.0
	tween.set_parallel(true)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.3)
	tween.tween_property(panel, "modulate:a", 1.0, 0.25)
	return tween


## 关闭弹窗（平滑收缩 + 淡出）
static func hide(panel: Panel, node: Node) -> Tween:
	if not is_instance_valid(panel) or not is_instance_valid(node):
		return null
	var tree := node.get_tree()
	var tween: Tween
	if tree:
		tween = tree.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	else:
		tween = node.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.set_parallel(true)
	tween.tween_property(panel, "scale", Vector2(0.88, 0.88), 0.15)
	tween.tween_property(panel, "modulate:a", 0.0, 0.12)
	tween.tween_callback(func():
		if is_instance_valid(panel):
			panel.scale = Vector2.ONE
			panel.modulate.a = 1.0
	)
	return tween


## 显示遮罩（淡入，独立于弹窗动画）
static func show_overlay(overlay: ColorRect, node: Node) -> Tween:
	if not is_instance_valid(overlay) or not is_instance_valid(node):
		return null
	var tree := node.get_tree()
	var tween: Tween
	if tree:
		tween = tree.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		tween = node.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	overlay.modulate = Color(1, 1, 1, 0)
	overlay.show()
	tween.tween_property(overlay, "modulate", Color.WHITE, 0.2)
	return tween


## 隐藏遮罩（淡出）
static func hide_overlay(overlay: ColorRect, node: Node) -> Tween:
	if not is_instance_valid(overlay) or not is_instance_valid(node):
		return null
	var tree := node.get_tree()
	var tween: Tween
	if tree:
		tween = tree.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	else:
		tween = node.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(overlay, "modulate", Color(1, 1, 1, 0), 0.15)
	tween.tween_callback(func():
		if is_instance_valid(overlay):
			overlay.hide()
			overlay.modulate = Color.WHITE
	)
	return tween
