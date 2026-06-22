extends Control
## SudokuLoading — 数独加载场景
##
## 预生成谜题到队列（最多 3 个），避免实时生成卡顿。
## 队首为当前游戏，队尾为预生成储备。
##
## 流程：
##   1. 从 SceneParams 获取 action 和 level
##   2. 检查队列中有无该难度条目（通过 GameQueueManager.consume_next）
##   3. 有 → 取出使用，跳转游戏
##   4. 无 → GameQueueManager 异步生成，等待完成
##
## 线程生命周期由 GameQueueManager Autoload 统一管理。

const SceneTransition := preload("res://scripts/ui/SceneTransition.gd")

@onready var bg: ColorRect = %Bg
@onready var spinner: Control = %Spinner
@onready var loading_text: Label = %LoadingText

var _action: String = ""
var _level: int = 8
var _is_generating: bool = false
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


func _on_theme_changed(_name: String) -> void:
	bg.color = ThemeManager.get_color("background")


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


## 从队列查找匹配难度的条目，找不到则通过 GameQueueManager 异步生成
func _find_or_generate(lvl: int) -> void:
	# 尝试从 GameQueueManager 取匹配条目
	var entry := GameQueueManager.consume_next(lvl)
	if not entry.is_empty():
		_proceed_to_game()
		return

	# 需要生成
	_is_generating = true
	loading_text.text = "正在生成数独…"
	GameQueueManager.ensure_filled(lvl, 1)


## 跳转至游戏场景
func _proceed_to_game() -> void:
	SceneParams.set_param("next_game", {"action": _action, "level": _level})
	SceneTransition.change_to("res://scenes/sudoku/SudokuGame.tscn")


# --------------------------------------------------------------------------
# 动画循环
# --------------------------------------------------------------------------

func _process(delta: float) -> void:
	# 文字脉冲
	_text_pulse = fmod(_text_pulse + delta, 2.0)
	var alpha := 1.0
	if _text_pulse < 1.0:
		alpha = 0.5 + 0.5 * _text_pulse
	else:
		alpha = 1.0 - 0.5 * (_text_pulse - 1.0)
	loading_text.modulate = Color(1, 1, 1, alpha)

	# 检查 GameQueueManager 生成完成
	if _is_generating and GameQueueManager.poll_generation():
		_is_generating = false
		loading_text.text = "准备就绪！"
		await get_tree().create_timer(0.3).timeout
		_proceed_to_game()


# --------------------------------------------------------------------------
# 输入
# --------------------------------------------------------------------------

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if not _is_generating:
			SceneTransition.change_to("res://scenes/main/Main.tscn")
