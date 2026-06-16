class_name SudokuGenerator
## SudokuGenerator — 数独谜题生成器
## 纯静态方法，无场景/节点依赖。
## 基于回溯法生成唯一解谜题。

## 生成指定难度的谜题
## level: 1~16, 挖空数 = 26 + level * 2
static func generate(level: int) -> Dictionary:
	var solution := _fill_grid()
	var grid := _copy_grid(solution)
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
					if _is_valid(grid, r, c, n):
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
		if _count_solutions(grid, 0, 2) == 1:
			dug += 1
		else:
			grid[r][c] = backup


## 计算解的数量（最多数到 limit 就停）
static func _count_solutions(grid: Array, placed: int, limit: int) -> int:
	if placed == 81:
		return 1
	var r := placed / 9
	var c := placed % 9
	if grid[r][c] != 0:
		return _count_solutions(grid, placed + 1, limit)
	var count := 0
	for n in range(1, 10):
		if _is_valid(grid, r, c, n):
			grid[r][c] = n
			count += _count_solutions(grid, placed + 1, limit)
			grid[r][c] = 0
			if count >= limit:
				return count
	return count


static func _copy_grid(src: Array) -> Array:
	var dst := []
	for r in 9:
		dst.append([])
		for c in 9:
			dst[r].append(src[r][c])
	return dst


static func _is_valid(grid: Array, row: int, col: int, num: int) -> bool:
	for c in 9:
		if c != col and grid[row][c] == num:
			return false
	for r in 9:
		if r != row and grid[r][col] == num:
			return false
	var br := (row / 3) * 3
	var bc := (col / 3) * 3
	for r in range(br, br + 3):
		for c in range(bc, bc + 3):
			if (r != row or c != col) and grid[r][c] == num:
				return false
	return true
