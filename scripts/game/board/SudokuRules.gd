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


# ---------------------------------------------------------------------------
# 位运算辅助 — 用于高性能回溯求解 (MRV + 位掩码)
# ---------------------------------------------------------------------------

## 从盘面构建行/列/宫的 9-bit 已占用掩码
static func build_masks(grid: Array) -> Dictionary:
	var rows := [0, 0, 0, 0, 0, 0, 0, 0, 0]
	var cols := [0, 0, 0, 0, 0, 0, 0, 0, 0]
	var boxes := [0, 0, 0, 0, 0, 0, 0, 0, 0]
	for r in 9:
		for c in 9:
			var n: int = grid[r][c]
			if n != 0:
				var bit: int = 1 << (n - 1)
				rows[r] |= bit
				cols[c] |= bit
				boxes[box_id(r, c)] |= bit
	return {"rows": rows, "cols": cols, "boxes": boxes}


## 宫索引 (0..8)
static func box_id(r: int, c: int) -> int:
	return int(r / 3) * 3 + int(c / 3)


## 9 位值的 popcount (Brian Kernighan)
static func popcount(x: int) -> int:
	var c := 0
	while x:
		x &= x - 1
		c += 1
	return c


## 将候选掩码转为 1..9 值的数组
static func mask_to_values(mask: int) -> Array:
	var vals := []
	for i in 9:
		if mask & (1 << i):
			vals.append(i + 1)
	return vals


# ---------------------------------------------------------------------------
# 解计数 (位运算 + MRV)
# ---------------------------------------------------------------------------

## 计算解的数量（最多数到 limit 就停）
## 使用 位运算 + MRV 启发式，速度数倍于纯数组回溯。
static func count_solutions(grid: Array, limit: int) -> int:
	var m := build_masks(grid)
	return _count_solutions_bit(grid, m, limit)


static func _count_solutions_bit(grid: Array, m: Dictionary, limit: int) -> int:
	# MRV：找候选最少的空格
	var br := -1
	var bc := -1
	var bmask := 0
	var bcnt := 10

	for r in 9:
		for c in 9:
			if grid[r][c] == 0:
				var mask: int = ~(m.rows[r] | m.cols[c] | m.boxes[box_id(r, c)]) & 0x1FF
				var cnt := popcount(mask)
				if cnt == 0:
					return 0  # 死路
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
		return 1  # 无空格 → 完整解

	var count: int = 0
	for n in mask_to_values(bmask):
		var bit: int = 1 << (n - 1)
		grid[br][bc] = n
		m.rows[br] |= bit
		m.cols[bc] |= bit
		m.boxes[box_id(br, bc)] |= bit

		count += _count_solutions_bit(grid, m, limit)

		grid[br][bc] = 0
		m.rows[br] &= ~bit
		m.cols[bc] &= ~bit
		m.boxes[box_id(br, bc)] &= ~bit

		if count >= limit:
			return count

	return count
