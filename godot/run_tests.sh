#!/usr/bin/env bash
# Runs every gdUnit4 suite in res://test.
# Uses a virtual display when one is available, so the UI click test really runs.
# Set GDUNIT_HEADLESS=1 to force the headless run; the UI click test then skips.
set -euo pipefail

cd "$(dirname "$0")"
GODOT="${GODOT_BIN:-godot}"
# --quiet keeps a pass silent. A failure is the exit code; its detail is in reports/.
ARGS=(--quiet -s addons/gdUnit4/bin/GdUnitCmdTool.gd -c -a res://test)

if [ -n "${GDUNIT_HEADLESS:-}" ]; then
	exec "$GODOT" --headless "${ARGS[@]}" --ignoreHeadlessMode
elif [ -n "${DISPLAY:-}" ]; then
	exec "$GODOT" "${ARGS[@]}"
elif command -v xvfb-run >/dev/null 2>&1; then
	# No input method reaches the virtual display, and Godot warns when XMODIFIERS names one.
	exec env -u XMODIFIERS xvfb-run -a "$GODOT" "${ARGS[@]}"
else
	exec "$GODOT" --headless "${ARGS[@]}" --ignoreHeadlessMode
fi
