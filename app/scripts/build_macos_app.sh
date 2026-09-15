#!/bin/zsh
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
app_dir="$(cd "${script_dir}/.." && pwd)"
bundle_dir="$(cd "${app_dir}/.." && pwd)/build/Latticewake.app"
binary_dir="${app_dir}/.build/arm64-apple-macosx/debug"

cd "${app_dir}"
swift build -c debug
mkdir -p "${bundle_dir}/Contents/MacOS" "${bundle_dir}/Contents/Resources"
cp "${binary_dir}/LatticewakeApp" "${bundle_dir}/Contents/MacOS/LatticewakeApp"
cp "${app_dir}/Resources/Info.plist" "${bundle_dir}/Contents/Info.plist"
codesign --force --sign - "${bundle_dir}"
echo "${bundle_dir}"
