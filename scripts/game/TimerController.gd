class_name TimerController
## TimerController — 计时器控制器
##
## 纯数据类，管理计时状态和格式转换。
## 从 SudokuGame 中提取，使其可独立测试。

var elapsed_time: float = 0.0

## 每帧推进计时（由外部传入暂停/结束状态）
func tick(delta: float, paused: bool, game_over: bool) -> void:
	if not paused and not game_over:
		elapsed_time += delta

## 格式化时间为 MM:SS
static func format_time(seconds: float) -> String:
	var total := int(seconds)
	var m := int(total / 60.0)
	var s := total % 60
	return "%02d:%02d" % [m, s]

## 获取当前格式化时间
func get_formatted_time() -> String:
	return format_time(elapsed_time)

## 重置计时器
func reset() -> void:
	elapsed_time = 0.0
