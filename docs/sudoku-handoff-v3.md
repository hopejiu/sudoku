# Handoff v3: 游戏集合 — 数独模块 (Godot 4.x)

## 项目路径

```
/mnt/d/code/Sudoku/
├── autoload/
│   ├── SaveManager.gd        # 存档 + 跨场景临时参数
│   └── ThemeManager.gd       # 主题切换 + 配色字典
├── scenes/
│   ├── main/Main.tscn + Main.gd
│   └── sudoku/
│       ├── SudokuGame.tscn + SudokuGame.gd
│       ├── SudokuGrid.tscn     ← Grid 是 SudokuGame 的子节点 (无独立 .tscn)
│       ├── NumberKeyboard.tscn + NumberKeyboard.gd
│       ├── HistoryList.tscn + HistoryList.gd
│       └── HistoryDetail.tscn + HistoryDetail.gd
├── scripts/
│   ├── game/
│   │   ├── SudokuBoard.gd       # 盘面数据 + 冲突检测 + 回撤栈
│   │   ├── SudokuGenerator.gd   # 回溯法生成唯一解
│   │   └── SudokuSolver.gd      # 解题器
│   └── ui/
│       ├── Main.gd / SudokuGame.gd / SudokuGrid.gd
│       ├── NumberKeyboard.gd / HistoryList.gd / HistoryDetail.gd
├── themes/
│   ├── classic.theme
│   └── purple_light.theme
├── docs/
│   ├── adr/0001-*.md / 0002-scene-switch-architecture.md
│   ├── sudoku-handoff-v2.md
│   └── 美术资源需求.md
├── assets/                     # 字体 + SVG 图标（已导入）
├── .gitignore
├── CONTEXT.md                  # 术语表 + 规格
├── exe_headless/godot          # Godot 4.6.3 头显二进制
└── project.godot
```

## 验证方式

```bash
cd /mnt/d/code/Sudoku && ./exe_headless/godot --headless --path . --quit
```
**最新结果: 零错误。**

## 已完成的架构决策

| # | 决策 | 来源 |
|---|------|------|
| 1 | 场景切换用 `change_scene_to_file()`，非 `add_child()` | ADR 0002 |
| 2 | Main <-> SudokuGame <-> History 通过 SaveManager.set_temp/get_temp 传参 | ADR 0002 |
| 3 | TopBar 左右分组：左侧 难度+计时，右侧 提示反馈+←+?+⏸ | 对话 Q2 |
| 4 | Grid + NumberKeyboard 等比例分区，VBoxContainer 布局 | 对话 Q3 |
| 5 | NumberKeyboard 3×3 GridContainer + 底部 FuncBar（笔记/删除）| 对话 Q4 |
| 6 | 弹窗用内嵌 Panel（ColorRect overlay），不支持点击外部关闭 | 对话 Q6 |
| 7 | 新游戏流程：Main 弹出菜单 → 难度滑动条 → 确认 → change_scene | 对话 Q5 |

## 场景切换数据流

```
Main.gd:
  SaveManager.set_temp("next_game", {"action": "continue"})
  get_tree().change_scene_to_file("res://scenes/sudoku/SudokuGame.tscn")

  SaveManager.set_temp("next_game", {"action": "new", "level": 8})
  get_tree().change_scene_to_file("res://scenes/sudoku/SudokuGame.tscn")

SudokuGame.gd _ready():
  params = SaveManager.get_temp("next_game", {})
  match params.action:
    "continue" → _load_saved_game()
    "new"      → _start_new_game(params.level)
  SaveManager.set_temp("next_game", {})  # 清理
```

## 当前功能状态

### ✅ 已实现
- 主界面：标题栏、数独卡片（点击弹出菜单）、主题切换按钮
- 弹出菜单：继续上局（检测存档存在）、新游戏（难度滑动条 1-16）、历史记录
- 游戏界面：TopBar（难度+计时+←+?+⏸）、Grid（_draw() 渲染）、NumberKeyboard
- 数字键盘：9 个按钮（代码动态创建）+ 笔记切换 + 删除
- 计时器：`_process(delta)`，MM:SS，暂停时冻结
- 暂停遮罩：游戏暂停 / 继续 / 重新开始 / 返回主界面
- 通关弹窗：三选一（降低/维持/增加难度），边界禁用，连胜计数
- 回撤栈：最多 50 步
- 提示：无次数限制，记录使用次数
- 笔记模式：位掩码，不记入回撤栈
- 冲突检测：全盘扫描，红色边框视觉提示
- 物理键盘支持：数字键 1-9、方向键、ESC、Backspace/Delete
- 自动存档：每步操作后存盘，通关清除
- 历史记录：最近 20 局列表 + 详情（重开/继续）
- `.gitignore`：排除 exe_headless/godot

### ❌ 待办 (P2+)
1. **Theme 编辑器微调**：在 Godot 编辑器中打开 `.theme` 文件，调整颜色和 StyleBox（当前为代码生成默认值）
2. **图标 modulate 颜色绑定**：场景中的 SVG 图标 `modulate` 需绑定 `ThemeManager.theme_changed` 信号
3. **鼓励话术**：同难度连胜 5 次触发弹窗引导提高难度（`streak_count % 5 == 0` 处有 TODO）
4. **更改难度菜单按钮**：TopBar 中 `MenuBtn`(⋮) 目前未连接，保留作为后续"重设/改难度"入口
5. **音效开关**：预留，后续扩展

## 关键代码引用

### SudokuGrid 访问父 Scene
```gdscript
# SudokuGrid.gd - Grid 节点在 VBox 内，使用 owner 而非 get_parent()
@onready var game: SudokuGame = owner as SudokuGame
```

### NumberKeyboard 按钮创建
```gdscript
# NumberKeyboard.gd - 9 个数字按钮在 _ready() 中动态创建
func _ready() -> void:
    for i in range(9):
        var btn := Button.new()
        btn.text = str(i + 1)
        var num := i + 1
        btn.pressed.connect(_on_number_button_pressed.bind(num))
        number_grid.add_child(btn)
```

### 跨场景参数传递
```gdscript
# SaveManager.gd
func set_temp(key: String, value) -> void:  _temp_meta[key] = value
func get_temp(key: String, default_value = null):  return _temp_meta.get(key, default_value)
```

### 通关按钮重绑定
```gdscript
# SudokuGame.gd _on_victory()
easy_btn.pressed.disconnect(_on_difficulty_choice)
same_btn.pressed.disconnect(_on_difficulty_choice)
hard_btn.pressed.disconnect(_on_difficulty_choice)
easy_btn.pressed.connect(_on_difficulty_choice.bind(level - 1))
# ... level 可能已变化，需要用新值重绑
```

## 已知的限制
- Autoload 名称 `SaveManager` 在孤立脚本检查中不可见 → `ThemeManager.gd` 误报
- 跨文件 `class_name` 在孤立检查中不可见 → `SudokuGrid.gd`、`SudokuGame.gd` 误报
- 不影响运行时，仅 `--check-only` 模式下报错

## 建议技能 (Suggested Skills)

- **ui-ux-pro-max** — Theme 编辑器微调、图标颜色绑定、布局间距优化
- **caveman** — 如需极简对话节省 tokens
