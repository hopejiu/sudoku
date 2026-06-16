class_name SudokuSolver
## SudokuSolver — 数独解题器
## 纯静态方法，供 Generator 验证唯一解，也可用于辅助功能。
## 不支持场景/节点依赖。

## 用回溯法求解，返回第一个找到的解，无解返回空数组
static func solve(grid: Array) -> Array:
	var copy := _copy_grid(grid)
	if _solve_recursive(copy):
		return copy
	return []


## 判断是否有唯一解（限制最多数到 2 个解）
static func is_unique(grid: Array) -> bool:
	var copy := _copy_grid(grid)
	return _count_solutions(copy, 0, 2) == 1


static func _solve_recursive(grid: Array) -> bool:
	for r in 9:
		for c in 9:
			if grid[r][c] == 0:
				for n in range(1, 10):
					if _is_valid(grid, r, c, n):
						grid[r][c] = n
						if _solve_recursive(grid):
							return true
						grid[r][c] = 0
				return false
	return true


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
