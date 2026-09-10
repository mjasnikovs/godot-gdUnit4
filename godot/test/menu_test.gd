## UI interaction: clicking a Button through the scene runner.
extends GdUnitTestSuite

@warning_ignore_start("return_value_discarded")
@warning_ignore_start("unsafe_method_access")
@warning_ignore_start("unsafe_property_access")
@warning_ignore_start("redundant_await")
@warning_ignore_start("inferred_declaration")

const MENU_SCENE: String = "res://scenes/menu.tscn"


func test_button_exists_and_is_labelled() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MENU_SCENE)
	var menu: Menu = runner.scene()
	assert_object(menu.play_button).is_not_null()
	assert_str(menu.play_button.text).is_equal("Play")


## The button can always be driven directly, with no mouse and no display.
func test_pressing_the_button_emits_started() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MENU_SCENE)
	var menu: Menu = monitor_signals(runner.scene())
	menu.play_button.pressed.emit()
	await assert_signal(menu).is_emitted("started")


## A real click needs a real display server. do_skip is an expression evaluated
## at discovery, so the test reports as skipped under --headless instead of
## failing. Run the suite through xvfb-run to actually exercise it.
func test_clicking_the_button_emits_started(
	_do_skip := DisplayServer.get_name() == "headless",
	_skip_reason := "mouse picking needs a real display server"
) -> void:
	var runner: GdUnitSceneRunner = scene_runner(MENU_SCENE)
	var menu: Menu = monitor_signals(runner.scene())

	# Mouse positions are window pixels. The project stretches a 320x180
	# viewport into a 960x540 window, so canvas coordinates miss by 3x.
	# get_screen_transform converts the button's rect into what the runner wants.
	var center: Vector2 = (
		menu.get_viewport().get_screen_transform()
		* menu.play_button.get_global_rect().get_center()
	)
	runner.set_mouse_position(center)
	await runner.simulate_frames(2)
	assert_object(menu.get_viewport().gui_get_hovered_control()).is_same(menu.play_button)

	runner.simulate_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	await runner.simulate_frames(2)
	await assert_signal(menu).is_emitted("started")
