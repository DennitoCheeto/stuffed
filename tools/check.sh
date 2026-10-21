#!/usr/bin/env bash
# Parses every game and test script with the project's warning rules (untyped code = error).
set -uo pipefail
GODOT="${GODOT:-/c/Users/denhu/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe}"
cd "$(dirname "$0")/.."
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
failed=0
while IFS= read -r file; do
	out=$("$GODOT" --headless --path . --check-only --script "res://$file" 2>&1)
	if [ $? -ne 0 ] || grep -q "SCRIPT ERROR\|Parse Error\|ERROR:" <<<"$out"; then
		echo "✗ $file"
		grep -E "ERROR|Parse Error|at:" <<<"$out" | sed 's/^/    /'
		failed=1
	else
		echo "✓ $file"
	fi
done < <(find src tests -name '*.gd' | sort)
exit $failed
