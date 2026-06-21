class_name DialogAnimator
## DialogAnimator — 弹窗 Tween 动画工具
##
## 纯静态方法，提供统一的弹窗显示/隐藏动画。
## 消除 SudokuGame / SudokuMenu 之间的 Tween 重复代码。
##
## 调用方负责管理返回的 Tween 生命周期（如 exit_tree 时 kill）。

## 弹出弹窗（TRANS_BACK 缓入 + 缩放 + 淡入）
static func show(panel: Panel, node: Node) -> Tween:
	if not is_instance_valid(panel) or not is_instance_valid(node):
		return null
	var tween: Tween = node.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	panel.scale = Vector2(0.85, 0.85)
	panel.modulate.a = 0.0
	tween.set_parallel(true)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.25)
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)
	return tween


## 关闭弹窗（TRANS_QUAD 淡出 + 缩放后重置）
static func hide(panel: Panel, node: Node) -> Tween:
	if not is_instance_valid(panel) or not is_instance_valid(node):
		return null
	var tween: Tween = node.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.set_parallel(true)
	tween.tween_property(panel, "scale", Vector2(0.9, 0.9), 0.12)
	tween.tween_property(panel, "modulate:a", 0.0, 0.1)
	tween.tween_callback(func():
		if is_instance_valid(panel):
			panel.scale = Vector2.ONE
			panel.modulate.a = 1.0
	)
	return tween
