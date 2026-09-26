extends GdUnitTestSuite

# Scene runner: drive a real scene, advance frames, simulate input.
@warning_ignore_start("return_value_discarded")
@warning_ignore_start("redundant_await")

const PLAYER_SCENE: String = "res://scenes/player.tscn"


func test_scene_loads_with_its_children() -> void:
	var runner: GdUnitSceneRunner = scene_runner(PLAYER_SCENE)
	assert_object(runner.scene()).is_not_null()
	assert_object(runner.find_child("Health")).is_not_null()


func test_gravity_pulls_down_over_frames() -> void:
	var runner: GdUnitSceneRunner = scene_runner(PLAYER_SCENE)
	var player: Player = runner.scene()
	var start_y: float = player.global_position.y

	await runner.simulate_frames(20)

	assert_float(player.global_position.y).is_greater(start_y)


func test_health_child_is_wired() -> void:
	var runner: GdUnitSceneRunner = scene_runner(PLAYER_SCENE)
	var player: Player = runner.scene()
	assert_object(player.health).is_not_null()
	assert_int(player.health.current).is_equal(100)


func test_pick_up_emits_on_the_live_scene() -> void:
	var runner: GdUnitSceneRunner = scene_runner(PLAYER_SCENE)
	var player: Player = monitor_signals(runner.scene())
	player.pick_up("torch")
	await assert_signal(player).is_emitted("picked_up", ["torch"])


# Input simulation needs a real display server. It is a no-op under --headless,
# so this suite runs under xvfb in CI. simulate_action_pressed presses AND
# releases in one call, so holding a direction needs press / frames / release.
func test_held_direction_drives_the_body() -> void:
	var runner: GdUnitSceneRunner = scene_runner(PLAYER_SCENE)
	var player: Player = runner.scene()

	runner.simulate_action_press("move_right")
	await runner.simulate_frames(10)
	assert_float(player.velocity.x).is_greater(0.0)
	assert_int(player.facing).is_equal(1)

	runner.simulate_action_press("move_left")
	runner.simulate_action_release("move_right")
	await runner.simulate_frames(10)
	assert_float(player.velocity.x).is_less(0.0)
	assert_int(player.facing).is_equal(-1)

	runner.simulate_action_release("move_left")
	await runner.simulate_frames(10)
	assert_float(player.velocity.x).is_zero()
