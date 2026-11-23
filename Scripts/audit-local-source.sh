#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="$ROOT/Sources"

if grep -RInE 'api\.shopmduyk\.site|URLSession|NSMutableURLRequest|URLRequest\(' "$SOURCE"; then
  echo "Có chuỗi/mã mạng trong source mới; cần rà soát trước khi gọi là offline-only." >&2
  exit 1
fi

echo "OK: không tìm thấy endpoint cũ hoặc API URLSession/URLRequest trong source mới."
echo "Lưu ý: kiểm tra này chỉ áp dụng source rebuild; không áp dụng binary gốc."
