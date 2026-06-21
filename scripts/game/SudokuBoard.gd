class_name SudokuBoard
## SudokuBoard — 数独盘面状态管理器
##
## 管理 9×9 盘面的核心数据：
## - grid[9][9]    : int, 0=空, 1-9=数字
## - given[9][9]   : bool, true=题目固定不可改
## - notes[9][9]   : int, 位掩码 (1<<1 ~ 1<<9)
## - conflict[9][9]: bool, 是否冲突
## - undo_stack    : Array[Dictionary]
##
## 不依赖任何 Godot 节点，纯数据类。

const GRID_SIZE := 9
const MAX_UNDO := 50

var grid: Array  # Array[Array[int]]
var given: Array  # Array[Array[bool]]
var notes: Array  # Array[Array[int]]
var conflict: Array  # Array[Array[bool]]
var undo_stack: Array[Dictionary]
var hint_count: int = 0
var solution: Array  # Array[Array[int]]


func _init() -> void:
	_clear_board()


## 清空盘面所有数据
func _clear_board() -> void:
	grid = []
	given = []
	notes = []
	conflict = []
	for r in GRID_SIZE:
		grid.append([])
		given.append([])
		notes.append([])
		conflict.append([])
		for c in GRID_SIZE:
			grid[r].append(0)
			given[r].append(false)
			notes[r].append(0)
			conflict[r].append(false)
	undo_stack = []
	hint_count = 0
	solution = []


## 从生成器数据加载新题目
func load_puzzle(puzzle_grid: Array, puzzle_given: Array, puzzle_solution: Array) -> void:
	_clear_board()
	for r in GRID_SIZE:
		for c in GRID_SIZE:
			grid[r][c] = puzzle_grid[r][c]
			given[r][c] = puzzle_given[r][c]
	solution = puzzle_solution
	update_conflicts()


## 在指定格子设置数字
func set_cell(row: int, col: int, value: int) -> bool:
	if given[row][col]:
		return false
	var old_val: int = grid[row][col]
	if old_val == value:
		return false

	# 记录回撤（含笔记状态）
	undo_stack.push_back({
		"r": row, "c": col,
		"ov": old_val, "nv": value,
		"on": notes[row][col], "nn": 0,
	})
	if undo_stack.size() > MAX_UNDO:
		undo_stack.pop_front()

	notes[row][col] = 0  # 放置数字时清除笔记
	grid[row][col] = value
	update_conflicts()
	return true


## 撤销上一步操作
func undo() -> bool:
	if undo_stack.is_empty():
		return false
	var entry: Dictionary = undo_stack.pop_back()
	grid[entry.r][entry.c] = entry.ov
	notes[entry.r][entry.c] = entry.on
	update_conflicts()
	return true


## 冲突检测 — 全盘扫描
func update_conflicts() -> void:
	for r in GRID_SIZE:
		for c in GRID_SIZE:
			conflict[r][c] = false
			var v: int = grid[r][c]
			if v == 0:
				continue
			# 检查行
			for cc in GRID_SIZE:
				if cc != c and grid[r][cc] == v:
					conflict[r][c] = true
					break
			if conflict[r][c]:
				continue
			# 检查列
			for rr in GRID_SIZE:
				if rr != r and grid[rr][c] == v:
					conflict[r][c] = true
					break
			if conflict[r][c]:
				continue
			# 检查宫
			var br := int(r / 3.0) * 3
			var bc := int(c / 3.0) * 3
			for rr in range(br, br + 3):
				for cc in range(bc, bc + 3):
					if (rr != r or cc != c) and grid[rr][cc] == v:
						conflict[r][c] = true
						break
				if conflict[r][c]:
					break


## 检查胜利条件：所有格填满且无冲突
func is_victory() -> bool:
	for r in GRID_SIZE:
		for c in GRID_SIZE:
			if grid[r][c] == 0 or conflict[r][c]:
				return false
	return true


## 笔记切换
func toggle_note(row: int, col: int, num: int) -> void:
	if given[row][col] or grid[row][col] != 0:
		return
	var mask := 1 << num
	# 笔记不记录回撤
	notes[row][col] ^= mask


## 自动填充所有唯一候选格
## 扫描全盘，对每个空格检查 1-9 唯一可行数字，有则填入。
## 重复直到再无单候选格。返回本次填充总数。
func auto_fill_singles() -> int:
	var filled := 0
	var changed := true
	while changed:
		changed = false
		for r in GRID_SIZE:
			for c in GRID_SIZE:
				if grid[r][c] != 0 or given[r][c]:
					continue
				var candidate := 0
				for num in range(1, 10):
					if _is_valid_placement(r, c, num):
						if candidate == 0:
							candidate = num
						else:
							candidate = -1  # 多于一个候选
							break
				if candidate > 0:
					undo_stack.push_back({
						"r": r, "c": c,
						"ov": 0, "nv": candidate,
						"on": notes[r][c], "nn": 0,
					})
					if undo_stack.size() > MAX_UNDO:
						undo_stack.pop_front()
					notes[r][c] = 0
					grid[r][c] = candidate
					filled += 1
					changed = true
	if filled > 0:
		update_conflicts()
	return filled


## 检查单个数字在盘面上是否合法（不修改盘面）
func _is_valid_placement(row: int, col: int, num: int) -> bool:
	for cc in GRID_SIZE:
		if cc != col and grid[row][cc] == num:
			return false
	for rr in GRID_SIZE:
		if rr != row and grid[rr][col] == num:
			return false
	var br := int(row / 3.0) * 3
	var bc := int(col / 3.0) * 3
	for rr in range(br, br + 3):
		for cc in range(bc, bc + 3):
			if (rr != row or cc != col) and grid[rr][cc] == num:
				return false
	return true


## 获取提示
func get_hint(row: int, col: int) -> int:
	if solution.is_empty():
		return 0
	var correct: int = solution[row][col]
	if grid[row][col] != correct:
		# 记录提示操作到回撤栈
		undo_stack.push_back({
			"r": row, "c": col,
			"ov": grid[row][col], "nv": correct,
			"on": 0, "nn": 0,
		})
		if undo_stack.size() > MAX_UNDO:
			undo_stack.pop_front()
		grid[row][col] = correct
		update_conflicts()
		hint_count += 1
	return correct


## 序列化当前状态（供 SaveManager 使用）
func serialize() -> Dictionary:
	return {
		"grid": grid,
		"given": given,
		"notes": notes,
		"undo_stack": undo_stack,
		"hint_count": hint_count,
		"solution": solution,
	}


## 反序列化恢复状态
func deserialize(data: Dictionary) -> void:
	grid = data.get("grid", [])
	given = data.get("given", [])
	notes = data.get("notes", [])
	# 反序列化可能返回未类型化的 Array，需手动转换到 Array[Dictionary]
	var raw_undo: Array = data.get("undo_stack", [])
	undo_stack = []
	for entry in raw_undo:
		undo_stack.append(entry)
	hint_count = data.get("hint_count", 0)
	solution = data.get("solution", [])
	update_conflicts()
