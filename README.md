# Godot gdUnit4

Reference test suites for [gdUnit4](https://github.com/godot-gdunit-labs/gdUnit4),
the unit testing framework for Godot 4. GDScript only. Godot 4.7, gdUnit4 6.2.1.

Every claim in this repo was measured against the working project in `godot/`, not
copied from the docs. Two of them contradict the framework's own warning banner,
and where they do, the measurement is shown.

49 test cases across seven suites, green under `--headless` and under `xvfb-run`.

## How it works

A test suite is one script. Every `test_*` function is a test.

```gdscript
extends GdUnitTestSuite

@warning_ignore_start("return_value_discarded")
@warning_ignore_start("redundant_await")

var health: Health


func before_test() -> void:
	health = auto_free(Health.new())
	add_child(health)


func test_damage_never_goes_below_zero() -> void:
	health.take_damage(500)
	assert_int(health.current).is_equal(0).is_not_negative()
```

Those two `@warning_ignore_start` lines are not decoration. This project sets 23
GDScript warnings to error, and without them the test file does not load at all.

## The ten traps

| # | Trap | Symptom | Fix |
|---|---|---|---|
| 1 | Fluent asserts under warnings-as-errors | suite never loads, exit 105 | two `@warning_ignore_start` lines per suite, typed locals for doubles |
| 2 | The runner is fail-fast | the run looks small, not truncated | `-c` |
| 3 | Headless refused | exit 103 before anything runs | `--ignoreHeadlessMode`, or `xvfb-run` |
| 4 | Mouse position is window pixels | the click lands on the parent Control | `get_screen_transform() * rect.get_center()` |
| 5 | `simulate_action_pressed` also releases | `velocity.x` stays 0 | press, frames, release |
| 6 | `is_not_emitted` waits out the timeout | 2s per call | `wait_until(100)` |
| 7 | A missing `auto_free` | test PASSED, exit code 101 | `auto_free`, or use `RefCounted` |
| 8 | Typed fuzzer parameter | `Nonexistent function 'new'` at runtime | keep `:=` on the fuzzer only |
| 9 | Unknown test argument | test silently skipped | only 6 argument names are recognised |
| 10 | `@export` node path in a `.tscn` | reads back `<null>` after instantiate | `node_paths=PackedStringArray(...)` on the node line |

Trap 1 is the one that stops you starting. Trap 7 is the one that ships.

## Run it

Needs Godot 4.7.2 or newer, and gdtoolkit 4.5.0 for `gdformat` and `gdlint`.

```sh
cd godot
godot                                             # play the demo scene
gdformat --check scripts/ test/
gdlint scripts/ test/
./run_tests.sh                                    # 49 test cases, exit 0 = pass
```

`run_tests.sh` uses `xvfb-run` when it can, so the mouse test really runs. Without
a display it falls back to `--headless` and that one test reports as skipped.

All 23 GDScript warnings are set to **error**, including `untyped_declaration`,
`inferred_declaration` and all five `unsafe_*` checks. Game code follows the
[godot-code-style](https://github.com/mjasnikovs/godot-code-style) skill and
suppresses nothing. Test suites relax two warnings at the top of a file,
`return_value_discarded` and `redundant_await`. Two more appear on one line each:
the fuzzer test's `inferred_declaration`, and the `verify` with an argument
matcher's `unsafe_method_access`.

## What is in the project

| Path | What it tests |
|---|---|
| `test/health_test.gd` | hooks, `auto_free`, int asserts, signal asserts |
| `test/inventory_test.gd` | array asserts, parameterized cases, fuzzers |
| `test/turret_test.gd` | mocks, stubs, spies, `verify` |
| `test/player_test.gd` | scene runner, frames, held input |
| `test/menu_test.gd` | UI clicks, `do_skip` for display-only tests |
| `test/asserts_test.gd` | dict, vector, object, func, error, failure asserts |
| `test/weapon_test.gd` | plain node state, signal payload asserts |

## Read it

- **[godot-gdunit4/SKILL.md](godot-gdunit4/SKILL.md)** — the whole technique. Start here.
- [godot-gdunit4/reference/asserts.md](godot-gdunit4/reference/asserts.md) — every assert family and its methods.
- [godot-gdunit4/reference/doubles.md](godot-gdunit4/reference/doubles.md) — mock, spy, stub, matchers, verify counting.
- [godot-gdunit4/reference/traps.md](godot-gdunit4/reference/traps.md) — the measurements behind the table above.
- [godot-gdunit4/reference/ci.md](godot-gdunit4/reference/ci.md) — CLI flags, exit codes, the GitHub workflow.

## Use it as an Agent Skill

`godot-gdunit4/` follows the [Agent Skills](https://agentskills.io/specification)
standard. Link it into whichever agent you use:

```sh
ln -s "$PWD/godot-gdunit4" ~/.claude/skills/godot-gdunit4   # Claude Code
ln -s "$PWD/godot-gdunit4" ~/.pi/agent/skills/godot-gdunit4 # pi
ln -s "$PWD/godot-gdunit4" ~/.agents/skills/godot-gdunit4   # shared
```

It then fires on its own when you write or debug gdUnit4 tests. Only `SKILL.md`
sits in context; the reference files load on demand.

It is also just markdown. Read it directly if you would rather not install
anything.

## License

MIT. See [LICENSE](LICENSE). `godot/addons/gdUnit4/` is gdUnit4 itself, by Mike
Schulze, also MIT.
