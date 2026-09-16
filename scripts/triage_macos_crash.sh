#!/bin/zsh
# Safe local crash triage for the standalone Latticewake app.
# It never deletes reports or terminates processes. Use its generated bundle
# when asking an agent to investigate a target-Mac failure.
set -euo pipefail

usage() {
  print "usage: $0 baseline|smoke|report [--app APP_BUNDLE] [--out DIRECTORY] [--seconds N]"
  exit 64
}

mode="${1:-}"
[[ -n "${mode}" ]] || usage
shift
app_bundle="${LW_APP_BUNDLE:-$(cd "$(dirname "$0")/.." && pwd)/build/Latticewake.app}"
output_dir="${LW_CRASH_TRIAGE_DIR:-$(cd "$(dirname "$0")/.." && pwd)/build/crash-triage}"
seconds=8
while (( $# > 0 )); do
  case "$1" in
    --app) app_bundle="${2:-}"; shift 2 ;;
    --out) output_dir="${2:-}"; shift 2 ;;
    --seconds) seconds="${2:-}"; shift 2 ;;
    *) usage ;;
  esac
done

[[ "$seconds" == <-> ]] || { print -- "--seconds must be a non-negative integer" >&2; exit 64; }
binary="${app_bundle}/Contents/MacOS/LatticewakeApp"
plist="${app_bundle}/Contents/Info.plist"
diagnostic_dir="${LW_DIAGNOSTIC_REPORT_DIR:-${HOME}/Library/Logs/DiagnosticReports}"
mkdir -p "$output_dir"

write_metadata() {
  [[ -x "$binary" && -f "$plist" ]] || { print -- "app bundle not found: $app_bundle" >&2; exit 66; }
  {
    print "captured_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    print "app_bundle=$app_bundle"
    print "binary=$binary"
    print "version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$plist")"
    print "build=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$plist")"
    print "binary_sha256=$(shasum -a 256 "$binary" | awk '{print $1}')"
    print "uuid=$(dwarfdump --uuid "$binary" | awk '{print $2}' | paste -sd ',' -)"
  } > "$output_dir/build-metadata.txt"
}

baseline() {
  write_metadata
  date +%s > "$output_dir/baseline-epoch.txt"
  find "$diagnostic_dir" -maxdepth 1 -type f -name 'LatticewakeApp-*.ips' -print 2>/dev/null | sort > "$output_dir/reports-before.txt" || true
  print "baseline=$output_dir"
}

new_reports() {
  [[ -f "$output_dir/baseline-epoch.txt" ]] || { print -- "missing baseline; run baseline first" >&2; exit 65; }
  local epoch marker
  epoch="$(cat "$output_dir/baseline-epoch.txt")"
  marker="$output_dir/.baseline-marker"
  touch -t "$(date -r "$epoch" +%Y%m%d%H%M.%S)" "$marker"
  find "$diagnostic_dir" -maxdepth 1 -type f -name 'LatticewakeApp-*.ips' -newer "$marker" -print 2>/dev/null | sort
  rm -f "$marker"
}

classify() {
  local report="$1"
  if rg -q 'swift_task_checkIsolatedSwift|_swift_task_checkIsolatedSwift' "$report"; then
    print "classification=Swift concurrency executor isolation"
  elif rg -q 'MIDIIngress|CoreMIDI' "$report"; then
    print "classification=Core MIDI ingress/lifecycle"
  elif rg -q 'SwiftUICore|LayoutEngine|NSHostingView\.layout' "$report"; then
    print "classification=SwiftUI layout or view lifecycle"
  elif rg -q 'AVAudio|AudioUnit|CoreAudio' "$report"; then
    print "classification=audio host/callback route"
  else
    print "classification=unclassified; preserve report and symbolize app frames"
  fi
}

report() {
  write_metadata
  local reports_text newest
  reports_text="$(new_reports)"
  if [[ -z "$reports_text" ]]; then
    print "result=no new Latticewake crash report since baseline"
    return
  fi
  newest="${${(f)reports_text}[-1]}"
  cp "$newest" "$output_dir/latest-report.ips"
  {
    print "report=$newest"
    rg -m 1 '"app_version"|^Process:|^Version:|^Triggered by Thread:|^Exception Type:|^Termination Reason:' "$newest" || true
    classify "$newest"
    print "-- Latticewake frames --"
    rg -n 'LatticewakeApp|MIDIIngress|AudioEngine|TerrainMetalView|LatticewakeApp\.swift' "$newest" | head -80 || true
  } > "$output_dir/summary.txt"
  cat "$output_dir/summary.txt"
  print "result=new report copied to $output_dir/latest-report.ips"
}

smoke() {
  baseline
  open -n "$app_bundle"
  sleep "$seconds"
  report
}

case "$mode" in
  baseline) baseline ;;
  smoke) smoke ;;
  report) report ;;
  *) usage ;;
esac
