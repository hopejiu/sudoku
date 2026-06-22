extends GutTest
## test_profile_manager.gd — ProfileManager 单元测试

const ProfileManager := preload("res://scripts/game/services/ProfileManager.gd")


var pm: ProfileManager


func before_each() -> void:
	pm = ProfileManager.new()


func after_each() -> void:
	# 清理测试文件
	if FileAccess.file_exists("user://profile.save"):
		DirAccess.remove_absolute("user://profile.save")
	pm = null


func test_get_section_empty() -> void:
	var data := pm.get_section("player")
	assert_true(data.is_empty())


func test_set_and_get_section() -> void:
	pm.set_section("player", {"level": 5, "xp": 42})
	var data := pm.get_section("player")
	assert_eq(data.level, 5)
	assert_eq(data.xp, 42)


func test_multiple_sections() -> void:
	pm.set_section("player", {"level": 3})
	pm.set_section("character", {"character": "char_b"})
	assert_eq(pm.get_section("player").level, 3)
	assert_eq(pm.get_section("character").character, "char_b")


func test_flush_writes_to_disk() -> void:
	pm.set_section("player", {"level": 7})
	pm.flush()
	# 重新加载验证
	var pm2 := ProfileManager.new()
	var data := pm2.get_section("player")
	assert_eq(data.level, 7)


func test_flush_without_dirty_does_nothing() -> void:
	# 不应崩溃，且 dirty 状态不变
	pm.flush()
	assert_false(pm._dirty, "Flush without dirty should remain not dirty")


func test_tick_decrements_timer() -> void:
	pm.set_section("test", {"a": 1})
	# _dirty is true, _flush_timer = 5.0
	# tick with 1.0 second
	pm.tick(1.0)
	# 不应 flush（还有 4 秒）
	assert_true(pm._dirty)


func test_tick_triggers_flush() -> void:
	pm.set_section("test", {"a": 1})
	# Tick enough to trigger flush
	pm.tick(6.0)
	assert_false(pm._dirty)


func test_overwrite_section() -> void:
	pm.set_section("player", {"level": 1})
	pm.set_section("player", {"level": 10})
	assert_eq(pm.get_section("player").level, 10)


func test_get_section_after_flush_reload() -> void:
	pm.set_section("player", {"level": 5, "xp": 100, "coins": 50})
	pm.flush()
	var pm2 := ProfileManager.new()
	var data := pm2.get_section("player")
	assert_eq(data.level, 5)
	assert_eq(data.xp, 100)
	assert_eq(data.coins, 50)
