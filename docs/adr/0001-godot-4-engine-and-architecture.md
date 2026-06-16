# 选用 Godot 4.x 引擎 + GDScript + 全二进制持久化

基于「游戏集合」产品规格，数独模块需要覆盖移动端和桌面端，且未来可能扩展更多游戏类型。选用 Godot 4.x（GDScript）为统一引擎，所有持久化采用 `FileAccess.store_var` 二进制序列化，由 `SaveManager` Autoload 统一管理。

## 考虑过的方案

- **原生平台单独实现** — iOS (Swift) + Android (Kotlin) + Desktop (Electron/Qt)，维护成本高，三套代码
- **Flutter + Dart** — 跨平台框架，渲染层强，但缺少 Godot 的场景树和 Autoload 等游戏开发原生机制
- **React Native** — 跨平台 UI 框架，但数独网格需要高性能自定义绘制，RN 的 Bridge 有额外开销
- **Godot 4.x + C#** — 可选，但数独纯逻辑场景无需 C# 性能优势，GDScript 开发迭代更快

## 关键权衡

- **`FileAccess.store_var` 而非 JSON/ConfigFile** — `store_var` 安全（不执行代码）、紧凑（二进制）、原生支持 `Variant`（Vector2、Color 等自动序列化），适合数独这种数据量小但写入频繁的场景
- **Godot 而非通用跨平台框架** — 场景树、信号系统、Autoload、`_draw()` 为网格渲染提供一等支持，代价是学习引擎特定的工作流
