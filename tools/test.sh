#!/usr/bin/env bash
# Runs all GUT tests headless. Usage: tools/test.sh [extra GUT options, e.g. -gselect=test_00_boot]
set -euo pipefail
GODOT="${GODOT:-/c/Users/denhu/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe}"
# Seconds Godot may take to quit after writing the test report.
EXIT_GRACE="${EXIT_GRACE:-30}"
REPORT="test-results/junit.xml"
cd "$(dirname "$0")/.."
mkdir -p test-results
rm -f "$REPORT"
# Import first so class_name caches and imported resources exist (fresh checkout / CI).
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
"$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json "$@" &
pid=$!

# On Linux CI Godot sometimes hangs at exit after all tests ran. Once the report is written,
# give it EXIT_GRACE seconds to quit, then stop it and judge the run by the report.
report_seen=""
stopped=""
while kill -0 "$pid" 2>/dev/null; do
  if [ -z "$report_seen" ] && [ -s "$REPORT" ]; then
    report_seen=$SECONDS
  fi
  if [ -n "$report_seen" ] && (( SECONDS - report_seen > EXIT_GRACE )); then
    echo "Godot did not quit ${EXIT_GRACE}s after writing the test report: stopping it."
    kill -9 "$pid" 2>/dev/null || true
    stopped="yes"
    break
  fi
  sleep 1
done
set +e
wait "$pid"
code=$?
set -e
if [ -z "$stopped" ]; then
  exit "$code"
fi
summary=$(grep -m 1 "<testsuites" "$REPORT" || true)
if [[ "$summary" == *'failures="0"'* ]] && [[ "$summary" != *'tests="0"'* ]]; then
  echo "The report shows no failures: tests passed."
  exit 0
fi
echo "The report shows failures (or no tests): $summary"
exit 1
