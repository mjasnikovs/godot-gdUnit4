#!/usr/bin/env bash
# Runs every gdUnit4 suite in res://test.
# Uses a virtual display when one is available, so the UI click test really runs.
set -euo pipefail

cd "$(dirname "$0")"
GODOT="${GODOT_BIN:-godot}"
ARGS=(-s addons/gdUnit4/bin/GdUnitCmdTool.gd -c -a res://test)

if [ -n "${DISPLAY:-}" ]; then
	exec "$GODOT" "${ARGS[@]}"
elif command -v xvfb-run >/dev/null 2>&1; then
	exec xvfb-run -a "$GODOT" "${ARGS[@]}"
else
	echo "No display found. Running headless; the UI click test will be skipped."
	exec "$GODOT" --headless "${ARGS[@]}" --ignoreHeadlessMode
fi
