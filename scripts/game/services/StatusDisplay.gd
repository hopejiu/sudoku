class_name StatusDisplay
extends RefCounted
## StatusDisplay — 状态文本显示服务
##
## 消除 hint_label 被多处同时写入导致冲突的问题。
## 使用优先级队列 + 定时器统一管理。


## 文本优先级
enum Priority {
	LOW = 0,     # 常规状态
	NORMAL = 1,  # 操作反馈
	HIGH = 2,    # 重要提示
}

var _label: Label = null
var _current_text: String = ""
var _current_priority: int = -1
var _timer_ref: int = 0  # 递增 ID，过期检查用


func setup(label: Label) -> void:
	_label = label
	_label.text = ""


## 显示文本
## duration: 秒数，0=一直显示（直到下次覆盖）
func show(text: String, duration: float = 2.0, priority: int = Priority.NORMAL) -> void:
	if not _label or not is_instance_valid(_label):
		return

	# 低优先级不能覆盖高优先级
	if priority < _current_priority and _current_priority >= 0:
		return

	_current_text = text
	_current_priority = priority
	_label.text = text

	if duration > 0.0:
		var my_id := _timer_ref + 1
		_timer_ref = my_id
		# 延迟清除（检查 id 避免竞争）
		_label.get_tree().create_timer(duration).timeout.connect(_clear_safe.bind(my_id), CONNECT_ONE_SHOT)


func _clear_safe(id: int) -> void:
	if id == _timer_ref and is_instance_valid(_label):
		if _label.text == _current_text:
			_label.text = ""
			_current_text = ""
			_current_priority = -1


## 强制清除
func clear() -> void:
	if _label and is_instance_valid(_label):
		_label.text = ""
	_current_text = ""
	_current_priority = -1
