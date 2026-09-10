#!/usr/bin/env bash
# Runs every gdUnit4 suite in res://test.
# Uses a virtual display when one is available, so the UI click test really runs.
# Set GDUNIT_HEADLESS=1 to force the headless run; the UI click test then skips.
set -euo pipefail

cd "$(dirname "$0")"
GODOT="${GODOT_BIN:-godot}"
ARGS=(-s addons/gdUnit4/bin/GdUnitCmdTool.gd -c -a res://test)

if [ -n "${GDUNIT_HEADLESS:-}" ]; then
	exec "$GODOT" --headless "${ARGS[@]}" --ignoreHeadlessMode
elif [ -n "${DISPLAY:-}" ]; then
	exec "$GODOT" "${ARGS[@]}"
elif command -v xvfb-run >/dev/null 2>&1; then
	exec xvfb-run -a "$GODOT" "${ARGS[@]}"
else
	echo "No display found. Running headless; the UI click test will be skipped."
	exec "$GODOT" --headless "${ARGS[@]}" --ignoreHeadlessMode
fi
