#!/bin/zsh
# Create and launch an isolated, signed review copy of the verified standalone
# app. A unique bundle ID lets native UI automation select this exact build even
# when another Latticewake instance is already open. It never alters user scenes.
set -euo pipefail

usage() {
  print "usage: $0 [--out DIRECTORY] [--wait SECONDS] [--keep-existing]"
  exit 64
}

root_dir="$(cd "$(dirname "$0")/.." && pwd)"
app_bundle="${root_dir}/build/Latticewake.app"
output_dir=""
wait_seconds=3
keep_existing=0

while (( $# > 0 )); do
  case "$1" in
    --out) output_dir="${2:-}"; shift 2 ;;
    --wait) wait_seconds="${2:-}"; shift 2 ;;
    --keep-existing) keep_existing=1; shift ;;
    *) usage ;;
  esac
done

if (( ! keep_existing )); then zsh "${root_dir}/scripts/close_latticewake_instances.sh"; fi

[[ "$wait_seconds" == <-> ]] || { print -- "--wait must be a non-negative integer" >&2; exit 64; }
zsh "${root_dir}/scripts/verify_macos_bundle.sh"

stamp="$(date -u +%Y%m%dT%H%M%SZ)-$$"
review_bundle="${root_dir}/build/review/LatticewakeReview-${stamp}.app"
review_identifier="com.mlflautt.latticewake.review.${stamp//[-T]/}"
review_binary="${review_bundle}/Contents/MacOS/LatticewakeApp"
review_plist="${review_bundle}/Contents/Info.plist"
mkdir -p "${root_dir}/build/review"
ditto "$app_bundle" "$review_bundle"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier ${review_identifier}" "$review_plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleName Latticewake Review" "$review_plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName Latticewake Review" "$review_plist" 2>/dev/null || true
codesign --force --deep --sign - "$review_bundle"
codesign --verify --deep --strict "$review_bundle"

if [[ -z "$output_dir" ]]; then
  output_dir="${root_dir}/build/review/${stamp}"
fi
mkdir -p "$output_dir"
process_ids_for_binary() {
  /bin/ps -axo pid=,command= | awk -v binary="$review_binary" 'index($0, binary) > 0 { print $1 }'
}
before_pids="$(process_ids_for_binary)"
started_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
open -n "$review_bundle"
sleep "$wait_seconds"

pid=""
for candidate in ${(f)"$(process_ids_for_binary)"}; do
  if ! print -rl -- ${(f)before_pids} | rg -qx -- "$candidate"; then
    pid="$candidate"
    break
  fi
done
[[ -n "$pid" ]] || { print -- "no isolated review process identified" >&2; exit 1; }
observed_command="$(/bin/ps -p "$pid" -o command= 2>/dev/null || true)"
[[ "$observed_command" == "$review_binary"* ]] || { print -- "unexpected review process: $observed_command" >&2; exit 1; }

{
  print "captured_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  print "started_at=$started_at"
  print "pid=$pid"
  print "review_bundle=$review_bundle"
  print "bundle_identifier=$review_identifier"
  print "binary=$review_binary"
  print "observed_command=$observed_command"
  print "version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$review_plist")"
  print "build=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$review_plist")"
  print "binary_sha256=$(shasum -a 256 "$review_binary" | awk '{print $1}')"
  print "uuid=$(dwarfdump --uuid "$review_binary" | awk '{print $2}' | paste -sd ',' -)"
} > "${output_dir}/receipt.txt"
print "receipt=${output_dir}/receipt.txt"
print "review_bundle=${review_bundle}"
print "bundle_identifier=${review_identifier}"
print "result=running pid=${pid}"
