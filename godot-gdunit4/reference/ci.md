# Running gdUnit4 from the command line

## The invocation

```sh
godot --headless --quiet -s addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -c -a res://test
```

`-s` runs the tool script. Everything after it is gdUnit4's own arguments, not
Godot's. The addon also ships `addons/gdUnit4/runtest.sh`, which wraps the same
call and reads `GODOT_BIN`.

`--quiet` is Godot's, and it goes before `-s`. gdUnit4 prints its report to stdout
on a pass as well as a failure, and `--quiet` drops it, so a green run prints
nothing past the banner. Errors still reach stderr: a suite that fails to parse
prints its `SCRIPT ERROR`. A failed test prints nothing and exits 100; the detail
is in `reports/`.

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

101 is the one people miss. Every test passed and the run still fails; under
`--quiet` nothing says so but the exit code. Check the exit code, not the log.

## Reports

`res://reports/report_N/` holds `results.xml` (JUnit) and `index.html`. Add
`reports/` to `.gitignore`. Upload `results.xml` as a CI artifact if the CI reads
JUnit.

## The display problem

Action events and key events work under `--headless`. Mouse picking on `Control`
nodes does not. Two ways out:

1. Run the whole thing under a virtual display: `xvfb-run -a godot --quiet -s ...`
   and drop `--ignoreHeadlessMode`.
2. Skip the display-dependent tests:

```gdscript
func test_clicking_the_button_emits_started(
	_do_skip: bool = DisplayServer.get_name() == "headless",
	_skip_reason: String = "mouse picking needs a real display server"
) -> void:
```

This project does both, so the suite is green either way.

## Strict typing next to gdUnit4

The project sets all 49 GDScript warnings to error. The addon is not held to
them: Godot's default `directory_rules` is `{"res://addons": 0}`. Leave it, and
leave the legacy `exclude_addons` key out — Godot folds it into `directory_rules`,
and measured on 4.7.2, `false` there made an addon script fail.

Game code follows the `godot-code-style` skill and suppresses nothing. A value it
does not want goes into a typed `_`-prefixed throwaway:

```gdscript
	var _collided: bool = move_and_slide()
	var _error: int = play_button.pressed.connect(func() -> void: _report_started())
```

`move_and_slide()` returns `bool` and `Signal.connect()` returns `int`. Typing
either throwaway as `Error` does not compile. Measured on 4.7.2.

Test suites relax at most two warnings file-wide, and only the ones they use:

```gdscript
@warning_ignore_start("return_value_discarded")  # every fluent assert call
@warning_ignore_start("redundant_await")  # await on assert_signal / simulate_*
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
- name: Install xvfb
  run: sudo apt-get update && sudo apt-get install -y xvfb

- name: Install gdtoolkit
  run: pip install "gdtoolkit==4.5.0"

- name: Import assets
  working-directory: godot
  run: godot --headless --import

- name: Launch silently
  working-directory: godot
  run: |
    # Parses only what the main scene reaches; the next step and the suites cover the rest.
    status=0
    output=$(godot --headless --quit-after 180 2>&1) || status=$?
    output=$(echo "$output" | grep -v '^Godot Engine' || true)
    if [ -n "$output" ] || [ "$status" != 0 ]; then echo "$output"; exit 1; fi

- name: Compile every script with warnings as errors
  working-directory: godot
  run: |
    failed=0
    while IFS= read -r f; do
      status=0
      output=$(godot --headless --check-only --script "$f" 2>&1) || status=$?
      output=$(echo "$output" | grep -v '^Godot Engine' || true)
      if [ -n "$output" ] || [ "$status" != 0 ]; then echo "$f"; echo "$output"; failed=1; fi
    done < <(find scripts test -name '*.gd' | sort)
    exit $failed

- name: Format
  working-directory: godot
  run: gdformat --check scripts/ test/

- name: Lint
  working-directory: godot
  run: gdlint scripts/ test/

# Both legs use run_tests.sh so the runner flags live in one place.
- name: Run the test suites
  working-directory: godot
  run: |
    status=0
    output=$(./run_tests.sh 2>&1) || status=$?
    output=$(echo "$output" | grep -v '^Godot Engine' || true)
    if [ -n "$output" ] || [ "$status" != 0 ]; then echo "$output"; exit 1; fi

- name: Run the test suites headless
  working-directory: godot
  env:
    GDUNIT_HEADLESS: "1"
  run: |
    status=0
    output=$(./run_tests.sh 2>&1) || status=$?
    output=$(echo "$output" | grep -v '^Godot Engine' || true)
    if [ -n "$output" ] || [ "$status" != 0 ]; then echo "$output"; exit 1; fi

- name: Upload the reports
  if: failure()
  uses: actions/upload-artifact@v4
  with:
    name: gdunit4-reports
    path: godot/reports/
```

Every Godot step has one shape: capture the exit status, drop the engine banner,
and fail on anything left or on a non-zero exit. A pass prints nothing. The exit
code is checked as well as the output, because a crash can exit non-zero with
nothing past the banner, and a script that fails to parse can print its error and
still exit 0.

`run_tests.sh` picks `xvfb-run` when there is no display, so the first leg runs the
mouse test for real and the second proves the suite is green headless too. It
passes `--quiet`, so a green run is silent; the reports are uploaded when a step
fails, because a quiet failure carries only its exit code.

The silent launch is the first test, and it is required. It runs the main scene
and parses only what that scene reaches: two of the thirteen scripts here.
Measured on 4.7.2, an `untyped_declaration` planted in a script the main scene
never loads printed nothing and the launch passed. The compile step and the
suites cover the rest.

The compile step parses every script with `--check-only --script <file>`, which
exits non-zero and prints the error on any warning-as-error, and names the file.
`--check-only` does not register autoloads. A script that names one fails with
`Identifier not found`, so this step only fits a project with no autoload, like
this one. With an autoload, load every script from a scene instead and check
`can_instantiate()` — the `godot-code-style` project does that.

The suites catch a broken script only when one of them depends on it, and it
arrives as exit 105 "failed to parse" rather than as a test failure.

A test that asserts a `push_error` or `push_warning` fails this CI. gdUnit4
captures the message, and Godot still prints it to stderr, `--quiet` or not;
`Engine.print_error_messages = false` hides it from gdUnit4 too. Measured on
4.7.2. So `asserts_test.gd` asserts `is_success()` on a call that reports nothing.

`apt-get update` before the install is not optional. Package lists on a hosted
runner go stale and the install 404s without it.
