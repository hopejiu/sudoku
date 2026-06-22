extends GutTest
## test_player_logic.gd — PlayerManager 逻辑测试
##
## 注意：PlayerManager 是 Autoload，依赖 ProfileSaver。
## 此测试仅验证不依赖 Autoload 的静态方法和纯逻辑。

const PlayerManagerScript = preload("res://autoload/PlayerManager.gd")


func test_item_defs_exist() -> void:
	assert_true(PlayerManagerScript.ITEMS.has(&"magnifier"))
	assert_true(PlayerManagerScript.ITEMS.has(&"bomb"))


func test_item_class_exists() -> void:
	assert_true(PlayerManagerScript.ITEM_CLASSES.has(&"magnifier"))
	assert_true(PlayerManagerScript.ITEM_CLASSES.has(&"bomb"))


func test_get_item_def() -> void:
	var def := PlayerManagerScript.get_item_def(&"magnifier")
	assert_eq(def.display_name, "放大镜")
	assert_eq(def.price, 20)


func test_get_item_def_unknown() -> void:
	var def := PlayerManagerScript.get_item_def(&"unknown")
	assert_true(def.is_empty())


func test_create_item_magnifier() -> void:
	var item := PlayerManagerScript.create_item(&"magnifier")
	assert_not_null(item)
	assert_eq(item.get_item_id(), &"magnifier")


func test_create_item_bomb() -> void:
	var item := PlayerManagerScript.create_item(&"bomb")
	assert_not_null(item)
	assert_eq(item.get_item_id(), &"bomb")


func test_create_item_unknown() -> void:
	var item := PlayerManagerScript.create_item(&"nonexistent")
	assert_null(item)


func test_get_all_item_defs() -> void:
	var defs := PlayerManagerScript.get_all_item_defs()
	assert_eq(defs.size(), 2)
	# 每个定义应有 id 字段
	for def in defs:
		assert_true(def.has("id"))


func test_hint_cap_formula() -> void:
	# 公式：等级 / 3 + 1 + bonus
	# 等级 1: 1/3 + 1 = 0 + 1 = 1
	assert_eq(PlayerManagerScript.new().get_hint_cap(1), 1)
	# 等级 3: 3/3 + 1 = 1 + 1 = 2
	# 等级 6: 6/3 + 1 = 2 + 1 = 3
	# 等级 9: 9/3 + 1 = 3 + 1 = 4
	# 注意：需要实例化来调用非 static 方法
	var pm := PlayerManagerScript.new()
	pm._hint_bonus = 0
	assert_eq(pm.get_hint_cap(1), 1)
	assert_eq(pm.get_hint_cap(3), 2)
	assert_eq(pm.get_hint_cap(6), 3)
	assert_eq(pm.get_hint_cap(9), 4)


func test_hint_cap_with_bonus() -> void:
	var pm := PlayerManagerScript.new()
	pm._hint_bonus = 2
	assert_eq(pm.get_hint_cap(1), 3)  # 1 + 2 = 3
	assert_eq(pm.get_hint_cap(6), 5)  # 3 + 2 = 5
