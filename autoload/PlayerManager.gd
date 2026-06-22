extends Node
## PlayerManager — 玩家进度管理器 (Autoload)
##
## 管理玩家等级、经验值、积分、背包。
## 数据通过 SaveManager 持久化到 profile.save。
##
## 信号：
##   level_up(level)     - 升级时触发
##   coins_changed(amt)  - 积分变动时触发
##   xp_changed(xp)      - 经验变动时触发
##   inventory_changed   - 背包内容变动时触发

signal level_up(new_level: int)
signal coins_changed(amount: int)
signal xp_changed(amount: int)
signal inventory_changed

const XP_PER_LEVEL := 100

# ---- 玩家状态 ----
var level: int = 1
var xp: int = 0
var coins: int = 0
var inventory: Dictionary = {}  # StringName -> int (数量)

# ---- 道具定义（从 ItemBase 子类获取） ----
const ITEM_CLASSES := {
	&"magnifier": preload("res://scripts/game/items/ItemMagnifier.gd"),
	&"bomb": preload("res://scripts/game/items/ItemBomb.gd"),
}

const ITEMS := {
	&"magnifier": {
		"display_name": "放大镜",
		"description": "永久增加本局提示次数上限 +1",
		"price": 20,
		"icon": "",
	},
	&"bomb": {
		"display_name": "炸弹",
		"description": "揭露指定 3×3 宫的所有正确答案",
		"price": 100,
		"icon": "",
	},
}

# 当前局临时加成（不持久化）
var _hint_bonus: int = 0  # 本局放大镜增加的提示次数


func _ready() -> void:
	_load()


func _exit_tree() -> void:
	save()


# ======== 存档 ========

func save() -> void:
	ProfileSaver.set_section("player", {
		"level": level,
		"xp": xp,
		"coins": coins,
		"inventory": _serialize_inventory(),
	})


func _load() -> void:
	var data := ProfileSaver.get_section("player")
	if data.is_empty():
		return
	level = data.get("level", 1)
	xp = data.get("xp", 0)
	coins = data.get("coins", 0)
	_deserialize_inventory(data.get("inventory", {}))


func _serialize_inventory() -> Dictionary:
	var out := {}
	for key in inventory:
		var count: int = inventory[key]
		if count > 0:
			out[str(key)] = count
	return out


func _deserialize_inventory(raw: Dictionary) -> void:
	inventory.clear()
	for key_str in raw:
		var key: StringName = StringName(key_str)
		inventory[key] = raw[key_str]


# ======== 等级与经验 ========

## 添加经验值，返回是否升级
func add_xp(amount: int) -> bool:
	xp += amount
	var leveled_up := false
	while xp >= XP_PER_LEVEL:
		xp -= XP_PER_LEVEL
		level += 1
		leveled_up = true
		level_up.emit(level)
	xp_changed.emit(xp)
	return leveled_up


## 获取当前等级的经验进度（0~99）
func get_xp_progress() -> int:
	return xp


## 获取升级所需经验
func get_xp_for_next_level() -> int:
	return XP_PER_LEVEL


# ======== 积分 ========

func add_coins(amount: int) -> void:
	coins += amount
	coins_changed.emit(coins)


func spend_coins(amount: int) -> bool:
	if coins < amount:
		return false
	coins -= amount
	coins_changed.emit(coins)
	return true


func has_coins(amount: int) -> bool:
	return coins >= amount


# ======== 背包 ========

func get_item_count(item_id: StringName) -> int:
	return inventory.get(item_id, 0)


func add_item(item_id: StringName, count: int = 1) -> void:
	inventory[item_id] = inventory.get(item_id, 0) + count
	inventory_changed.emit()


func remove_item(item_id: StringName, count: int = 1) -> bool:
	var cur: int = inventory.get(item_id, 0)
	if cur < count:
		return false
	cur -= count
	if cur <= 0:
		inventory.erase(item_id)
	else:
		inventory[item_id] = cur
	inventory_changed.emit()
	return true


## 获取所有有库存的道具列表（用于显示）
func get_available_items() -> Array:
	var result := []
	for key in inventory:
		result.append(key)
	return result


# ======== 道具定义查询 ========

static func get_item_def(item_id: StringName) -> Dictionary:
	return ITEMS.get(item_id, {})


## 创建道具实例
static func create_item(item_id: StringName) -> ItemBase:
	var cls = ITEM_CLASSES.get(item_id)
	if cls:
		return cls.new()
	return null


static func get_all_item_defs() -> Array:
	var result := []
	for key in ITEMS:
		var def := ITEMS[key].duplicate()
		def["id"] = key
		result.append(def)
	return result


# ======== 局内临时状态 ========

func reset_game_bonus() -> void:
	_hint_bonus = 0


## 使用放大镜：增加本局提示上限
func apply_magnifier() -> bool:
	if not remove_item(&"magnifier"):
		return false
	_hint_bonus += 1
	return true


## 获取本局提示上限加成
func get_hint_bonus() -> int:
	return _hint_bonus


func set_hint_bonus(value: int) -> void:
	_hint_bonus = value


func get_hint_cap(player_lvl: int) -> int:
	# 公式：等级 / 3 + 1 + 本局放大镜加成
	return (player_lvl / 3) + 1 + _hint_bonus
