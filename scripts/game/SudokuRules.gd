class_name SudokuRules
## SudokuRules — 数独规则与工具方法
##
## 纯静态类，提供数独合法性校验、网格拷贝、解计数等共享工具。
## 消除 SudokuGenerator / SudokuSolver 之间的重复代码。

## 检查在指定位置放置 num 是否合法
static func is_valid(grid: Array, row: int, col: int, num: int) -> bool:
	for c in 9:
		if c != col and grid[row][c] == num:
			return false
	for r in 9:
		if r != row and grid[r][col] == num:
			return false
	var br := int(row / 3.0) * 3
	var bc := int(col / 3.0) * 3
	for r in range(br, br + 3):
		for c in range(bc, bc + 3):
			if (r != row or c != col) and grid[r][c] == num:
				return false
	return true


## 深拷贝 9×9 网格
static func copy_grid(src: Array) -> Array:
	var dst := []
	for r in 9:
		dst.append([])
		for c in 9:
			dst[r].append(src[r][c])
	return dst


## 计算解的数量（最多数到 limit 就停）
static func count_solutions(grid: Array, placed: int, limit: int) -> int:
	if placed == 81:
		return 1
	var r := int(placed / 9.0)
	var c := placed % 9
	if grid[r][c] != 0:
		return count_solutions(grid, placed + 1, limit)
	var count := 0
	for n in range(1, 10):
		if is_valid(grid, r, c, n):
			grid[r][c] = n
			count += count_solutions(grid, placed + 1, limit)
			grid[r][c] = 0
			if count >= limit:
				return count
	return count
