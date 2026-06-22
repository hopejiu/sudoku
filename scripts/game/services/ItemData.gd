class_name ItemData
extends Resource
## ItemData — 道具数据定义
## 使用 Resource 模式，可在 Inspector 中编辑。

## 唯一标识
@export var id: StringName
## 显示名称
@export var display_name: String
## 描述
@export var description: String
## 购买价格（积分）
@export var price: int = 0
## 道具图标路径
@export var icon_path: String = ""
