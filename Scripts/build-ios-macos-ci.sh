#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TRIPLE="${IOS_TARGET_TRIPLE:-arm64-apple-ios17.2}"
PRODUCT="VideoStarToolLocal"
OUT="$ROOT/dist"

fail() {
  echo "BUILD ERROR: $*" >&2
  exit 2
}

[[ "$(uname -s)" == "Darwin" ]] || fail "This script must run on macOS with Xcode."
command -v xcodebuild >/dev/null 2>&1 || fail "xcodebuild is unavailable."
command -v xcrun >/dev/null 2>&1 || fail "xcrun is unavailable."
command -v swift >/dev/null 2>&1 || fail "Swift is unavailable."
command -v install_name_tool >/dev/null 2>&1 || fail "install_name_tool is unavailable."

xcodebuild -version
SDK_PATH="$(xcrun --sdk iphoneos --show-sdk-path)"
SDK_VERSION="$(xcrun --sdk iphoneos --show-sdk-version)"
[[ -d "$SDK_PATH" ]] || fail "iPhoneOS SDK path does not exist: $SDK_PATH"

echo "==> iPhoneOS SDK: $SDK_VERSION ($SDK_PATH)"
echo "==> Swift toolchain: $(swift --version | head -n 1)"
echo "==> Target: $TRIPLE"

cd "$ROOT"
bash Scripts/audit-local-source.sh
swift test -c release

swift build \
  --package-path "$ROOT" \
  --configuration release \
  --product "$PRODUCT" \
  --sdk "$SDK_PATH" \
  --triple "$TRIPLE"

BIN_DIR="$(swift build \
  --package-path "$ROOT" \
  --configuration release \
  --show-bin-path \
  --sdk "$SDK_PATH" \
  --triple "$TRIPLE")"

LIBRARY=""
for candidate in \
  "$BIN_DIR/lib${PRODUCT}.dylib" \
  "$BIN_DIR/${PRODUCT}.dylib"; do
  if [[ -f "$candidate" ]]; then
    LIBRARY="$candidate"
    break
  fi
done

if [[ -z "$LIBRARY" ]]; then
  LIBRARY="$(find "$BIN_DIR" -type f -name '*VideoStarToolLocal*.dylib' -print -quit)"
fi
[[ -n "$LIBRARY" && -f "$LIBRARY" ]] || fail "SwiftPM completed but no dynamic library was found under $BIN_DIR."

mkdir -p "$OUT"
FINAL="$OUT/VideoStarTool.dylib"
cp "$LIBRARY" "$FINAL"
install_name_tool -id '@rpath/VideoStarTool.dylib' "$FINAL"

FILE_INFO="$(file "$FINAL")"
echo "$FILE_INFO"
printf '%s' "$FILE_INFO" | grep -q 'Mach-O' || fail "Output is not a Mach-O binary."
lipo -verify_arch arm64 "$FINAL" || fail "Output does not contain ARM64."
xcrun vtool -show-build "$FINAL" | tee "$OUT/platform-info.txt"

cat > "$OUT/build-info.txt" <<INFO
Product: VideoStarTool
Author metadata: j4avzckcy
Host inspected: com.frontierdesign.videostar 15.0.3 (1847)
Target: $TRIPLE
SDK: iPhoneOS $SDK_VERSION
Xcode: $(xcodebuild -version | tr '\n' ' ')
Signing: unsigned (must be signed by the authorized host/development setup)
Runtime integration: not validated; editor bridge remains incomplete
INFO

echo ""
echo "Created: $FINAL"
echo "This artifact compiles the current source only. It does not implement the missing Video Star editor bridge or alter the original binary's authorization system."
