#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TRIPLE="${IOS_TARGET_TRIPLE:-arm64-apple-ios17.2}"
SDK_ID="${XTOOL_SWIFT_SDK_ID:-darwin}"
OUT="$ROOT/dist"

fail() {
  echo "LỖI: $*" >&2
  exit 2
}

command -v swift >/dev/null 2>&1 || fail "Không tìm thấy Swift toolchain. Cài Swift theo hướng dẫn xtool Linux/Windows."
command -v xtool >/dev/null 2>&1 || fail "Không tìm thấy xtool. Cài xtool và chạy 'xtool setup' trước."

SWIFT_LINE="$(swift --version | head -n 1)"
SWIFT_VERSION="$(printf '%s' "$SWIFT_LINE" | sed -nE 's/.*Swift version ([0-9]+)\.([0-9]+).*/\1.\2/p')"
[[ -n "$SWIFT_VERSION" ]] || fail "Không đọc được phiên bản Swift: $SWIFT_LINE"
SWIFT_MAJOR="${SWIFT_VERSION%%.*}"
SWIFT_MINOR="${SWIFT_VERSION##*.}"
if (( SWIFT_MAJOR < 6 || (SWIFT_MAJOR == 6 && SWIFT_MINOR < 4) )); then
  fail "xtool Linux hiện yêu cầu Swift 6.4 trở lên; đang có Swift $SWIFT_VERSION."
fi

SDK_LIST="$(swift sdk list 2>&1 || true)"
if ! printf '%s\n' "$SDK_LIST" | grep -Eq "^[[:space:]]*${SDK_ID}[[:space:]]*$"; then
  cat >&2 <<MSG
Không tìm thấy Swift SDK '$SDK_ID'.
Hãy cài xtool, tải Xcode.xip từ Apple Developer, rồi chạy 'xtool setup' và chọn Xcode.xip.
Sau khi setup, 'swift sdk list' phải hiển thị '$SDK_ID'.
MSG
  exit 2
fi

cd "$ROOT"
echo "==> Building VideoStarToolLocal for $TRIPLE using Swift SDK '$SDK_ID'"
swift build \
  --package-path "$ROOT" \
  --configuration release \
  --product VideoStarToolLocal \
  --swift-sdk "$SDK_ID" \
  --triple "$TRIPLE"

BIN_DIR="$(swift build --package-path "$ROOT" --configuration release --show-bin-path --swift-sdk "$SDK_ID" --triple "$TRIPLE")"
LIBRARY=""
for candidate in \
  "$BIN_DIR/libVideoStarToolLocal.dylib" \
  "$BIN_DIR/VideoStarToolLocal.dylib"; do
  if [[ -f "$candidate" ]]; then LIBRARY="$candidate"; break; fi
done

if [[ -z "$LIBRARY" ]]; then
  LIBRARY="$(find "$BIN_DIR" -maxdepth 2 -type f -name '*VideoStarToolLocal*.dylib' -print -quit)"
fi
[[ -n "$LIBRARY" && -f "$LIBRARY" ]] || fail "Build kết thúc nhưng không tìm thấy dylib trong $BIN_DIR."

mkdir -p "$OUT"
cp "$LIBRARY" "$OUT/VideoStarTool.dylib"

if command -v file >/dev/null 2>&1; then
  DESCRIPTION="$(file "$OUT/VideoStarTool.dylib")"
  echo "$DESCRIPTION"
  printf '%s' "$DESCRIPTION" | grep -q 'Mach-O' || fail "Artifact không phải Mach-O; không phát hành dưới tên dylib iOS."
  printf '%s' "$DESCRIPTION" | grep -qi 'arm64' || fail "Artifact không có kiến trúc ARM64."
fi

echo
echo "Đã tạo: $OUT/VideoStarTool.dylib"
echo "Artifact chưa được ký và chưa được kiểm thử trong Video Star."
