extends GutTest
## test_character_manager.gd — CharacterManager 静态逻辑测试
##
## 仅测试不依赖 Autoload 的静态方法。

const CharacterManagerScript = preload("res://autoload/CharacterManager.gd")


func test_characters_defined() -> void:
	assert_true(CharacterManagerScript.CHARACTERS.has(&"char_a"))
	assert_true(CharacterManagerScript.CHARACTERS.has(&"char_b"))
	assert_true(CharacterManagerScript.CHARACTERS.has(&"char_c"))


func test_character_has_required_fields() -> void:
	for char_id in CharacterManagerScript.CHARACTERS:
		var def: Dictionary = CharacterManagerScript.CHARACTERS[char_id]
		assert_true(def.has("name"), "Character %s missing 'name'" % char_id)
		assert_true(def.has("skill_name"), "Character %s missing 'skill_name'" % char_id)
		assert_true(def.has("skill_desc"), "Character %s missing 'skill_desc'" % char_id)


func test_get_char_def() -> void:
	var def := CharacterManagerScript.get_char_def(&"char_a")
	assert_eq(def.name, "连锁者")


func test_get_char_def_unknown() -> void:
	var def := CharacterManagerScript.get_char_def(&"unknown")
	assert_true(def.is_empty())


func test_get_all_char_ids() -> void:
	var ids := CharacterManagerScript.get_all_char_ids()
	assert_eq(ids.size(), 3)
	assert_true(ids.has(&"char_a"))
	assert_true(ids.has(&"char_b"))
	assert_true(ids.has(&"char_c"))


func test_skill_classes_match_characters() -> void:
	# 每个角色应有对应技能类
	for char_id in CharacterManagerScript.CHARACTERS:
		assert_true(CharacterManagerScript.SKILL_CLASSES.has(char_id),
			"Missing skill class for %s" % char_id)


func test_create_skill_returns_instance() -> void:
	var cm := CharacterManagerScript.new()
	cm.current_char_id = &"char_a"
	var skill := cm.create_skill()
	assert_not_null(skill)
	assert_true(skill.has_method("on_number_placed"))


func test_create_skill_b() -> void:
	var cm := CharacterManagerScript.new()
	cm.current_char_id = &"char_b"
	var skill := cm.create_skill()
	assert_not_null(skill)
	assert_true(skill.has_method("on_cell_selected"))


func test_create_skill_c() -> void:
	var cm := CharacterManagerScript.new()
	cm.current_char_id = &"char_c"
	var skill := cm.create_skill()
	assert_not_null(skill)
	assert_true(skill.has_method("get_combo_count"))
