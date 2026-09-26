extends GdUnitTestSuite

@warning_ignore_start("return_value_discarded")
@warning_ignore_start("redundant_await")

# Hooks, plain asserts and signal asserts on a Node under test.

var health: Health


func before_test() -> void:
	health = auto_free(Health.new())
	add_child(health)


func test_starts_full() -> void:
	assert_int(health.c_health).is_equal(100)
	assert_bool(health.is_alive()).is_true()


func test_damage_subtracts() -> void:
	health.take_damage(30)
	assert_int(health.c_health).is_equal(70)


func test_damage_never_goes_below_zero() -> void:
	health.take_damage(500)
	assert_int(health.c_health).is_equal(0).is_not_negative()
	assert_bool(health.is_alive()).is_false()


func test_heal_clamps_to_max() -> void:
	health.take_damage(10)
	health.heal(999)
	assert_int(health.c_health).is_equal(health.max_health)


func test_dead_stays_dead() -> void:
	health.take_damage(100)
	health.heal(50)
	assert_int(health.c_health).is_zero()


func test_damaged_signal_carries_amount() -> void:
	var monitored: Health = monitor_signals(health)
	monitored.take_damage(15)
	await assert_signal(monitored).is_emitted("damaged", [15])


func test_died_emitted_once_at_zero() -> void:
	var monitored: Health = monitor_signals(health)
	monitored.take_damage(60)
	# is_not_emitted waits out the full timeout, 2000ms by default.
	await assert_signal(monitored).wait_until(100).is_not_emitted("died")
	monitored.take_damage(60)
	await assert_signal(monitored).is_emitted("died")


func test_zero_damage_is_ignored() -> void:
	var monitored: Health = monitor_signals(health)
	monitored.take_damage(0)
	await assert_signal(monitored).wait_until(100).is_not_emitted("damaged")
	assert_int(monitored.c_health).is_equal(100)


func test_a_smaller_max_starts_at_that_max() -> void:
	var weak: Health = auto_free(Health.new())
	weak.max_health = 40
	# _ready seeds c_health from max_health, so it fires on add_child.
	add_child(weak)
	assert_int(weak.c_health).is_equal(40)
	assert_bool(weak.is_alive()).is_true()


func test_a_smaller_max_dies_to_a_smaller_hit() -> void:
	var weak: Health = auto_free(Health.new())
	weak.max_health = 40
	add_child(weak)
	weak.take_damage(40)
	assert_int(weak.c_health).is_zero()
	assert_bool(weak.is_alive()).is_false()
