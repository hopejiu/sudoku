class_name SkillBase
extends RefCounted
## SkillBase — 被动技能基类
##
## 每个角色的技能实现此接口，通过 on_number_placed / on_cell_selected 等
## 返回 Dictionary 描述需要 SudokuGame 执行的 UI 效果。
##
## 返回值支持以下键（全部可选）：
##   reveal:     {"r","c"}       — 揭露该格
##   reveal_from: {"r","c"}      — 连线起点（区域中心）
##   hint_text:  String          — 状态栏文本
##   dialogue:   String          — 对话时机 ID
##   disable_keys: Array[int]    — 角色B: 需禁用的数字键(1-9)
##   combo_count: int            — 角色C: 当前连击数
##   combo_reset: bool           — 角色C: 重置连击


## 游戏开始时调用
func on_game_start(_board: SudokuBoard) -> Dictionary:
	return {}


## 填入数字后调用
func on_number_placed(_board: SudokuBoard, _row: int, _col: int, _num: int, _old_val: int) -> Dictionary:
	return {}


## 选中格子时调用
func on_cell_selected(_board: SudokuBoard, _row: int, _col: int, _prev_row: int, _prev_col: int) -> Dictionary:
	return {}


## 回撤后调用
func on_undo(_board: SudokuBoard) -> Dictionary:
	return {}


## 获取当前连击数（非连击技能返回 0）
func get_combo_count() -> int:
	return 0


## 获取技能说明（用于 UI 展示）
static func get_skill_name() -> String:
	return ""


static func get_skill_desc() -> String:
	return ""
