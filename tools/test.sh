#!/usr/bin/env bash
# Runs all GUT tests headless. Usage: tools/test.sh [extra GUT options, e.g. -gselect=test_00_boot]
set -euo pipefail
GODOT="${GODOT:-/c/Users/denhu/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe}"
cd "$(dirname "$0")/.."
mkdir -p test-results
# Import first so class_name caches and imported resources exist (fresh checkout / CI).
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
"$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json "$@"
