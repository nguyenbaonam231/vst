#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Lỗi: cần macOS với Xcode và iOS SDK; môi trường hiện tại không phải macOS." >&2
  exit 2
fi
if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "Lỗi: không tìm thấy xcodebuild. Hãy cài Xcode và chọn Command Line Tools." >&2
  exit 2
fi
if ! command -v install_name_tool >/dev/null 2>&1; then
  echo "Lỗi: không tìm thấy install_name_tool trong Xcode toolchain." >&2
  exit 2
fi

cd "$ROOT"
DERIVED="$ROOT/.build/DerivedData"
PRODUCTS="$DERIVED/Build/Products/Release-iphoneos"
OUT="$ROOT/dist"
mkdir -p "$OUT"

xcodebuild -resolvePackageDependencies -scheme VideoStarToolLocal
xcodebuild \
  -scheme VideoStarToolLocal \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$DERIVED" \
  ARCHS=arm64 \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGNING_ALLOWED=NO \
  build

mapfile_candidate=""
while IFS= read -r candidate; do
  case "$candidate" in
    */libVideoStarToolLocal.dylib|*/VideoStarToolLocal.dylib|*/libVideoStarTool.dylib)
      mapfile_candidate="$candidate"
      break
      ;;
  esac
done < <(find "$PRODUCTS" -type f -name '*.dylib' -print)

if [[ -z "$mapfile_candidate" ]]; then
  echo "Build đã chạy nhưng không tìm thấy dynamic library mong đợi trong $PRODUCTS." >&2
  find "$PRODUCTS" -maxdepth 4 -type f -print >&2 || true
  exit 3
fi

FINAL="$OUT/VideoStarTool.dylib"
cp "$mapfile_candidate" "$FINAL"
install_name_tool -id '@executable_path/Frameworks/VideoStarTool.dylib' "$FINAL"

file "$FINAL"
if command -v lipo >/dev/null 2>&1; then lipo -info "$FINAL"; fi
if command -v otool >/dev/null 2>&1; then otool -D "$FINAL"; fi

echo
echo "Đã stage dynamic library tại: $FINAL"
echo "Chưa ký và chưa được xác nhận chạy trong host. Hãy ký/load bằng quy trình development hợp lệ của ông."
