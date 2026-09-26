# Running gdUnit4 from the command line

## The invocation

```sh
godot --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -c -a res://test
```

`-s` runs the tool script. Everything after it is gdUnit4's own arguments, not
Godot's. The addon also ships `addons/gdUnit4/runtest.sh`, which wraps the same
call and reads `GODOT_BIN`.

## Options

| Flag | Meaning |
|---|---|
| `-a <path>` | add a suite or a directory to the run |
| `-i <name>` | ignore a suite, or `suite:test` |
| `-c` | continue past the first failure |
| `-conf <file>` | run a saved test configuration |
| `-rd <dir>` | report directory, default `res://reports/` |
| `-rc <n>` | how many reports to keep |
| `--ignoreHeadlessMode` | allow `--headless` |
| `--info` | version info |
| `-help`, `--help-advanced` | the option list |

Without `-c` the runner is fail-fast: `_executor.fail_fast(true)` in
`GdUnitTestCIRunner._ready()`. Use `-c` in CI so one break does not hide the rest.

## Exit codes

| Code | Meaning |
|---|---|
| 0 | pass |
| 100 | a test failed |
| 101 | orphan nodes detected, tests otherwise passed |
| 103 | headless mode refused |
| 104 | Godot version not supported |
| 105 | a test script failed to parse |

101 is the one people miss. The console prints PASSED and the run still fails.
Check the exit code, not the log.

## Reports

`res://reports/report_N/` holds `results.xml` (JUnit) and `index.html`. Add
`reports/` to `.gitignore`. Upload `results.xml` as a CI artifact if the CI reads
JUnit.

## The display problem

Action events and key events work under `--headless`. Mouse picking on `Control`
nodes does not. Two ways out:

1. Run the whole thing under a virtual display: `xvfb-run -a godot -s ...` and drop
   `--ignoreHeadlessMode`.
2. Skip the display-dependent tests:

```gdscript
func test_clicking_the_button(
	_do_skip: bool = DisplayServer.get_name() == "headless",
	_skip_reason: String = "mouse picking needs a real display server"
) -> void:
```

This project does both, so the suite is green either way.

## Strict typing next to gdUnit4

The project sets all 49 GDScript warnings to error. `debug/gdscript/warnings/exclude_addons`
is written out as `true`. On 4.7.2 that is a legacy key that Godot folds into
`directory_rules`: measured, `false` became `{"res://addons": 1}` and made an
addon script fail. `true` behaves like the default, so the addon itself is not
held to the warnings.

Game code follows the `godot-code-style` skill and suppresses nothing. A value it
does not want goes into a typed `_`-prefixed throwaway:

```gdscript
	var _collided: bool = move_and_slide()
	var _error: int = play_button.pressed.connect(report_started)
```

`move_and_slide()` returns `bool` and `Signal.connect()` returns `int`. Typing
either throwaway as `Error` does not compile. Measured on 4.7.2.

Test suites relax at most two warnings file-wide, and only the ones they use:

```gdscript
@warning_ignore_start("return_value_discarded")   # every fluent assert call
@warning_ignore_start("redundant_await")          # await on assert_signal / simulate_*
```

Two more are allowed, each on one line and never file-wide:

- `@warning_ignore("unsafe_method_access")` on a `verify` that takes an argument
  matcher (`reference/doubles.md`).
- `@warning_ignore("inferred_declaration")` on a test that takes a fuzzer
  (`reference/traps.md`, 8).

Nothing else. `unsafe_property_access` is not needed at all. Measured: removing
it from every suite broke nothing.

## The GitHub workflow

```yaml
- name: Import assets
  working-directory: godot
  run: godot --headless --import

- name: Install xvfb
  run: sudo apt-get update && sudo apt-get install -y xvfb

- name: Format and lint
  working-directory: godot
  run: |
    pip install "gdtoolkit==4.5.0"
    gdformat --check scripts/ test/
    gdlint scripts/ test/

- name: Compile with warnings as errors
  working-directory: godot
  run: |
    status=0
    while IFS= read -r f; do
      if out=$(godot --headless --check-only --script "$f" 2>&1); then
        echo "ok   $f"
      else
        echo "FAIL $f"; echo "$out" | grep -v '^Godot Engine'; status=1
      fi
    done < <(find scripts test -name '*.gd' | sort)
    exit $status

- name: Run the tests
  working-directory: godot
  run: xvfb-run -a godot -s addons/gdUnit4/bin/GdUnitCmdTool.gd -c -a res://test
```

Check every script by hand. `--check-only --script <file>` parses one file and
exits non-zero on any warning-as-error. Do not use `godot --quit-after N` for
this: it runs the main scene and only parses what that scene reaches. Measured on
4.7.2, an `untyped_declaration` planted in a script the main scene never loads
printed nothing and the step passed.

`--check-only` does not register autoloads. A script that names one fails with
`Identifier not found`, so this step only fits a project with no autoload, like
this one. With an autoload, load every script from a scene instead and check
`can_instantiate()` — the `godot-code-style` project does that.

The test run does catch such a script, but only when a suite depends on it, and
it arrives as exit 105 "failed to parse" rather than as a test failure. The
compile step names the file directly.

`apt-get update` before the install is not optional. Package lists on a hosted
runner go stale and the install 404s without it.
