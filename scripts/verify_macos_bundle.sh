#!/bin/zsh
# Proves that build/Latticewake.app contains the SwiftPM executable just built.
set -euo pipefail

root_dir="$(cd "$(dirname "$0")/.." && pwd)"
app_dir="${root_dir}/app"
bundle_binary="${root_dir}/build/Latticewake.app/Contents/MacOS/LatticewakeApp"

cd "$app_dir"
swift build -c debug >/dev/null
product_dir="$(swift build -c debug --show-bin-path)"
product_binary="${product_dir}/LatticewakeApp"

[[ -x "$product_binary" && -x "$bundle_binary" ]] || {
  print -- "missing SwiftPM product or app-bundle executable" >&2
  exit 66
}

product_uuid="$(dwarfdump --uuid "$product_binary" | awk '{print $2}' | paste -sd ',' -)"
bundle_uuid="$(dwarfdump --uuid "$bundle_binary" | awk '{print $2}' | paste -sd ',' -)"
[[ -n "$product_uuid" && "$product_uuid" == "$bundle_uuid" ]] || {
  print -- "bundle code UUID does not match SwiftPM product" >&2
  print -- "product=$product_uuid bundle=$bundle_uuid" >&2
  exit 1
}

codesign --verify --deep --strict "${root_dir}/build/Latticewake.app"
print "bundle_code_uuid=$bundle_uuid"
