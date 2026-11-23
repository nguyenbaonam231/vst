# Ghi chú bàn giao – VideoStarTool Local

## Có trong gói

- Source Swift Package dynamic library `VideoStarToolLocal`.
- Giao diện UIKit tiếng Việt, căn giữa, viền/nền pastel hồng–vàng và tra font Paytone One.
- Metadata tác giả `j4avzckcy`.
- Recent Code local: lưu trữ, trang lịch sử, sao chép mã, xóa lịch sử và entry point `recordRecentCode(_:)`.
- Phân tích nhịp âm thanh offline độc lập.
- Chính sách không hiện thông báo khi thao tác thành công; lỗi vẫn được trả về.
- Runtime inspector chỉ đọc: kiểm tra bundle/version/build, Objective-C type encodings và image names của VSPlusUltra/VSFix1–4/CydiaSubstrate.
- Tài liệu ABI/dependency từ IPA 15.0.3 build 1847.

## Không có trong gói

- Không có binary iOS `.dylib` đã build/ký.
- Không có adapter đang hoạt động để sửa project Video Star cho Replace Media, Beat Split, Multi Scene Apply hoặc Merge Scenes.
- Không đóng gói/copy các thư viện bên thứ ba từ IPA. Các tên VSPlusUltra/VSFix/CydiaSubstrate chỉ nằm trong runtime manifest.
- Không có mã để giả mạo quyền mua/subscription trong Video Star hoặc vượt kiểm tra cấp phép của tool cũ.

## Build trên Mac

1. Mở `Package.swift` bằng Xcode trên macOS có iOS SDK.
2. Thêm/đăng ký font `PaytoneOne-Regular.ttf` có quyền sử dụng trong host app nếu cần đúng font.
3. Hoàn thiện adapter bằng API/header được phép sử dụng và xác thực trên thiết bị thử nghiệm.
4. Chạy `Scripts/build-ios.sh`; script tạo/stage `dist/VideoStarTool.dylib` khi có Xcode.
5. Kiểm tra kiến trúc/install name và ký bằng signing identity hợp lệ của người triển khai.

## Trạng thái xác minh ở workspace này

- `swift test`: 7/7 PASS trên Linux x86_64.
- `Scripts/audit-local-source.sh`: PASS; source mới không chứa endpoint server cũ hoặc URLSession/URLRequest.
- `Scripts/build-ios.sh`: dừng đúng với exit 2 vì workspace là Linux và không có Xcode/iOS SDK.
- `.build/x86_64-unknown-linux-gnu/debug/libVideoStarToolLocal.so` là ELF Linux, không phải iOS `.dylib`.
