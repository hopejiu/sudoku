class_name ItemBase
extends RefCounted
## ItemBase — 道具基类
##
## 每个道具实现 can_use / use 方法。
## can_use 检查前置条件
## use 执行业务逻辑，返回 Dictionary 描述需要 SudokuGame 执行的 UI 效果。


## 道具 ID
func get_item_id() -> StringName:
	return &""


## 道具显示名称
func get_display_name() -> String:
	return ""


## 道具描述
func get_description() -> String:
	return ""


## 购买价格
func get_price() -> int:
	return 0


## 检查是否可以使用
func can_use(board: SudokuBoard, selected_row: int, selected_col: int) -> bool:
	return false


## 执行业务效果，返回效果描述（用于 UI 回调）
## 返回值键：
##   hint_text: String    — 提示栏文字
##   dialogue: String     — 对话时机 ID
##   flash: bool          — 触发网格闪光
##   hint_bonus: int      — 增加的提示上限
##   bomb_effect: {"r","c"} — 炸弹作用的 3×3 宫，由 SudokuGame 处理特效
func use(board: SudokuBoard, selected_row: int, selected_col: int, args: Dictionary = {}) -> Dictionary:
	return {}
