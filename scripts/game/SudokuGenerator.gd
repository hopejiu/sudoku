class_name SudokuGenerator
## SudokuGenerator — 数独谜题生成器
## 纯静态方法，无场景/节点依赖。
## 基于回溯法生成唯一解谜题。
## 规则检测委托给 SudokuRules 共享工具类。

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


## 用回溯法填充完整盘面
static func _fill_grid() -> Array:
	var grid := []
	for r in 9:
		grid.append([])
		for c in 9:
			grid[r].append(0)
	_fill_recursive(grid)
	return grid


static func _fill_recursive(grid: Array) -> bool:
	for r in 9:
		for c in 9:
			if grid[r][c] == 0:
				var nums := range(1, 10)
				nums.shuffle()
				for n in nums:
					if SudokuRules.is_valid(grid, r, c, n):
						grid[r][c] = n
						if _fill_recursive(grid):
							return true
						grid[r][c] = 0
				return false
	return true


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
		if SudokuRules.count_solutions(grid, 0, 2) == 1:
			dug += 1
		else:
			grid[r][c] = backup
