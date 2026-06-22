# Context v4: 游戏集合 — 数独模块 (Godot 4.x)

## 项目路径

```
d:\code\sudoku\
├── autoload/
│   ├── SaveManager.gd         # 存档 + 队列管理
│   ├── SceneParams.gd         # 跨场景参数传递
│   ├── ThemeManager.gd        # 主题切换 + Material Design 主题生成
│   └── GameQueueManager.gd    # [NEW] 后台谜题生成队列管理器
├── scenes/
│   ├── main/Main.tscn + Main.gd
│   └── sudoku/
│       ├── SudokuGame.tscn + SudokuGame.gd
│       ├── SudokuGrid.tscn (SudokuGame 子节点)
│       ├── SudokuMenu.tscn + SudokuMenu.gd
│       ├── SudokuLoading.tscn + SudokuLoading.gd
│       ├── NumberKeyboard.tscn + NumberKeyboard.gd
│       ├── HistoryList.tscn + HistoryList.gd
│       └── HistoryDetail.tscn + HistoryDetail.gd
├── scripts/
│   ├── game/
│   │   ├── SudokuBoard.gd     # 盘面数据 + 冲突检测 + 回撤栈
│   │   ├── SudokuGenerator.gd # 回溯法生成唯一解
│   │   ├── SudokuRules.gd     # 规则工具类
│   │   └── SudokuSolver.gd    # 解题器
│   └── ui/
│       ├── ConfettiEffect.gd  # 胜利撒花粒子效果
│       ├── DialogAnimator.gd  # 弹窗动效 (RefCounted)
│       ├── GridRenderState.gd # 网格渲染数据传输对象
│       ├── LoadingSpinner.gd  # 旋转加载指示器
│       ├── SceneTransition.gd # 场景切换过渡 (RefCounted)
│       └── TimerController.gd # 计时控制器
├── themes/
│   ├── classic.theme
│   └── purple_light.theme
├── assets/
│   ├── fonts/                 # msyh.ttc / msyhbd.ttc
│   └── icons/                 # SVG 图标
├── docs/
│   ├── adr/0001-godot-4-engine-and-architecture.md
│   ├── adr/0002-scene-switch-architecture.md
│   ├── sudoku-handoff-v3.md
│   ├── sudoku-context-v4.md   # [NEW] 当前文档
│   ├── editor-guide.md
│   ├── 美术资源需求.md
│   └── a.html                 # 架构审查报告
├── export_presets.cfg
├── project.godot
└── CONTEXT.md
```

## 验证方式

```bash
cd /mnt/d/code/Sudoku && ./exe_headless/godot --headless --path . --quit
```
Windows:
```
D:\software\Godot\win64.exe --headless --path . --quit
```

**最新结果: exit code 0。** 仅剩预存 WARNING（UID 版本差异 + 字体缺失，不影响运行）。

## 架构审查修改清单 (2026-06-22)

基于 `docs/a.html` 架构审查报告完成的修改：

| 编号 | 候选 | 强度 | 修改内容 |
|------|------|------|---------|
| ⭐ | 提取 GameQueueManager | Strong | 新增 `autoload/GameQueueManager.gd`，消除 SudokuLoading/SudokuGame 间 ~100 行重复的队列管理和 Thread 生命周期代码 |
| C5 | 移动端渲染器配置 | Strong | `project.godot` 从 Forward Plus → Mobile (纯 2D 游戏无需 3D 渲染管线) |
| C3 | Theme 按钮注册数据驱动 | Worth | ThemeManager: 提取 `_register_outlined/filled/text/icon_buttons` 四个数据驱动函数，消除 8 组重复的 set_stylebox/set_color 模式 |
| C4 | 胜利撒花置于弹窗之上 | Spec | ConfettiEffect 改为 victory_overlay 子节点，确保撒花渲染在弹窗遮罩上方 |
| C6 | 安全区域处理改进 | Worth | 移除递归 `_find_vbox` 场景树遍历，改用 Theme 的 MarginContainer.margin_top 常量 |
| — | 依赖链修复 | 连带 | SudokuGenerator/SudokuSolver 添加 SudokuRules 显式 preload，支持 Autoload 在启动早期正确编译 |
| — | SVG 兼容性 | 连带 | SudokuCard.gd SVG 预加载改为带兜底纹理的 ResourceLoader.load()；Main.tscn 移除 icon_settings.svg 引用，Main.gd 生成程序化图标 |

### GameQueueManager API

```gdscript
func ensure_filled(level: int, needed: int) -> bool  # 确保队列有足够条目
func poll_generation() -> bool                        # 轮询生成完成
func consume_next(level: int) -> Dictionary            # 取匹配条目
func is_busy() -> bool                                 # 是否正在生成
signal queue_filled                                    # 队列填充完成
signal generation_started                              # 生成已启动
```

### 已删除的重复逻辑

**SudokuLoading.gd** 移除（由 GameQueueManager 替代）：
- `_generate_thread`, `_generated_results` 字段
- `_exit_tree` 线程清理
- `_generate_batch()` 静态方法
- `_on_generation_completed()`
- `_make_entry()` 静态方法

**SudokuGame.gd** 移除（由 GameQueueManager 替代）：
- `_refill_thread`, `_refilling`, `_refill_results` 字段
- `_exit_tree` 线程清理
- `_start_queue_refill()`
- `_refill_task()` 静态方法
- `_apply_refill_results()`
- `_make_refill_entry()` 静态方法

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
- 主界面：标题栏、数独卡片、主题切换按钮
- 弹出菜单：继续上局、新游戏（难度 1-16）、历史记录
- 游戏界面：TopBar、Grid (_draw)、NumberKeyboard
- 数字键盘：9 按钮 + 笔记切换 + 删除
- 计时器：`_process(delta)`，MM:SS
- 暂停遮罩 + 通关弹窗 + 连胜计数
- 回撤栈（50 步）+ 提示 + 笔记模式
- 冲突检测 + 自动存档
- 物理键盘支持 + Android 返回键
- 历史记录（20 局）+ 详情/重开
- 后台谜题预生成（最多 3 个队列，GameQueueManager 统一管理）

### ✅ 架构改进已完成
- GameQueueManager Autoload 统一队列/Thread 管理
- 移动端渲染器 (Vulkan Mobile)
- ThemeManager 按钮注册数据驱动
- 安全区域处理移除递归遍历
- 撒花粒子置于胜利弹窗上方
- SudokuGenerator/SudokuSolver 显式依赖声明
- Godot 4.7 兼容性（SVG 兜底 + UID 降级）

### ❌ 待办 (P2+)
1. Theme 编辑器微调（颜色和 StyleBox）
2. SVG 图标手动转换为 PNG（因 Godot 4.7 无 SVG 加载器）
3. 音效开关

## 已知的 Godot 4.7 兼容性问题
- `class_name` 引用在 Autoload 编译阶段不可用 → 已用显式 `preload` 修复
- SVG 文件无加载器 → 已用程序化生成兜底 + ResourceLoader.load()
- UID 格式差异（Godot 4.6→4.7）→ 显示警告，自动降级为文本路径

## 关键代码引用

### SudokuGrid 访问父 Scene
```gdscript
# SudokuGrid.gd
@onready var game: SudokuGame = owner as SudokuGame
```

### 跨场景参数传递
```gdscript
# SceneParams.gd
func set_param(key: String, value) -> void:  _temp_meta[key] = value
func get_param(key: String, default_value = null):  return _temp_meta.get(key, default_value)
```

### GameQueueManager 使用示例
```gdscript
# SudokuLoading.gd
func _find_or_generate(lvl: int) -> void:
    var entry := GameQueueManager.consume_next(lvl)
    if not entry.is_empty():
        _proceed_to_game()
        return
    _is_generating = true
    loading_text.text = "正在生成数独…"
    GameQueueManager.ensure_filled(lvl, 1)

func _process(delta):
    if _is_generating and GameQueueManager.poll_generation():
        _is_generating = false
        _proceed_to_game()
```
