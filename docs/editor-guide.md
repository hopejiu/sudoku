# 必须通过 Godot 编辑器完成的操作指南

> 以下操作无法通过纯代码完成，需要在 Godot 编辑器中手动操作。
> 建议操作顺序按编号依次执行。

---

## 1. Theme 资源可视化微调

**目标**：让 `classic.theme` / `purple_light.theme` 中的按钮/面板/标签拥有正确的背景色、字体、圆角。

### 1.1 打开 Theme 编辑器

1. 在 Godot 编辑器的 `FileSystem` 面板中导航到 `res://themes/`
2. 双击 `classic.theme` → 自动打开 Theme 编辑器（底部面板）
3. 如果显示 "No base theme type selected"，在 Theme 编辑器左上角点击 **"Add Theme Type"**

### 1.2 配置 Button 样式

| 步骤 | 操作 |
|------|------|
| 1 | 在 Theme 编辑器中，`Theme Type` 下拉选择 **Button**（如果列表为空先点左下 `+` Add Theme Type） |
| 2 | 在右侧面板确保 `Show Default` 已勾选（显示继承的默认项） |
| 3 | 切换到 **Styles** 标签页（不是 "Style Boxes"，Godot 4 英文版叫 **Styles**，中文版可能叫"样式"） |
| 4 | 找到 `normal` 项（灰色显示），点击其右侧的 **Override** 按钮 → 变为可编辑状态 |
| 5 | 点击 `normal` 旁的 `[empty]` 下拉箭头 → **New StyleBoxFlat** |
| 6 | 创建后，选中它，在 Inspector 中设置： |
| 6a | `Background Color` = `#FFFFFF`（白色背景） |
| 6b | `Corner Radius` → `Top Left`/`Top Right`/`Bottom Left`/`Bottom Right` = `6` |
| 6c | `Content Margin` → `Left`/`Right` = `12`, `Top`/`Bottom` = `8` |
| 7 | 重复步骤 4-6 为 `hover`、`pressed`、`disabled` 状态做同样操作： |
|    | - 先点 **Override** 按钮 → 再创建 New StyleBoxFlat → Inspector 改背景色 |
|    | - `hover`: 背景色 = `#F0F0F0` |
|    | - `pressed`: 背景色 = Primary 色（`#1E3A8A` 约 20% 透明度） |
|    | - `disabled`: 背景色 = `#E0E0E0` |
| 8 | 切换到 **Fonts** 标签，为 Button 的 `font` 项点 **Override** → 选择 `msyh.ttc` |

**purple_light 版本**：同理，Primary 色改为 `#7C3AED`，按钮 hover 背景微调。

### 1.3 配置 Panel 样式

| 步骤 | 操作 |
|------|------|
| 1 | Theme 编辑器 → `Add Theme Type` → 选 **Panel** |
| 2 | 切换到 **Styles** 标签，找到 `panel` 项，点击 **Override** |
| 3 | 点击 `[empty]` → **New StyleBoxFlat** |
| 4 | Inspector: `Background Color` = `#FFFFFF`，`Corner Radius` = `8` |

### 1.4 配置 Label 样式

| 步骤 | 操作 |
|------|------|
| 1 | Theme 编辑器 → `Add Theme Type` → 选 **Label** |
| 2 | `Fonts` → `font` → 选择 `msyh.ttc` |
| 3 | `Font Sizes` → `font_size` = `16`（正文）/ `14`（小号） |
| 4 | `Colors` → `font_color` = `#1E293B`（深铁灰） |

### 1.5 其他控件

| 控件类型 | 需要配置的项 |
|----------|-------------|
| HSlider | `Styles` → `grabber_area` / `grabber_area_highlight` 用 StyleBoxFlat |
| ColorRect | 无需样式，代码已设置颜色 |
| ScrollContainer | `Styles` → `panel` 用透明 StyleBoxFlat |

### 1.6 复制到 purple_light

完成 `classic.theme` 后，回到 FileSystem 面板：
1. 右键 `classic.theme` → **Duplicate**
2. 重命名为 `purple_light.theme`（覆盖已有的文件）
3. 双击打开 `purple_light.theme`，将各控件的 Primary 色从 `#1E3A8A` 改为 `#7C3AED`，背景微调匹配紫色调

---

## 2. 布局目视微调

**目标**：在不同屏幕尺寸下看起来协调。

### 2.1 网格与键盘分割比例

1. 打开 `SudokuGame.tscn`
2. 选中 `VBox` → 在场景树中展开 `Grid` 和 `NumberKeyboard`
3. 分别选中这两个节点，在 Inspector 中调整 `Layout > Container Sizing > Vertical`：
   - **Grid**：`Expand` = 勾选（已有），增加比重使网格更大
   - **NumberKeyboard**：`Expand` = 勾选（已有），减少比重使键盘更紧凑
4. 在编辑器顶部切换多种分辨率预览（400×600、360×640、414×896）

### 2.2 弹窗面板定位

1. 选中 `VictoryOverlay/Center/Popup`
2. Inspector → `Rect` → `Position`：调整 `offset_left`/`offset_top` 使面板居中
3. 选中 `PauseOverlay/Center/PausePanel`
4. 同样调整弹窗大小适配内容
5. 选中 `Main.tscn` 中的 `PopupPanel` / `DiffPanel`，同样微调

### 2.3 弹窗文本和按钮间距

选中每个弹窗内的 `VBoxContainer`，在 Inspector 中设置：
- `Theme Constants` → `separation` = `8`（按钮间距）

---

## 3. 设置默认字体

**目标**：所有控件默认使用 `msyh.ttc`，无需在每个控件上单独设置。

1. 打开 `project.godot`（Project → Project Settings）
2. 搜索 `gui/theme/custom_font`
3. 选择 `msyh.ttc` 的 `.fontdata` 资源（在 `res://assets/fonts/` 下）
4. **注意**：此设置只作为 Fallback。具体控件的字体仍需在 Theme 编辑器中为各 Type 设置

---

## 4. 确认对话框 UI（已实现）

`SudokuGame.gd` 中已实现完整的确认流程：

- `%ConfirmLabel` / `%ConfirmYes` / `%ConfirmNo` 节点需在 `PauseOverlay/PausePanel/PauseVBox` 中存在
- 代码中已连接信号、实现 `_show_confirm` / `_hide_confirm` / `_on_confirm_yes` / `_on_confirm_no` 方法
- 重启和返回主界面操作前会弹出确认，确认后执行

**如 Scene 中尚未创建 UI 节点**：

在 `SudokuGame.tscn` 的 `PauseOverlay/PausePanel/PauseVBox` 中增加：
```
PauseVBox (VBoxContainer)
├── ... 现有节点 ...
├── ConfirmLabel (Label, visible=false, text="确定？当前进度将丢失")
├── ConfirmYes (Button, visible=false, text="确定")
└── ConfirmNo (Button, visible=false, text="取消")
```
确保 `%` 唯一名称（`%ConfirmLabel` / `%ConfirmYes` / `%ConfirmNo`）已在 Scene 中注册。

---

## 5. "维持难度" 按钮默认高亮（已实现）

在 `SudokuGame.gd` 的 `_on_victory()` 中已在第 334 行调用 `same_btn.grab_focus()`，通关弹窗中"维持难度"按钮会自动获得焦点高亮。

如需要 Theme 侧进一步强调（例如 focused 状态的 StyleBoxFlat 不同颜色），可在 Theme 编辑器中对 Button 的 `focused` 状态微调。

---

## 6. 统计摘要界面（已实现）

统计摘要功能已在 `HistoryList.gd` 中完整实现（第 44-84 行 `_compute_stats()`）：

- 总游戏次数、通关次数、通关率
- 各难度下的局数、最佳用时、平均用时
- 在 `_refresh_list()` 第 25 行通过 `stats_label.text = _compute_stats(history)` 展示

**如果需要调整展示布局**：编辑 `HistoryList.tscn` 中 `StatsLabel` 的位置和样式。

---

## 7. SVG 图标资源关联

**目标**：将 `assets/icons/` 下的 SVG 图标关联到场景中的按钮/纹理。

| SVG | 目标场景 | 目标节点 | 操作 |
|-----|---------|---------|------|
| `icon_sudoku.svg` | `Main.tscn` | `CardIcon` (TextureRect) | ✅ 已通过代码 `preload` 加载 |
| `icon_settings.svg` | `Main.tscn` | `SettingsBtn` (Button) | 在 Inspector 中拖 `icon_settings.svg` 到 `icon` 属性 |
| `icon_back.svg` | `HistoryList.tscn` | `BackBtn` | 拖到 `icon` 属性 |
| `icon_back.svg` | `HistoryDetail.tscn` | `BackBtn` | 拖到 `icon` 属性 |
| `icon_undo.svg` / `icon_hint.svg` / `icon_pause.svg` | `SudokuGame.tscn` | `UndoBtn` / `HintBtn` / `PauseBtn` | 替换按钮文本为图标 |
| `icon_note.svg` | `NumberKeyboard.tscn` | `NoteToggle` | 拖到 `icon` 属性，文本去掉 |

**代码中颜色绑定**：对于有 icon 的按钮，在脚本中连接 ThemeManager.theme_changed 信号：

```gdscript
# 示例 — 在 SudokuGame.gd _ready() 中添加
ThemeManager.theme_changed.connect(_on_theme_changed)

func _on_theme_changed(name: String) -> void:
    var primary := ThemeManager.get_color("primary")
    undo_btn.modulate = primary
    hint_btn.modulate = primary
    pause_btn.modulate = primary
```

---

## 操作优先级建议

| 优先级 | 操作 | 预估时间 | 影响 |
|--------|------|---------|------|
| P0 | 1.1~1.4 Button/Panel/Label Theme 配置 | 20min | 按钮和面板显示正常 |
| P0 | 1.6 Duplicate 到 purple_light | 5min | 第二主题可用 |
| P1 | 2.1 网格/键盘分割微调 | 5min | 不同屏幕适配 |
| P1 | 2.2 弹窗定位微调 | 5min | 弹窗位置正确 |
| P1 | 7 图标关联 + 颜色绑定 | 10min | 图标代替文字标签 |
| ~~P2~~ | ~~4 确认对话框 UI~~ | ✅ 已实现 | |
| ~~P2~~ | ~~5 维持难度高亮~~ | ✅ 已实现 | |
| ~~P2~~ | ~~6 统计摘要~~ | ✅ 已实现 | |

> 注：启动编辑器后，先运行一次场景（F6）查看当前效果，再按上述步骤逐个优化。
