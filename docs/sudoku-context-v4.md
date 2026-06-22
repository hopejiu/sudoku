# Context v5: 游戏集合 — 数独模块 (Godot 4.x)

## 项目路径

```
d:\code\sudoku\
├── autoload/
│   ├── SaveManager.gd         # 存档 + 队列管理
│   ├── SceneParams.gd         # 跨场景参数传递
│   ├── ThemeManager.gd        # 主题切换 + Material Design 主题生成
│   ├── GameQueueManager.gd    # 后台谜题生成队列管理器
│   ├── PlayerManager.gd       # 玩家等级/经验/积分/背包
│   ├── CharacterManager.gd    # 角色定义/技能类映射/台词
│   └── ProfileSaver.gd        # [NEW] 统一存档写入（消除竞态）
├── scenes/
│   ├── main/Main.tscn
│   └── sudoku/
│       ├── SudokuGame.tscn
│       ├── SudokuMenu.tscn
│       ├── SudokuLoading.tscn
│       ├── NumberKeyboard.tscn
│       ├── CharacterSelect.tscn  # [NEW] 角色选择
│       ├── Shop.tscn             # [NEW] 商店
│       ├── HistoryList.tscn
│       └── HistoryDetail.tscn
├── scripts/
│   ├── game/
│   │   ├── board/
│   │   │   ├── SudokuBoard.gd     # 盘面 + 冲突 + 回撤
│   │   │   ├── SudokuRules.gd     # 规则工具
│   │   │   ├── SudokuGenerator.gd # 谜题生成
│   │   │   └── SudokuSolver.gd    # 解题器
│   │   ├── skills/
│   │   │   ├── SkillBase.gd              # [NEW] 技能基类 (RefCounted)
│   │   │   ├── SkillChainReveal.gd       # [NEW] 角色A 连锁揭露
│   │   │   ├── SkillConflictBlock.gd     # [NEW] 角色B 冲突屏蔽
│   │   │   └── SkillComboReveal.gd       # [NEW] 角色C 连击馈赠
│   │   ├── items/
│   │   │   ├── ItemBase.gd               # [NEW] 道具基类 (RefCounted)
│   │   │   ├── ItemMagnifier.gd          # [NEW] 放大镜
│   │   │   └── ItemBomb.gd               # [NEW] 炸弹
│   │   └── services/
│   │       ├── ProfileManager.gd         # [NEW] 统一存档 (RefCounted)
│   │       ├── StatusDisplay.gd          # [NEW] 文本显示服务 (RefCounted)
│   │       ├── ItemData.gd               # 道具数据 (预留)
│   │       └── TimerController.gd        # 计时器
│   └── ui/
│       ├── sudoku/
│       │   ├── SudokuGame.gd        # 主游戏编排（~600行）
│       │   ├── SudokuGrid.gd        # 网格渲染 + 特效
│       │   ├── NumberKeyboard.gd    # 数字键盘
│       │   ├── SudokuLoading.gd     # 加载页
│       │   ├── SudokuMenu.gd        # 数独菜单
│       │   ├── CharacterSelect.gd   # [NEW] 角色选择
│       │   ├── Shop.gd              # [NEW] 商店
│       │   ├── HistoryList.gd
│       │   ├── HistoryDetail.gd
│       │   └── SudokuCard.gd
│       └── common/
│           ├── SceneTransition.gd   # 场景切换
│           ├── DialogAnimator.gd    # 弹窗动效
│           ├── ConfettiEffect.gd    # 撒花粒子
│           ├── LoadingSpinner.gd    # 旋转加载
│           └── GridRenderState.gd   # 网格渲染数据
├── themes/ (classic/purple_light)
├── assets/
│   ├── icons/ (SVG 图标)
│   └── characters/  [预留] 角色立绘/头像/语音
├── docs/
│   ├── CONTEXT.md                # 产品规格完整文档 (18章节)
│   ├── resources.md              # [NEW] 资源清单
│   └── adr/ (架构决策记录)
├── project.godot
└── export_presets.cfg
```

## 验证方式

```
D:\software\Godot\win64.exe --headless --check-only --path d:\code\sudoku
```
**最新结果: exit code 0。**

## 今日新增功能 (2026-06-22)

### 奖励系统 (上午)
| 功能 | 实现文件 | 说明 |
|------|---------|------|
| 玩家等级/经验/积分 | `autoload/PlayerManager.gd` | 等级无限，升级固定100经验 |
| 有限提示 | `SudokuBoard.gd` | `提示上限 = 等级 / 3 + 1` |
| 通关奖励 | `SudokuGame.gd` `_on_victory()` | `经验=难度+10`, `积分=难度+10` |
| 升级弹窗 | `SudokuGame.tscn` `LevelUpOverlay` | 全屏特效 |
| 商店 | `Shop.tscn` + `Shop.gd` | 积分购买道具 |
| 道具 | `ItemMagnifier.gd` `ItemBomb.gd` | 放大镜(+1提示)，炸弹(揭露3×3宫) |
| 道具UI | `SudokuGame.tscn` `ItemsPanel` | 🎒按钮展开道具栏 |
| 删除闪电速通 | `SudokuGame.gd` | 移除 `_on_auto_fill_pressed` |

### 角色系统 (下午)
| 功能 | 实现文件 | 说明 |
|------|---------|------|
| 角色管理 | `CharacterManager.gd` | 3角色定义 + 技能类映射 + 台词 |
| 角色选择 | `CharacterSelect.tscn` | 先选角色 → 再选难度(1~20) |
| 底部立绘 | `SudokuGame.tscn` `CharacterPanel` | 左130px立绘 + 右键盘 |
| 技能A 连锁揭露 | `SkillChainReveal.gd` | 完成行/列/宫→揭露1格 |
| 技能B 冲突屏蔽 | `SkillConflictBlock.gd` | 选中格→键盘禁用冲突数字 |
| 技能C 连击馈赠 | `SkillComboReveal.gd` | 连续5正确→揭露1格+Combo圆点 |
| 台词系统 | `CharacterManager.gd` | JSON加载 + 气泡显示 + 13触发场景 |
| 语音预留 | `CharacterManager.gd` | `{charID}_{triggerID}_{NN}.ogg` |
| 资源缺失兼容 | 各处 | 所有load有null检查 |

### 视觉特效
| 特效 | 实现 | 说明 |
|------|------|------|
| Combo圆点 | `SudokuGame.tscn` 5个ColorRect | 角色C每个正确点亮一个 |
| 技能揭露连线 | `SudokuGrid.gd` `_draw_reveal_line()` | 区域中心→揭露格动画连线 |
| 揭露高亮 | `SudokuGrid.gd` `_draw_reveal_highlight()` | 外发光膨胀+粗边框脉冲 |
| 炸弹爆炸 | `SudokuGrid.gd` `_draw_bomb_effect()` | 橙红膨胀+边框闪光 |
| 放大镜闪光 | `SudokuGrid.gd` `trigger_flash()` | 全格白色闪烁 |
| 技能名标签 | `SudokuGame.tscn` `SkillNameLabel` | 角色面板显示"连锁揭露: ..." |

### 架构改进 (下午)
| 改进 | 说明 |
|------|------|
| 目录分层 | game/board/, game/services/, ui/sudoku/, ui/common/ |
| 技能/道具提取 | 独立SkillBase/ItemBase RefCounted类 |
| 统一存档 | `ProfileSaver` + `ProfileManager` 消除PlayerManager/CharacterManager文件竞争 |
| 状态文本服务 | `StatusDisplay` 优先级队列防text冲突 |
| NumberKeyboard | 新增board_ref + refresh_from_board()自算计数 |

## CONTEXT.md 对照

`docs/CONTEXT.md` 是完整产品规格文档（18章）。本文档是快速导航和实现摘要。

关键章节：
- §3 等级经验系统
- §4 提示系统（有限次数）
- §5 商店与道具
- §7 角色系统（含资源格式表、台词触发时机25个、JSON格式示例）
- §10 难度系统（1~20）
- §11 游戏界面元素（含底部角色布局）
- §17 第一版范围

## 核心数据流

### 游戏启动流程
```
Main → 数独卡片 → SudokuMenu
  → "开启新游戏"
    → CharacterSelect (选角色) → 难度选(1~20)
      → SudokuLoading (生成谜题)
        → SudokuGame
          → board.deserialize + _skill.create() + _init_character_display()

  → "继续上局" → SudokuLoading(取队首) → SudokuGame(_restore_from_save)

  → "历史记录" → HistoryList → HistoryDetail → "重开/继续" → SudokuLoading
```

### 提示流程
```
_on_hint_pressed()
  → board.hint_count >= board.hint_cap? → return (已达上限)
  → board.get_hint(r, c) → 填入 + hint_count++
  → _show_dialogue("hint_used")
  → _status_display.show("提示 N/M 次")
```

### 道具使用流程
```
道具按钮展开 → 点击道具
  放大镜: _on_magnifier_pressed()
    → 暂停弹窗确认 → _use_magnifier()
      → PlayerManager.remove_item("magnifier")
      → ItemMagnifier.use() → {"hint_bonus":1, "flash":true}
      → _apply_skill_result(result)

  炸弹: _on_bomb_pressed()
    → selected_row<0? return
    → enter_bomb_mode() → SudokuGrid 捕捉拖动
    → bomb_target_selected(box_r, box_c)
      → PlayerManager.remove_item("bomb")
      → ItemBomb.use(board, args={box_r, box_c})
      → trigger_bomb_effect()
```

### 技能委托流程
```
_on_number_pressed() 或 _on_cell_selected() 或 _on_undo_pressed()
  → _skill.on_xxx(board, row, col, ...)   ← SkillBase 接口
  → _apply_skill_result(result)           ← 统一处理返回值
     result = {
       "reveal": {"r", "c"},        # 揭露格
       "reveal_from": {"r", "c"},   # 连线起点
       "hint_text": String,         # 状态文本
       "dialogue": String,          # 对话时机
       "flash": bool,               # 闪光特效
       "disable_keys": Array,       # 角色B禁用键
       "combo_count": int,          # 角色C连击
       "combo_reset": bool,
       "hint_bonus": int,           # 提示上限增加
     }
```

## 存档文件结构

| 文件 | 内容 | 格式 |
|------|------|------|
| `user://settings.save` | 主题设置 | store_var Dictionary |
| `user://current.save` | 游戏队列 Array[Dictionary] (最多3个) | store_var Array |
| `user://history.save` | 历史记录 Array[Dictionary] (最多20局) | store_var Array |
| `user://profile.save` | 玩家+角色合并数据 | store_var Dictionary, ProfileSaver统一写入 |

### profile.save 结构
```json
{
  "player": {
    "level": 5,
    "xp": 42,
    "coins": 230,
    "inventory": {"magnifier": 2, "bomb": 1}
  },
  "character": {
    "character": "char_a"
  }
}
```

## 当前目录文件索引

| 路径 | 行数 | 职责 |
|------|------|------|
| `autoload/PlayerManager.gd` | ~140 | 等级/经验/积分/背包 (委托ProfileSaver) |
| `autoload/CharacterManager.gd` | ~130 | 角色定义/技能类/台词/语音路径 (委托ProfileSaver) |
| `autoload/ProfileSaver.gd` | ~30 | 统一存档写入 (Autoload, tick flush) |
| `game/services/ProfileManager.gd` | ~60 | 存档合并/分section (RefCounted) |
| `game/services/StatusDisplay.gd` | ~65 | 状态文本优先级队列 (RefCounted) |
| `game/skills/SkillBase.gd` | ~45 | 技能接口基类 |
| `game/items/ItemBase.gd` | ~40 | 道具接口基类 |
| `ui/sudoku/SudokuGame.gd` | ~600 | 主游戏编排 |
| `ui/sudoku/SudokuGrid.gd` | ~300 | 网格渲染+特效 |

## 建议下一步工作

1. 音效系统（17种音效预留）
2. 语音播放实现（对接 CharacterManager.get_voice_path）
3. 全量台词 JSON 制作
4. 角色 Live2D 支持
5. 第4个角色扩展（只需新建 Skill.gd + CharacterManager 加映射）
6. 新道具扩展（只需新建 Item.gd + PlayerManager 加映射）

## 建议技能

后续会话建议加载：
- `godot-master` — 建筑/编码参考
- `grill-with-docs` — 新需求设计讨论
- `improve-codebase-architecture` — 架构审查
