#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <path-to.xcresult>" >&2
  exit 1
fi

xcresult_path="$1"

if [[ ! -d "$xcresult_path" ]]; then
  echo "ERROR: xcresult path not found: $xcresult_path" >&2
  exit 1
fi

report_json=$(xcrun xccov view --report --json "$xcresult_path")

printf '%s' "$report_json" | python3 - <<'PY'
import json
import sys

data = json.loads(sys.stdin.read())

overall = None
targets = []

if isinstance(data, dict):
    overall = data.get("lineCoverage")
    targets = data.get("targets") or []
elif isinstance(data, list):
    targets = data

if overall is None:
    covered = 0
    executable = 0
    for t in targets:
        if isinstance(t, dict):
            covered += int(t.get("coveredLines", 0) or 0)
            executable += int(t.get("executableLines", 0) or 0)
    if executable > 0:
        overall = covered / executable
    else:
        ratios = [t.get("lineCoverage") for t in targets if isinstance(t, dict) and isinstance(t.get("lineCoverage"), (int, float))]
        overall = sum(ratios) / len(ratios) if ratios else 0.0

overall_pct = overall * 100.0

print("## Coverage Summary")
print(f"- Overall line coverage: {overall_pct:.1f}%")

if targets:
    print("")
    print("| Target | Line Coverage |")
    print("| --- | --- |")
    for t in targets:
        if not isinstance(t, dict):
            continue
        name = t.get("name") or "(unknown)"
        lc = t.get("lineCoverage")
        if isinstance(lc, (int, float)):
            print(f"| {name} | {lc * 100.0:.1f}% |")
PY
