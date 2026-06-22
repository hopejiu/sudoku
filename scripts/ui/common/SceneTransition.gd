extends RefCounted
## SceneTransition — 场景切换淡入淡出工具
##
## 静态方法，提供统一过渡效果。
## 调用方式：
##   SceneTransition.change_to("res://scenes/main/Main.tscn")
##
## 原理：在当前场景创建全屏 CanvasLayer → ColorRect，
## 执行淡入（黑屏）→ 切换场景 → 新场景 _ready 中执行淡出。

const FADE_DURATION := 0.2
const HOLD_DURATION := 0.05

static func change_to(scene_path: String) -> void:
	var tree: SceneTree = Engine.get_main_loop()
	if not tree:
		printerr("[SceneTransition] no SceneTree")
		return

	var root: Window = tree.root
	if not root:
		printerr("[SceneTransition] no root")
		tree.change_scene_to_file(scene_path)
		return

	# 创建 CanvasLayer + ColorRect 覆盖层
	var layer := CanvasLayer.new()
	layer.layer = 128  # 顶层
	root.add_child(layer)

	var rect := ColorRect.new()
	rect.color = Color(0, 0, 0, 0)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_STOP  # 阻止点击穿透
	layer.add_child(rect)

	# 淡入
	var tween := tree.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(rect, "color:a", 1.0, FADE_DURATION)
	await tween.finished

	# 切场景
	tree.change_scene_to_file(scene_path)

	# 等待新场景加载完成
	await tree.process_frame

	# layer 已在 root 上（change_scene_to_file 只替换当前场景，不清 root 其他子节点）
	if not is_instance_valid(rect):
		return

	var tween2 := tree.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween2.tween_property(rect, "color:a", 0.0, FADE_DURATION)
	await tween2.finished

	layer.queue_free()


## 非阻塞版本 — 直接返回，淡入 + 切换异步执行
static func change_to_async(scene_path: String) -> void:
	change_to(scene_path)
