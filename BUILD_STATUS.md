# Trạng thái bản dựng — VideoStarTool Local 1.1.0

Ngày cập nhật: 2026-11-23

## Đã triển khai trong source

| Thành phần | Trạng thái | Phạm vi đã xác minh |
|---|---|---|
| Giao diện UIKit pastel, tiếng Việt, căn giữa | Có source | Chưa preview trên thiết bị iOS |
| Paytone One | Có tra font và fallback | Host cần nhúng font có quyền sử dụng |
| Metadata tác giả `j4avzckcy` | Có | `ToolMetadata.plist` |
| Feature preferences | Local | UserDefaults, reset được |
| Recent Code | Local | Lưu, deduplicate, giới hạn số mục, xóa; cần host gọi callback ghi mã |
| Media vault | Local | Sao chép ảnh/video được chọn vào sandbox; batch rollback khi lỗi |
| Preset store | Local | Lưu/đọc/liệt kê/xóa payload opaque; không giả định schema app khác |
| Beat Analyzer | Local | AVFoundation source cho iOS/macOS; chưa áp dụng marker vào timeline Video Star |
| Beat marker exporter | Local | Xuất JSON/CSV |
| Success feedback | Local policy | Không phát thông báo thành công; chuyển lỗi cho host |
| Runtime inspector | Read-only | Kiểm tra bundle/version/build, method encoding và loaded image presence; không invoke private methods |

## Chưa triển khai / không tuyên bố hoàn tất

| Thành phần | Trạng thái | Lý do |
|---|---|---|
| Replace Media trên layer Video Star | Chưa tích hợp | Cần adapter/API được phép và kiểm thử trong app host |
| Multi Scene Apply | Chưa tích hợp | Chưa có schema project/preset chính thức |
| Merge Scenes trong project Video Star | Chưa tích hợp | Chưa có adapter/API hợp lệ; local preset/media storage không đồng nghĩa thao tác project |
| Beat markers trên timeline Video Star | Chưa tích hợp | Analyzer tạo timestamp nhưng chưa có editor adapter |
| Bỏ hoặc giả mạo key/subscription/purchase của Video Star | Không hỗ trợ | Không sửa cơ chế cấp phép của ứng dụng bên thứ ba |
| Thay server auth của binary cũ | Chưa thực hiện | Source rebuild mới không dùng endpoint cũ; không vá binary gốc để vượt cấp phép |
| Ký và chạy trong Video Star | Chưa kiểm thử | Cần quy trình ký hợp lệ, môi trường host được phép và thiết bị thử nghiệm |

## Kiểm thử hiện tại

- `swift test -c release`: **13 tests passed, 0 failures** trên `x86_64-unknown-linux-gnu`.
- `Scripts/audit-local-source.sh`: PASS; source rebuild không chứa endpoint cũ hoặc `URLSession`/`URLRequest`.
- Lưu ý: Linux tests không compile/execute nhánh UIKit/AVFoundation/Objective-C của iOS.

## iOS dylib artifact trước đó

Artifact do GitHub Actions tạo trước lần cập nhật source 1.1.0 là Mach-O ARM64 iOS dynamic library. Artifact đó **không chứa các module 1.1.0 vừa thêm**. Cần commit source mới để workflow chạy lại và tạo artifact mới.

Workflow hiện tại:

- Runner: `xcode-27` (Apple Silicon macOS runner).
- Chạy unit tests.
- Build SwiftPM dynamic library cho `arm64-apple-ios17.2`.
- Kiểm tra Mach-O / ARM64 và upload artifact unsigned.

Một build xanh chỉ chứng minh package biên dịch được thành iOS dynamic library; không chứng minh editor integration hoặc toàn bộ feature Video Star hoạt động.
