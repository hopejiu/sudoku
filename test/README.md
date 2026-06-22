# Sudoku 自动化测试

## 使用方法

### 在 Godot 编辑器中运行（推荐）

1. 用 Godot 编辑器打开项目
2. 编辑器底部会出现 **GUT** 面板（如果没有，检查 插件 → Gut 是否启用）
3. 点击 **Run All** 按钮运行所有测试
4. 也可以在文件树中右键单击单个测试文件运行

### 测试文件

所有测试文件位于 `test/unit/` 目录，使用 `extends GutTest` 基类：

| 文件 | 测试内容 |
|------|----------|
| `test_sudoku_rules.gd` | 数独规则：验证、拷贝、位运算、解计数 |
| `test_sudoku_solver.gd` | 解题器：求解、唯一性、无解处理 |
| `test_sudoku_generator.gd` | 生成器：结构验证、挖空公式、唯一解 |
| `test_sudoku_board.gd` | 盘面：加载、设置、回撤、冲突、提示 |
| `test_timer_controller.gd` | 计时器：计时、暂停、格式化、重置 |
| `test_item_magnifier.gd` | 放大镜道具：属性与效果 |
| `test_item_bomb.gd` | 炸弹道具：属性与填宫效果 |
| `test_skill_chain_reveal.gd` | 连锁揭露技能：行/列/宫完成触发 |
| `test_skill_combo_reveal.gd` | 连击馈赠技能：连击计数与触发 |
| `test_skill_conflict_block.gd` | 冲突屏蔽技能：禁用键计算 |
| `test_profile_manager.gd` | 存档管理器：读写、持久化 |
| `test_player_logic.gd` | 玩家管理器：静态方法、道具定义 |
| `test_character_manager.gd` | 角色管理器：角色定义、技能创建 |

### 命令行运行

```powershell
& "D:\software\Godot\win64.exe" --headless -s addons/gut/gut_cmdln.gd
```

需要 GUT v9.6.0+（旧版本与 Godot 4.6 不兼容）。

### 配置

- `.gutconfig.json` — GUT 配置文件（测试目录、日志级别等）
