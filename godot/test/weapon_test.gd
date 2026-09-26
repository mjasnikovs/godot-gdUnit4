extends GdUnitTestSuite

# Ammo accounting on a plain Node, including a non-default magazine size.
@warning_ignore_start("return_value_discarded")
@warning_ignore_start("redundant_await")

var weapon: Weapon


func before_test() -> void:
	weapon = auto_free(Weapon.new())
	add_child(weapon)


func test_starts_at_the_configured_max() -> void:
	assert_int(weapon.ammo).is_equal(weapon.max_ammo).is_equal(6)


func test_fire_spends_one_round() -> void:
	weapon.fire(Vector2.ZERO)
	assert_int(weapon.ammo).is_equal(5)


func test_fire_stops_at_empty() -> void:
	for _i: int in 10:
		weapon.fire(Vector2.ZERO)
	assert_int(weapon.ammo).is_zero().is_not_negative()
	assert_bool(weapon.can_fire()).is_false()


func test_reload_refills_to_the_default_max() -> void:
	weapon.fire(Vector2.ZERO)
	weapon.reload()
	assert_int(weapon.ammo).is_equal(6)


# The bug this guards: reload() used to hardcode 6 and shrink a larger magazine.
func test_reload_refills_to_a_larger_configured_max() -> void:
	var big: Weapon = auto_free(Weapon.new())
	big.max_ammo = 12
	add_child(big)
	assert_int(big.ammo).is_equal(12)
	big.fire(Vector2.ZERO)
	big.reload()
	assert_int(big.ammo).is_equal(12)


func test_fired_signal_carries_the_target() -> void:
	var monitored: Weapon = monitor_signals(weapon)
	monitored.fire(Vector2(3, 4))
	await assert_signal(monitored).is_emitted("fired", [Vector2(3, 4)])
