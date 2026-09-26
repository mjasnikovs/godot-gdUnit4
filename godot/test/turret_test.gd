extends GdUnitTestSuite

# Mocks, stubs and spies: testing a collaborator without the real thing.
@warning_ignore_start("return_value_discarded")

const ORIGIN: Vector2 = Vector2.ZERO
const NEAR: Vector2 = Vector2(50, 0)
const FAR: Vector2 = Vector2(500, 0)

var turret: Turret


func before_test() -> void:
	turret = auto_free(Turret.new())
	add_child(turret)


func test_no_weapon_never_engages() -> void:
	assert_bool(turret.engage(ORIGIN, NEAR)).is_false()


# A mock answers with defaults and records calls. It runs no real code.
func test_out_of_range_never_touches_the_weapon() -> void:
	var weapon: Weapon = mock(Weapon)
	turret.weapon = weapon

	assert_bool(turret.engage(ORIGIN, FAR)).is_false()
	verify_no_interactions(weapon)


# do_return stubs one method for one mock.
func test_empty_weapon_is_not_fired() -> void:
	var weapon: Weapon = mock(Weapon)
	# on() and verify() return Variant. A typed local makes the next call checked.
	var stub: Weapon = do_return(false).on(weapon)
	stub.can_fire()
	turret.weapon = weapon

	assert_bool(turret.engage(ORIGIN, NEAR)).is_false()
	var checked: Weapon = verify(weapon)
	checked.can_fire()
	checked = verify(weapon, 0)
	checked.fire(NEAR)


func test_loaded_weapon_fires_once_at_the_target() -> void:
	var weapon: Weapon = mock(Weapon)
	var stub: Weapon = do_return(true).on(weapon)
	stub.can_fire()
	turret.weapon = weapon

	assert_bool(turret.engage(ORIGIN, NEAR)).is_true()
	# verify_no_more_interactions counts every recorded call, so can_fire()
	# has to be verified too or it reports as an unverified interaction.
	var checked: Weapon = verify(weapon)
	checked.can_fire()
	checked = verify(weapon)
	checked.fire(NEAR)
	verify_no_more_interactions(weapon)


# any_vector2 matches whatever argument arrives.
func test_fires_at_whatever_is_in_range() -> void:
	var weapon: Weapon = mock(Weapon)
	var stub: Weapon = do_return(true).on(weapon)
	stub.can_fire()
	turret.weapon = weapon

	assert_bool(turret.engage(ORIGIN, Vector2(10, 10))).is_true()
	assert_bool(turret.engage(ORIGIN, Vector2(0, 90))).is_true()
	# A matcher is not a Vector2, so the verify receiver cannot be typed as Weapon.
	@warning_ignore("unsafe_method_access")
	verify(weapon, 2).fire(any_vector2())


# A spy wraps a real instance: real code runs and calls are still recorded.
func test_spy_runs_the_real_weapon() -> void:
	var real: Weapon = auto_free(Weapon.new())
	add_child(real)
	var weapon: Weapon = spy(real)
	turret.weapon = weapon

	assert_bool(turret.engage(ORIGIN, NEAR)).is_true()
	var checked: Weapon = verify(weapon)
	checked.fire(NEAR)
	# The real fire() ran, so ammo really dropped.
	assert_int(weapon.ammo).is_equal(5)


func test_spy_runs_dry_after_six_shots() -> void:
	var real: Weapon = auto_free(Weapon.new())
	add_child(real)
	var weapon: Weapon = spy(real)
	turret.weapon = weapon

	for i: int in 6:
		assert_bool(turret.engage(ORIGIN, NEAR)).is_true()
	assert_bool(turret.engage(ORIGIN, NEAR)).is_false()
	assert_int(weapon.ammo).is_zero()
	var checked: Weapon = verify(weapon, 6)
	checked.fire(NEAR)
