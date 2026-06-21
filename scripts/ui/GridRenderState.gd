class_name GridRenderState
## GridRenderState — 数独网格渲染数据
##
## 封装 SudokuGrid 渲染所需的全部盘面数据，替代直接通过 owner 访问 SudokuGame 内部状态。
## SudokuGame 在每次 _update_ui 时更新此状态。
## SudokuGrid 只读此状态（cell_selected 信号在 SudokuGrid.gd 中定义）。

## 盘面数据引用（与 SudokuBoard 共享 Array 引用，不拷贝）
var grid: Array
var given: Array
var notes: Array
var conflict: Array

## 当前选中格
var selected_row: int = -1
var selected_col: int = -1
