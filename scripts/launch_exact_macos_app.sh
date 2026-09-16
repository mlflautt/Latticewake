#!/bin/zsh
# Launch the exact verified standalone app and record a process receipt.
# This helper never deletes crash reports or
# changes saved scenes. It uses Launch Services, then records only a newly
# created process whose executable path is the exact binary being examined.
set -euo pipefail

usage() {
  print "usage: $0 [--app APP_BUNDLE] [--out DIRECTORY] [--wait SECONDS] [--keep-existing]"
  exit 64
}

root_dir="$(cd "$(dirname "$0")/.." && pwd)"
app_bundle="${LW_APP_BUNDLE:-${root_dir}/build/Latticewake.app}"
output_dir=""
wait_seconds=3
keep_existing=0

while (( $# > 0 )); do
  case "$1" in
    --app) app_bundle="${2:-}"; shift 2 ;;
    --out) output_dir="${2:-}"; shift 2 ;;
    --wait) wait_seconds="${2:-}"; shift 2 ;;
    --keep-existing) keep_existing=1; shift ;;
    *) usage ;;
  esac
done

[[ "$wait_seconds" == <-> ]] || { print -- "--wait must be a non-negative integer" >&2; exit 64; }

binary="${app_bundle}/Contents/MacOS/LatticewakeApp"
plist="${app_bundle}/Contents/Info.plist"
[[ -x "$binary" && -f "$plist" ]] || { print -- "app bundle not found: $app_bundle" >&2; exit 66; }
if (( ! keep_existing )); then zsh "${root_dir}/scripts/close_latticewake_instances.sh"; fi

# The default bundle must be proven to correspond to the current SwiftPM
# product before it is launched. A custom --app path remains useful for
# forensic reproduction, but is labelled as such in its receipt.
identity="custom bundle; current-product identity not checked"
if [[ "$app_bundle" == "${root_dir}/build/Latticewake.app" ]]; then
  zsh "${root_dir}/scripts/verify_macos_bundle.sh"
  identity="current SwiftPM product UUID and app signature verified"
fi

if [[ -z "$output_dir" ]]; then
  output_dir="${root_dir}/build/exact-launch/$(date -u +%Y%m%dT%H%M%SZ)-$$"
fi
mkdir -p "$output_dir"

process_ids_for_binary() {
  /bin/ps -axo pid=,command= | awk -v binary="$binary" 'index($0, binary) > 0 { print $1 }'
}

started_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
before_pids="$(process_ids_for_binary)"
open -n "$app_bundle"
sleep "$wait_seconds"

pid=""
for candidate in ${(f)"$(process_ids_for_binary)"}; do
  if ! print -rl -- ${(f)before_pids} | rg -qx -- "$candidate"; then
    pid="$candidate"
    break
  fi
done
[[ -n "$pid" ]] || {
  print -- "no newly launched process identified for expected executable" >&2
  exit 1
}
kill -0 "$pid" 2>/dev/null || {
  print -- "exact app process exited before receipt: pid=$pid" >&2
  exit 1
}

# ps is a read-only check. Its command field contains the executable path on
# the target Mac; retain it verbatim in the receipt instead of inferring it.
observed_command="$(/bin/ps -p "$pid" -o command= 2>/dev/null || true)"
[[ "$observed_command" == "$binary"* ]] || {
  print -- "PID command does not identify the expected executable: $observed_command" >&2
  exit 1
}

{
  print "captured_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  print "started_at=$started_at"
  print "pid=$pid"
  print "app_bundle=$app_bundle"
  print "binary=$binary"
  print "observed_command=$observed_command"
  print "identity=$identity"
  print "version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$plist")"
  print "build=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$plist")"
  print "binary_sha256=$(shasum -a 256 "$binary" | awk '{print $1}')"
  print "uuid=$(dwarfdump --uuid "$binary" | awk '{print $2}' | paste -sd ',' -)"
} > "${output_dir}/receipt.txt"

print "receipt=${output_dir}/receipt.txt"
print "result=running pid=${pid}"
