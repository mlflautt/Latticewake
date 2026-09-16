#!/bin/zsh
set -euo pipefail

# Stop only processes launched from this repository's app bundles.
root_dir="$(cd "$(dirname "$0")/.." && pwd)"
if [[ "${1:-}" == "--keep-existing" ]]; then exit 0; fi

typeset -a pids
pids=(${(@f)$(/bin/ps -axo pid=,command= | awk -v root="$root_dir" '
  index($0, root "/build/Latticewake.app/Contents/MacOS/LatticewakeApp") ||
  index($0, root "/build/review/") { print $1 }
')} )
for pid in $pids; do
  [[ "$pid" == <-> ]] || continue
  kill -TERM "$pid" 2>/dev/null || true
done
for pid in $pids; do
  [[ "$pid" == <-> ]] || continue
  for _ in {1..20}; do
    /bin/kill -0 "$pid" 2>/dev/null || break
    sleep 0.05
  done
done
remaining=(${(@f)$(/bin/ps -axo pid=,command= | awk -v root="$root_dir" '
  index($0, root "/build/Latticewake.app/Contents/MacOS/LatticewakeApp") ||
  index($0, root "/build/review/") { print $1 }
')} )
if (( ${#remaining} )); then
  print -u2 "latticewake instances still running: ${remaining[*]}"
  exit 1
fi
print "closed_latticewake_instances=${#pids}"
