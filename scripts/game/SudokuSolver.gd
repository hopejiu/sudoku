class_name SudokuSolver
## SudokuSolver — 数独解题器
## 纯静态方法，供 Generator 验证唯一解，也可用于辅助功能。
## 不支持场景/节点依赖。
## 规则检测委托给 SudokuRules 共享工具类。

## 用回溯法求解，返回第一个找到的解，无解返回空数组
static func solve(grid: Array) -> Array:
	var copy := SudokuRules.copy_grid(grid)
	if _solve_recursive(copy):
		return copy
	return []


## 判断是否有唯一解（限制最多数到 2 个解）
static func is_unique(grid: Array) -> bool:
	var copy := SudokuRules.copy_grid(grid)
	return SudokuRules.count_solutions(copy, 0, 2) == 1


static func _solve_recursive(grid: Array) -> bool:
	for r in 9:
		for c in 9:
			if grid[r][c] == 0:
				for n in range(1, 10):
					if SudokuRules.is_valid(grid, r, c, n):
						grid[r][c] = n
						if _solve_recursive(grid):
							return true
						grid[r][c] = 0
				return false
	return true
