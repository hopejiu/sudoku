class_name SudokuGenerator
## SudokuGenerator — 数独谜题生成器
## 纯静态方法，无场景/节点依赖。
## 基于回溯法生成唯一解谜题。
## 规则检测委托给 SudokuRules 共享工具类。

const SudokuRules := preload("res://scripts/game/SudokuRules.gd")

## 生成指定难度的谜题
## level: 1~16, 挖空数 = 26 + level * 2
static func generate(level: int) -> Dictionary:
	var solution := _fill_grid()
	var grid := SudokuRules.copy_grid(solution)
	var holes := 26 + level * 2
	_dig_holes(grid, holes)

	# given mask: true = 题目固定数字
	var given := []
	for r in 9:
		given.append([])
		for c in 9:
			given[r].append(grid[r][c] != 0)

	return {
		"grid": grid,
		"given": given,
		"solution": solution,
	}


## 用位运算+MRV 回溯填充完整盘面
static func _fill_grid() -> Array:
	var grid := []
	for r in 9:
		grid.append([])
		for c in 9:
			grid[r].append(0)
	var masks := SudokuRules.build_masks(grid)
	_fill_bit(grid, masks)
	return grid


static func _fill_bit(grid: Array, m: Dictionary) -> bool:
	# MRV：找候选最少的空格
	var br := -1
	var bc := -1
	var bmask := 0
	var bcnt := 10

	for r in 9:
		for c in 9:
			if grid[r][c] == 0:
				var mask: int = ~(m.rows[r] | m.cols[c] | m.boxes[SudokuRules.box_id(r, c)]) & 0x1FF
				var cnt := SudokuRules.popcount(mask)
				if cnt == 0:
					return false
				if cnt < bcnt:
					bcnt = cnt
					br = r
					bc = c
					bmask = mask
					if cnt == 1:
						break
		if bcnt == 1:
			break

	if br == -1:
		return true  # 全填满

	var vals := SudokuRules.mask_to_values(bmask)
	vals.shuffle()  # 随机打乱以确保每次生成不同盘面
	for n in vals:
		var bit: int = 1 << (n - 1)
		grid[br][bc] = n
		m.rows[br] |= bit
		m.cols[bc] |= bit
		m.boxes[SudokuRules.box_id(br, bc)] |= bit

		if _fill_bit(grid, m):
			return true

		grid[br][bc] = 0
		m.rows[br] &= ~bit
		m.cols[bc] &= ~bit
		m.boxes[SudokuRules.box_id(br, bc)] &= ~bit

	return false


## 挖空，保证唯一解
static func _dig_holes(grid: Array, count: int) -> void:
	var cells := []
	for r in 9:
		for c in 9:
			cells.append([r, c])
	cells.shuffle()

	var dug := 0
	for cell in cells:
		if dug >= count:
			break
		var r: int = cell[0]
		var c: int = cell[1]
		var backup: int = grid[r][c]
		grid[r][c] = 0
		if SudokuRules.count_solutions(grid, 2) == 1:
			dug += 1
		else:
			grid[r][c] = backup
