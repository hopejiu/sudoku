# 资源清单

> 本文件列出 "游戏集合 — 数独模块" 全部所需美术/音频/数据资源。
> 状态标记：✅ 已有 · 🔲 待提供 · 🔧 需替换

---

## 一、角色相关

### 1.1 角色立绘（大图）

| 文件 | 规格 | 状态 | 说明 |
|------|------|------|------|
| `char_a_portrait.png` | 512×728px+，透明 PNG | 🔲 | 角色A 连锁者，半身立绘 |
| `char_b_portrait.png` | 512×728px+，透明 PNG | 🔲 | 角色B 明镜者，半身立绘 |
| `char_c_portrait.png` | 512×728px+，透明 PNG | 🔲 | 角色C 专注者，半身立绘 |

- 立绘在游戏内的实际显示区域为 **130×184px**（底部左侧），大图用于缩放适配。
- 构图以半身（胸部以上）为主，背景透明。
- **可选升级**：提供 Live2D 模型（`.model3.json` + 贴图）替代静态 PNG。

### 1.2 角色头像（圆形裁切）

| 文件 | 规格 | 状态 | 说明 |
|------|------|------|------|
| `char_a_avatar.png` | 64×64px，透明 PNG | 🔲 | 圆形/圆角裁切，用于角色选择卡片和顶部栏 |
| `char_b_avatar.png` | 64×64px，透明 PNG | 🔲 | 同上 |
| `char_c_avatar.png` | 64×64px，透明 PNG | 🔲 | 同上 |

### 1.3 角色台词数据

| 文件 | 格式 | 状态 | 说明 |
|------|------|------|------|
| `dialogue.json` | JSON | 🔲 | 3 个角色的全部台词文本 |

**JSON 结构规范：**

```json
{
  "character_a": {
    "game_start": ["交给我吧！", "难度N？小菜一碟"],
    "number_placed": ["有了", "这里！"],
    "skill_a_trigger": ["完成！下一个是…", "连锁反应！"]
  },
  "character_b": { ... },
  "character_c": { ... }
}
```

键名 = 时机 ID。值 = 字符串数组，游戏随机选一句播放。

### 1.4 完整触发时机 ID 列表

| 时机 ID | 触发场景 | 优先级 |
|---------|---------|--------|
| `character_select` | 角色选定后 | ⭐ |
| `game_start` | 游戏开始/盘面展示 | ⭐ |
| `number_placed` | 填入正确数字 | ⭐ |
| `number_conflict` | 填入冲突数字 | ⭐ |
| `undo` | 回撤操作 | |
| `hint_used` | 使用提示 | ⭐ |
| `hint_exhausted` | 提示次数耗尽 | ⭐ |
| `cell_already_filled` | 选中已填数字格 | |
| `item_magnifier` | 使用放大镜道具 | ⭐ |
| `item_bomb` | 使用炸弹道具 | ⭐ |
| `item_out_of_stock` | 道具不足时点击 | |
| `skill_a_trigger` | 角色A 连锁揭露触发 | ⭐ |
| `skill_b_block` | 角色B 冲突数字变灰 | |
| `skill_c_combo` | 角色C 连击里程碑 | ⭐ |
| `skill_c_break` | 角色C 连击中段 | |
| `region_complete` | 完成一行/一列/一宫 | ⭐ |
| `progress_half` | 游戏进度过半 | |
| `progress_almost` | 只剩 10 格 | ⭐ |
| `idle_long` | 长时间不动（10秒+） | |
| `victory` | 通关瞬间 | ⭐ |
| `level_up` | 升级弹窗 | ⭐ |
| `difficulty_change` | 通关后选择难度变化 | |
| `pause` | 暂停 | |
| `restart_confirm` | 确认重新开始 | |
| `exit_game` | 返回主界面 | |

### 1.5 语音文件

| 文件 | 格式 | 状态 | 说明 |
|------|------|------|------|
| `{char_id}_{trigger_id}_01.ogg` | OGG Vorbis | 🔲 | 每条对白一个文件 |

- **命名规范**：`{角色ID}_{时机ID}_{两位序号}.ogg`
  - 示例：`character_a_game_start_01.ogg`、`character_c_victory_01.ogg`
- 每句台词建议 **1~4 秒** 时长。
- 编码：OGG Vorbis，采样率 44100Hz，单声道，比特率 ~96kbps。

---

## 二、已有图标（assets/icons/）

| 文件 | 状态 | 说明 |
|------|------|------|
| `icon_back.svg` | ✅ | 返回箭头 |
| `icon_hint.svg` | ✅ | 提示（灯泡） |
| `icon_pause.svg` | ✅ | 暂停 |
| `icon_settings.svg` | ✅ | 设置（齿轮） |
| `icon_timer.svg` | ✅ | 计时器 |
| `icon_undo.svg` | ✅ | 回撤 |
| `icon_thunder.svg` | 🔧 | 闪电（原自动填充，已弃用，可删除） |

---

## 三、游戏图标

| 文件 | 规格 | 状态 | 说明 |
|------|------|------|------|
| `app_icon.svg` | SVG 矢量 | ✅ | 当前游戏应用图标（在 project.godot 中配置） |
| 桌面端图标 | `.ico` (多尺寸) | ✅ | 导出时从 SVG 生成 |
| Android 图标 | 各密度 mipmap | ✅ | 导出时从 SVG 生成 |

---

## 四、字体

当前项目使用 `SystemFont`，**不嵌入任何字体文件**（APK 体积优化）。无字体资源需求。

---

## 五、音效资源（预留）

| 资源 | 格式 | 状态 | 说明 |
|------|------|------|------|
| 数字填入音效 | OGG | 🔲 | 短促点击音，<0.5s |
| 冲突反馈音效 | OGG | 🔲 | 错误提示音，<0.5s |
| 通关庆祝音效 | OGG | 🔲 | 胜利 jingle，~2s |
| 按钮触摸音效 | OGG | 🔲 | UI 反馈，<0.3s |
| Combo 计数音效 | OGG | 🔲 | 叠加音高，与连击数对应 |
| 炸弹爆炸音效 | OGG | 🔲 | 爆炸效果，~1s |
| 放大镜闪光音效 | OGG | 🔲 | 明亮闪烁音，~0.5s |

> 音效当前不在第一版范围内，预留接口供后续扩展。

---

## 六、资源目录结构

```
assets/
├── characters/          ← 角色资源（全部 🔲）
│   ├── char_a/
│   │   ├── portrait.png
│   │   ├── avatar.png
│   │   └── voice/       ← 语音文件
│   │       ├── game_start_01.ogg
│   │       └── ...
│   ├── char_b/
│   │   └── ...
│   └── char_c/
│       └── ...
├── icons/               ← UI 图标（全部 ✅/🔧）
│   ├── app_icon.svg
│   ├── icon_back.svg
│   ├── icon_hint.svg
│   ├── icon_pause.svg
│   ├── icon_settings.svg
│   ├── icon_timer.svg
│   ├── icon_undo.svg
│   └── icon_thunder.svg  (可删除)
├── fonts/               ← 不使用（SystemFont）
├── sounds/              ← 音效（全部 🔲，预留）
│   ├── place.ogg
│   ├── conflict.ogg
│   ├── victory.ogg
│   ├── button.ogg
│   ├── combo.ogg
│   ├── bomb.ogg
│   └── magnifier.ogg
└── dialogue.json        ← 台词数据（🔲）
```
