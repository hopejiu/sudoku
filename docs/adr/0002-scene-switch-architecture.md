# 0002 — 场景切换架构：`change_scene_to_file()` 独立场景切换

## 状态

已采纳（2026-06-16）

## 背景

项目采用多场景 + Autoload 架构。主界面（Main.tscn）和数独游戏（SudokuGame.tscn）需要一种切换方式。

有两种备选方案：
- **A — `add_child()` 内嵌子场景**：Main 常驻场景树，SudokuGame 实例化为子节点
- **B — `change_scene_to_file()` 场景切换**：Main 与 SudokuGame 彼此完全独立，通过场景树 API 切换

## 决策

采用 **方案 B**。

## 理由

### 与产品规格一致

规格第 2 条明确："各游戏模块不共享状态、不共享存档机制、不共享生命周期"。方案 B 天然满足——每次切换场景，旧场景完全卸载，新场景从 `_ready()` 全新开始。

### 编码简洁性

`change_scene_to_file()` 单行调用即可完成场景切换。方案 A 需手动维护子场景栈、处理 `remove_child()` + `queue_free()` 时机，容易产生内存泄漏。

### 扩展性

未来新增游戏类型时，每款游戏作为独立场景（`GameX.tscn`），在 Main 中通过 `change_scene_to_file()` 切换。不会出现多个游戏场景同时驻留内存的情况。

### 数据传递

跨场景通信已通过 Autoload（SaveManager、ThemeManager）实现。场景切换时 Autoload 不被卸载，数据自然保持。

## 后果

### 正面

- 每款游戏模块完全解耦，不引用 Main 或其他游戏类型
- 场景树自动管理加载/卸载生命周期
- 内存消耗精准匹配当前场景所需

### 负面

- 切换场景时会产生重新实例化的开销（SudokuGame 场景简单，< 50ms，可忽略）
- 无法通过 `get_parent()` 或信号链访问 Main 中的数据，必须通过 Autoload 中转
