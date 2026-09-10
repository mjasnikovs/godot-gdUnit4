# The measurements

Every number here came from running `godot/` on Godot 4.7.2 with gdUnit4 6.2.1.
Method after each claim.

## 1. Strict warnings stop the test file from loading

The project sets 23 GDScript warnings to error. Adding one ordinary test suite
produced 13 parse errors and exit code **105**:

```
Parse Error: The function "is_equal()" returns a value that will be discarded if not used.
Parse Error: "await" keyword is unnecessary because the expression isn't a coroutine nor a signal.
Parse Error: Casting "Variant" to "Health" is unsafe.
```

Not a failing test — a file that never loads. The suite disappears from the run.

Fix: three `@warning_ignore_start` lines at the top of every suite, plus
`unsafe_property_access` and `inferred_declaration` where needed. Game code takes
no file-wide relaxation, only a one-line `@warning_ignore` where it discards the
`Error` from `move_and_slide()` or `connect()`.

The `unsafe_cast` error came from `auto_free(Health.new()) as Health`. A typed
declaration has no cast and no warning:

```gdscript
	health = auto_free(Health.new())        # var health: Health
```

## 2. The runner is fail-fast by default

`GdUnitTestCIRunner._ready()` calls `_executor.fail_fast(true)`.

Measured: a suite with 7 test functions and one failure in the middle reported
`Executed test cases : (4/4)`. The four tests after the failure never ran, and the
summary looked like a small suite rather than a truncated one.

Fix: `-c` (`--continue`) to run the whole set.

## 3. Headless is refused, then works fine

Without the flag, exit **103**:

```
Headless mode is not supported!
Please note that tests that use UI interaction do not work correctly in headless mode.
```

With `--ignoreHeadlessMode`, measured on the project's own suites:

| Simulation | `--headless` | `xvfb-run` |
|---|---|---|
| `simulate_action_press` | works | works |
| `simulate_key_press` | works | works |
| mouse click on a `Button` | **fails** | works |

Under `--headless`, `gui_get_hovered_control()` returned `<Object#null>` with the
mouse inside the button's rect. Under `xvfb-run` the same call returned the
`Button`. The framework's banner is too broad: only GUI picking needs a display.

## 4. Mouse coordinates are window pixels

The project's viewport is 320x180 with `window_width_override=960`, so the canvas
is scaled 3x.

`play_button.get_global_rect()` reported `P: (20, 20), S: (100, 32)`. Clicking at
canvas centre `(70, 36)` hovered the parent `Control`, not the button. Clicking at
`(210, 108)` hovered the `Button`.

`get_viewport().get_screen_transform() * rect.get_center()` returned exactly
`(210, 108)`. Use it instead of a hardcoded multiplier.

## 5. simulate_action_pressed presses and releases

Source, `GdUnitSceneRunnerImpl.gd:118`:

```gdscript
func simulate_action_pressed(action: String, event_index := -1) -> GdUnitSceneRunner:
	simulate_action_press(action, event_index)
	simulate_action_release(action, event_index)
```

Measured: `simulate_action_pressed("move_right")` followed by
`simulate_frames(10)` left `velocity.x` at `0.0`. The action was already released
when the first frame ran.

Fix: `simulate_action_press` → `simulate_frames` → `simulate_action_release`.
Same shape for `simulate_key_pressed` and `simulate_mouse_button_pressed`.

## 6. is_not_emitted spends the whole timeout

| Call | Measured |
|---|---|
| `await assert_signal(m).is_not_emitted("died")` | 2s 10ms |
| `await assert_signal(m).wait_until(100).is_not_emitted("died")` | 102ms |

There is nothing to wait for, so it waits out the default 2000ms. Two of them in
the 8-case health suite made it take 4s 28ms. With `wait_until(100)` on both, the
whole 41-case run finishes in **1s 128ms**.

## 7. An orphan node passes the test and fails the run

A `Health.new()` without `auto_free`:

```
WARNING: Detected 1 possible orphan nodes.
Statistics: 1 test cases | 0 errors | 0 failures | 1 orphans | PASSED
Exit code: 101
```

The test says PASSED. Only the exit code says otherwise. CI that checks for a
non-zero exit catches it; CI that greps for "FAILED" does not.

`RefCounted` subjects never orphan. Mocks and spies of `Node` subclasses do not
either — gdUnit4 frees the double itself.

## 8. Fuzzer and parameter arguments must stay inferred

gdUnit4 re-reads the default expression from source and evaluates it
(`GdUnitExpressionRunner`). A typed fuzzer parameter broke that:

```gdscript
func test_x(fuzzer: Fuzzer = Fuzzers.rand_str(1, 12)) -> void:
```

```
Invalid call. Nonexistent function 'new' in base 'GDScript'.
Invalid assignment of property or key '_iteration_index' ... on a base object of type 'Nil'.
```

`fuzzer := Fuzzers.rand_str(1, 12)` works. So does `_test_parameters := [...]`.
The price is `@warning_ignore_start("inferred_declaration")`.

## 9. An unknown test argument silently skips the test

`GdUnitTestSuiteScanner._build_test_attribute` ends with:

```gdscript
	if not collected_unknown_aruments.is_empty():
		attribute.is_skipped = true
		attribute.skip_reason = "Unknown test case argument's %s found."
```

The recognised names, after stripping a leading underscore: `timeout`, `do_skip`,
`skip_reason`, `fuzzer_iterations`, `fuzzer_seed`, `test_parameters`. Anything else
turns the test into a skip. A typo in `_test_parameters` costs you the test with no
error.

## 10. Exported Node paths do not resolve on instantiate

`@export var health: Health` written into the `.tscn` as `health = NodePath("Health")`
read back as `<null>` after `PackedScene.instantiate()`, with the `Health` child
present in `get_children()`.

`@onready var health: Health = $Health` resolved correctly inside `scene_runner`,
which puts the scene in the tree and lets `_ready` run.
