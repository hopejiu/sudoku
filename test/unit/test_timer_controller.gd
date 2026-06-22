extends GutTest
## test_timer_controller.gd — TimerController 单元测试

const TimerController := preload("res://scripts/game/services/TimerController.gd")


var timer: TimerController


func before_each() -> void:
	timer = TimerController.new()


func after_each() -> void:
	timer = null


func test_initial_state() -> void:
	assert_eq(timer.elapsed_time, 0.0)


func test_tick_increments_time() -> void:
	timer.tick(1.0, false, false)
	assert_almost_eq(timer.elapsed_time, 1.0, 0.001)


func test_tick_paused() -> void:
	timer.tick(1.0, true, false)
	assert_eq(timer.elapsed_time, 0.0)


func test_tick_game_over() -> void:
	timer.tick(1.0, false, true)
	assert_eq(timer.elapsed_time, 0.0)


func test_tick_accumulates() -> void:
	timer.tick(0.5, false, false)
	timer.tick(0.3, false, false)
	timer.tick(0.2, false, false)
	assert_almost_eq(timer.elapsed_time, 1.0, 0.001)


func test_format_time_zero() -> void:
	assert_eq(TimerController.format_time(0.0), "00:00")


func test_format_time_seconds() -> void:
	assert_eq(TimerController.format_time(45.0), "00:45")


func test_format_time_minutes() -> void:
	assert_eq(TimerController.format_time(125.0), "02:05")


func test_format_time_large() -> void:
	assert_eq(TimerController.format_time(3661.0), "61:01")


func test_get_formatted_time() -> void:
	timer.elapsed_time = 90.0
	assert_eq(timer.get_formatted_time(), "01:30")


func test_reset() -> void:
	timer.elapsed_time = 100.0
	timer.reset()
	assert_eq(timer.elapsed_time, 0.0)
