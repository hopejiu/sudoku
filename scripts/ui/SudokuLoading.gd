extends Control
## SudokuLoading — 数独加载场景
##
## 预生成谜题到队列（最多 3 个），避免实时生成卡顿。
## 队首为当前游戏，队尾为预生成储备。
##
## 流程：
##   1. 从 SceneParams 获取 action 和 level
##   2. 检查队列中有无该难度条目
##   3. 有 → 取出使用，跳转游戏
##   4. 无 → 后台线程生成，填满队列到 3 个，取队首跳转

const SceneTransition := preload("res://scripts/ui/SceneTransition.gd")

@onready var bg: ColorRect = %Bg
@onready var spinner: Control = %Spinner
@onready var loading_text: Label = %LoadingText

var _action: String = ""
var _level: int = 8
var _generate_thread: Thread = null
var _is_generating: bool = false
var _generated_results: Array = []  # 批量生成结果缓存
var _spinner_angle: float = 0.0
var _text_pulse: float = 0.0


func _ready() -> void:
	ThemeManager.theme_changed.connect(_on_theme_changed)
	_on_theme_changed(ThemeManager.current_theme_name)

	var params: Dictionary = SceneParams.get_param("next_game", {})
	_action = params.get("action", "new")
	_level = params.get("level", 8)

	# 入场淡入
	bg.modulate = Color(1, 1, 1, 0)
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(bg, "modulate", Color.WHITE, 0.15)
	await tween.finished
	await get_tree().process_frame
	_start_loading()


func _exit_tree() -> void:
	if _generate_thread and _generate_thread.is_alive():
		_generate_thread.wait_to_finish()


func _on_theme_changed(_name: String) -> void:
	bg.color = ThemeManager.get_color("background")
	if is_instance_valid(spinner):
		(spinner as Control).queue_redraw()


# --------------------------------------------------------------------------
# 加载流程
# --------------------------------------------------------------------------

func _start_loading() -> void:
	match _action:
		"continue":
			_check_continue()
		"history_replay":
			_prepare_history_replay()
		_:
			_find_or_generate(_level)


## 继续上局：取队首
func _check_continue() -> void:
	var queue := SaveManager.load_queue()
	if queue.is_empty():
		loading_text.text = "没有已保存的游戏…"
		await get_tree().create_timer(0.6).timeout
		_action = "new"
		_find_or_generate(8)
		return
	var entry: Dictionary = queue[0]
	_level = entry.get("level", 8)
	# 不弹出，游戏场景会直接读队首
	_proceed_to_game()


## 历史重开：将历史谜题插入队首
func _prepare_history_replay() -> void:
	var params: Dictionary = SceneParams.get_param("next_game", {})
	var snapshot: Dictionary = params.get("board_snapshot", {})
	var lvl: int = params.get("level", 8)

	if snapshot.is_empty():
		loading_text.text = "历史数据异常，重新生成…"
		await get_tree().create_timer(0.5).timeout
		_action = "new"
		_find_or_generate(lvl)
		return

	var data := {
		"board": snapshot,
		"level": lvl,
		"elapsed_time": 0.0,
		"streak": 0,
	}
	SaveManager.queue_push_front(data)
	_proceed_to_game()


## 从队列查找匹配难度的条目，找不到则生成
func _find_or_generate(lvl: int) -> void:
	var queue := SaveManager.load_queue()
	# 查找队列中是否有匹配难度的条目
	for i in queue.size():
		if queue[i].get("level") == lvl:
			# 找到，移到队首即可（游戏场景直接读队首）
			if i > 0:
				var entry = queue[i]
				queue.remove_at(i)
				queue.push_front(entry)
				SaveManager.save_queue(queue)
			_proceed_to_game()
			return

	# 需要生成，计算需要多少个：取 1 个来玩，队列低于 3 则填充到 3
	var needed := 1
	if queue.size() < 3:
		needed = 3 - queue.size()
	# 但至少要生成 1 个
	needed = max(1, needed)

	_is_generating = true
	loading_text.text = "正在生成数独…"
	_generated_results = []
	_generate_thread = Thread.new()
	_generate_thread.start(_generate_batch.bind(lvl, needed))


static func _generate_batch(lvl: int, count: int) -> Array:
	var results = []
	for i in count:
		results.append(SudokuGenerator.generate(lvl))
	return results


func _on_generation_completed(results: Array) -> void:
	_is_generating = false
	_generate_thread = null

	var queue := SaveManager.load_queue()
	for i in results.size():
		var entry := _make_entry(results[i], _level)
		if i == 0:
			# 第一个推到队首，是当前要玩的
			queue.push_front(entry)
		else:
			# 其余的推到队尾，作为预生成储备
			queue.append(entry)
	SaveManager.save_queue(queue)

	loading_text.text = "准备就绪！"
	await get_tree().create_timer(0.3).timeout
	_proceed_to_game()


## 构造游戏条目数据
static func _make_entry(result: Dictionary, lvl: int) -> Dictionary:
	var notes := []
	for r in 9:
		notes.append([])
		for c in 9:
			notes[r].append(0)
	return {
		"board": {
			"grid": result.grid,
			"given": result.given,
			"notes": notes,
			"undo_stack": [],
			"hint_count": 0,
			"solution": result.solution,
		},
		"level": lvl,
		"elapsed_time": 0.0,
		"streak": 0,
	}


## 跳转至游戏场景
func _proceed_to_game() -> void:
	SceneParams.set_param("next_game", {"action": _action, "level": _level})
	SceneTransition.change_to("res://scenes/sudoku/SudokuGame.tscn")


# --------------------------------------------------------------------------
# 动画循环
# --------------------------------------------------------------------------

func _process(delta: float) -> void:
	# 旋转角度
	_spinner_angle = fmod(_spinner_angle + delta * 240.0, 360.0)

	# 文字脉冲
	_text_pulse = fmod(_text_pulse + delta, 2.0)
	var alpha := 1.0
	if _text_pulse < 1.0:
		alpha = 0.5 + 0.5 * _text_pulse
	else:
		alpha = 1.0 - 0.5 * (_text_pulse - 1.0)
	loading_text.modulate = Color(1, 1, 1, alpha)

	# 更新旋转器
	if is_instance_valid(spinner):
		var sp := spinner as Control
		sp.angle = _spinner_angle
		sp.line_color = ThemeManager.get_color("primary")
		sp.queue_redraw()

	# 检查线程完成
	if _is_generating and _generate_thread and not _generate_thread.is_alive():
		var results: Array = _generate_thread.wait_to_finish()
		_on_generation_completed(results)


# --------------------------------------------------------------------------
# 输入
# --------------------------------------------------------------------------

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if not _is_generating:
			SceneTransition.change_to("res://scenes/main/Main.tscn")
