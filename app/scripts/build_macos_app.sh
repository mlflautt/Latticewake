#!/bin/zsh
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
app_dir="$(cd "${script_dir}/.." && pwd)"
bundle_dir="$(cd "${app_dir}/.." && pwd)/build/Latticewake.app"

if ! /usr/bin/xcodebuild -license check >/dev/null 2>&1; then
  export DEVELOPER_DIR=/Library/Developer/CommandLineTools
fi
export CLANG_MODULE_CACHE_PATH="$(cd "${app_dir}/.." && pwd)/build/clang-module-cache"

cd "${app_dir}"
swift build -c debug
binary_dir="$(swift build -c debug --show-bin-path)"
mkdir -p "${bundle_dir}/Contents/MacOS" "${bundle_dir}/Contents/Resources"
cp "${binary_dir}/LatticewakeApp" "${bundle_dir}/Contents/MacOS/LatticewakeApp"
cp "${app_dir}/Resources/Info.plist" "${bundle_dir}/Contents/Info.plist"
codesign --force --sign - "${bundle_dir}"
echo "${bundle_dir}"
