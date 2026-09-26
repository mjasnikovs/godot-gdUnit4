extends GdUnitTestSuite

# The assert families that are easy to forget: dict, vector, object, func,
# error and failure.
@warning_ignore_start("return_value_discarded")
@warning_ignore_start("redundant_await")


func test_dict_asserts() -> void:
	var loadout: Dictionary[String, int] = {"pistol": 6, "rifle": 30}
	assert_dict(loadout).has_size(2).contains_keys(["pistol"]).contains_key_value("rifle", 30)
	assert_dict(loadout).not_contains_keys(["bow"])


func test_vector_asserts() -> void:
	assert_vector(Vector2(1.0, 2.0)).is_equal(Vector2(1.0, 2.0))
	assert_vector(Vector2(0.1 + 0.2, 0.0)).is_equal_approx(Vector2(0.3, 0.0), Vector2.ONE * 0.0001)
	assert_vector(Vector2(1.0, 1.0)).is_between(Vector2.ZERO, Vector2(2.0, 2.0))


func test_object_asserts() -> void:
	var weapon: Weapon = auto_free(Weapon.new())
	assert_object(weapon).is_instanceof(Weapon).is_not_instanceof(Turret)
	assert_object(weapon).is_same(weapon).is_not_same(auto_free(Weapon.new()))


# extract maps a method over the array before asserting on the results.
func test_array_extract() -> void:
	var pistol: Weapon = auto_free(Weapon.new())
	var rifle: Weapon = auto_free(Weapon.new())
	pistol.name = "pistol"
	rifle.name = "rifle"
	assert_array([pistol, rifle]).extract("get_name").contains_exactly(["pistol", "rifle"])


# assert_func polls a method instead of waiting on a signal.
func test_func_assert_polls_until_true() -> void:
	var health: Health = auto_free(Health.new())
	add_child(health)
	health.take_damage(100)
	await assert_func(health, "is_alive").wait_until(500).is_false()


# Not is_push_error: an asserted push_error still prints, and CI fails on any output.
func test_error_assert_sees_an_empty_weapon_fire_quietly() -> void:
	var weapon: Weapon = auto_free(Weapon.new())
	weapon.max_ammo = 0
	add_child(weapon)
	await assert_error(func() -> void: weapon.fire(Vector2.ZERO)).is_success()


# assert_failure asserts that an assertion fails. Useful when tightening a test.
func test_failure_assert_catches_a_bad_assertion() -> void:
	assert_failure(func() -> void: assert_int(1).is_equal(2)).is_failed()
