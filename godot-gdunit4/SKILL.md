---
name: godot-gdunit4
description: >
  Write, run and debug gdUnit4 test suites for Godot 4 GDScript. Use when adding
  tests to a Godot project; when a test suite will not load, is silently skipped,
  or reports orphan nodes; when a mock, spy, stub or verify call behaves oddly;
  when a scene_runner input simulation does nothing; when a signal assertion hangs
  for two seconds; or when wiring gdUnit4 into CI. Triggers: gdUnit4, GdUnitTestSuite,
  assert_that, assert_int, assert_signal, monitor_signals, auto_free, scene_runner,
  simulate_frames, simulate_action_press, mock, spy, do_return, verify,
  verify_no_more_interactions, _test_parameters, Fuzzers, do_skip, GdUnitCmdTool,
  runtest.sh, ignoreHeadlessMode, orphan nodes, Godot unit test, TDD in Godot.
---

# gdUnit4 test suites (Godot 4)

Verified against Godot 4.7.2 and gdUnit4 6.2.1 by building the project in `godot/`
and running it. 49 test cases, green headless and under a display.

A test suite is one script that `extends GdUnitTestSuite`. Every function named
`test_*` is a test. There is no registration, no manifest, no runner class.

```gdscript
extends GdUnitTestSuite


func test_damage_subtracts() -> void:
	assert_int(health.current).is_equal(70)
```

## The first thing that will bite you

gdUnit4's assertions are a fluent chain. Every call returns the assert object and
the value is thrown away. `await` sits in front of calls that are not coroutines.
Both are warnings, and a project with warnings as errors **refuses to load the test
file at all** — reported as `Parse error` during discovery, exit code 105.

Put this block at the top of every test suite, right under `extends`:

```gdscript
@warning_ignore_start("return_value_discarded")
@warning_ignore_start("redundant_await")
@warning_ignore_start("unsafe_method_access")
```

Only test code relaxes warnings file-wide. Game code takes a one-line
`@warning_ignore("return_value_discarded")` where it drops the `Error` that
`move_and_slide()` or `connect()` returns, and nothing broader.

Add `unsafe_property_access` when a test reads a property off a mock or a
`runner.scene()`, and `inferred_declaration` when a test takes `_test_parameters`,
a fuzzer, or `_do_skip`. Those three parameters must stay inferred — gdUnit4
re-reads the default expression from source and a typed fuzzer parameter fails to
build.

## The four hooks

| Hook | Runs |
|---|---|
| `before()` | once, before the suite |
| `before_test()` | before every test |
| `after_test()` | after every test |
| `after()` | once, after the suite |

Build the subject in `before_test`, so each test gets a fresh one.

```gdscript
var health: Health


func before_test() -> void:
	health = auto_free(Health.new())
	add_child(health)
```

`auto_free` releases the object when the test ends. A `Node` created without it
survives the test and gdUnit4 reports **orphan nodes**: a warning, exit code 101,
and the test still says PASSED. A `RefCounted` needs no `auto_free`.

## The assert families

Pick the family, then chain. The family decides which methods exist.

```gdscript
assert_bool(v)   assert_int(v)     assert_float(v)   assert_str(v)
assert_array(v)  assert_dict(v)    assert_vector(v)  assert_object(v)
assert_file(v)   assert_result(v)  assert_that(v)
```

```gdscript
assert_int(health.current).is_equal(0).is_not_negative()
assert_array(inventory.items()).contains_exactly(["torch"]).not_contains(["sword"])
assert_str(menu.play_button.text).is_equal("Play")
```

Full method list per family in `reference/asserts.md`.

## Signals

`monitor_signals` starts recording. It must be called **before** the action that
emits, and it returns the same object back.

```gdscript
func test_damaged_signal_carries_amount() -> void:
	var monitored: Health = monitor_signals(health)
	monitored.take_damage(15)
	await assert_signal(monitored).is_emitted("damaged", [15])
```

`is_not_emitted` has nothing to wait for, so it burns the whole timeout — 2000ms
by default. Measured: 2s 10ms, against 102ms with `wait_until(100)`.

```gdscript
	await assert_signal(monitored).wait_until(100).is_not_emitted("died")
```

## Mocks, stubs and spies

A **mock** is a fake. It runs no real code and returns type defaults.

```gdscript
	var weapon: Weapon = mock(Weapon)
	do_return(true).on(weapon).can_fire()      # stub one method
	turret.weapon = weapon

	assert_bool(turret.engage(ORIGIN, NEAR)).is_true()
	verify(weapon).fire(NEAR)                  # exactly once
	verify(weapon, 0).fire(FAR)                # never
	verify(weapon, 2).fire(any_vector2())      # argument matcher
```

A **spy** wraps a real instance. Real code runs and calls are still recorded.

```gdscript
	var real: Weapon = auto_free(Weapon.new())
	add_child(real)
	var weapon: Weapon = spy(real)

	assert_bool(turret.engage(ORIGIN, NEAR)).is_true()
	verify(weapon).fire(NEAR)
	assert_int(weapon.ammo).is_equal(5)        # the real shot was taken
```

`verify_no_interactions(x)` asserts nothing was called.
`verify_no_more_interactions(x)` asserts nothing was called **that you did not
already verify** — a probe call like `can_fire()` counts, so verify it too.

Full anatomy in `reference/doubles.md`.

## Scene runner

`scene_runner` loads a scene, puts it in the tree and drives it.

```gdscript
	var runner: GdUnitSceneRunner = scene_runner("res://scenes/player.tscn")
	var player: Player = runner.scene()

	await runner.simulate_frames(20)
	assert_float(player.global_position.y).is_greater(start_y)
```

`simulate_action_pressed` presses **and releases** in one call. Holding a
direction takes three steps:

```gdscript
	runner.simulate_action_press("move_right")
	await runner.simulate_frames(10)
	assert_float(player.velocity.x).is_greater(0.0)
	runner.simulate_action_release("move_right")
```

Mouse positions are **window** pixels, not canvas pixels. A project that stretches
320x180 into a 960x540 window puts a button drawn at canvas (20,20) under the
mouse at window (60,60). Let Godot do the maths:

```gdscript
	var center: Vector2 = (
		menu.get_viewport().get_screen_transform()
		* menu.play_button.get_global_rect().get_center()
	)
	runner.set_mouse_position(center)
```

Mouse picking needs a real display server. Under `--headless`,
`gui_get_hovered_control()` returns null and clicks land nowhere. Action events and
key events **do** work headless — measured, and contrary to the framework's own
warning banner.

## Skipping a test that needs a display

`do_skip` is an expression evaluated at discovery. Prefix both arguments with an
underscore so they do not read as unused parameters.

```gdscript
func test_clicking_the_button_emits_started(
	_do_skip := DisplayServer.get_name() == "headless",
	_skip_reason := "mouse picking needs a real display server"
) -> void:
```

Headless reports it as skipped and exits 0. Under `xvfb-run` it runs for real.

## Parameterized tests and fuzzers

One test, many runs. The parameter set is the last argument and must be named
`_test_parameters`.

```gdscript
func test_capacity_is_reached_after_n_adds(
	count: int, expected_full: bool, _test_parameters := [
		[1, false],
		[3, false],
		[4, true]
	]
) -> void:
```

A fuzzer feeds a fresh random value per iteration.

```gdscript
func test_any_name_fits(fuzzer := Fuzzers.rand_str(1, 12), fuzzer_iterations := 50) -> void:
	# fuzzer_iterations must be read or unused_parameter rejects the file, and
	# gdUnit4 needs that exact name so it cannot be underscore-prefixed.
	assert_int(fuzzer_iterations).is_equal(50)
	# Not `name`: GdUnitTestSuite extends Node, so `name` shadows Node.name.
	var item_name: String = fuzzer.next_value()
```

An **unrecognised** argument name does not fail. gdUnit4 marks the test skipped
with reason "Unknown test case argument's". A typo in `_test_parameters` silently
stops the test from running.

## Running it

```sh
godot --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -c -a res://test
xvfb-run -a godot -s addons/gdUnit4/bin/GdUnitCmdTool.gd -c -a res://test
```

Headless is refused without `--ignoreHeadlessMode` (exit 103). `-c` is not
optional in practice: without it the runner is **fail-fast** and stops at the
first failing test, so the run looks small rather than truncated.

| Exit | Meaning |
|---|---|
| 0 | pass |
| 100 | a test failed |
| 101 | orphan nodes detected, tests passed |
| 103 | headless mode refused |
| 105 | a test script failed to parse |

Reports land in `res://reports/`. Git-ignore them.

## Build order

1. Enable the plugin: `addons/gdUnit4/` in the project, ticked in Project Settings.
2. One suite per script under test, in `test/`, named `<subject>_test.gd`.
3. `extends GdUnitTestSuite` and the three `@warning_ignore_start` lines.
4. `before_test` builds the subject with `auto_free`.
5. Asserts first, then signals, then doubles, then the scene runner.
6. Wire the CLI into CI and treat exit 101 as a failure too.

## Reference

- `reference/asserts.md` — every assert family and its methods.
- `reference/doubles.md` — mock, spy, stub, argument matchers, verify counting.
- `reference/traps.md` — the measurements behind every claim above.
- `reference/ci.md` — CLI flags, exit codes, the GitHub workflow, strict typing.
