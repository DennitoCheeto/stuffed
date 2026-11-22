#!/usr/bin/env bash
# Runs the GUT tests headless.
# Usage: tools/test.sh [--shard=NAME] [extra GUT options, e.g. -gselect=test_00_boot]
#   no shard     all tests (unit + scenarios)
#   unit         tests/unit only
#   scenarios-1  scenario files test_00_* ... test_04_* (incl. test_02b_*)
#   scenarios-2  every other scenario file (test_05_* and up, new ones land here)
# CI runs the three shards as parallel jobs (.github/workflows/ci.yml).
set -euo pipefail
GODOT="${GODOT:-/c/Users/denhu/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe}"
# Seconds Godot may take to quit after writing the test report.
EXIT_GRACE="${EXIT_GRACE:-30}"
REPORT="test-results/junit.xml"
cd "$(dirname "$0")/.."

shard=""
if [[ "${1:-}" == --shard=* ]]; then
  shard="${1#--shard=}"
  shift
fi

mkdir -p test-results
rm -f "$REPORT"
config="res://.gutconfig.json"
if [ -n "$shard" ]; then
  # A config like .gutconfig.json, but listing only this shard's test scripts.
  files=()
  case "$shard" in
    unit) mapfile -t files < <(find tests/unit -name 'test_*.gd' | sort) ;;
    scenarios-1) mapfile -t files < <(find tests/scenarios -name 'test_0[0-4]*.gd' | sort) ;;
    scenarios-2)
      mapfile -t files < <(find tests/scenarios -name 'test_*.gd' ! -name 'test_0[0-4]*.gd' | sort)
      ;;
    *) echo "Unknown shard: $shard (unit, scenarios-1, scenarios-2)"; exit 2 ;;
  esac
  if [ "${#files[@]}" -eq 0 ]; then
    echo "Shard $shard has no test files."
    exit 1
  fi
  list=""
  for file in "${files[@]}"; do
    list+="${list:+, }\"res://$file\""
  done
  cat > test-results/shard.gutconfig.json <<EOF
{
  "dirs": [],
  "tests": [$list],
  "should_exit": true,
  "should_exit_on_success": true,
  "log_level": 1,
  "junit_xml_file": "res://$REPORT"
}
EOF
  config="res://test-results/shard.gutconfig.json"
  echo "Shard $shard: ${#files[@]} test files."
fi

# Import first so class_name caches and imported resources exist (fresh checkout / CI).
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
"$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd -gconfig="$config" "$@" &
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
