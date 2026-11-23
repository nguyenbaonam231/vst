# Trạng thái bản dựng — VideoStarTool Local

Ngày kiểm tra: 2026-11-23

## Tình trạng theo hạng mục

| Hạng mục | Trạng thái | Ghi chú / bằng chứng |
|---|---|---|
| Giao diện tiếng Việt, căn giữa, pastel hồng–vàng | Source có | UIKit source; chưa chạy preview trên iOS trong môi trường này |
| Paytone One | Đã cấu hình tra font | Cần host app nhúng/đăng ký `PaytoneOne-Regular.ttf` có quyền sử dụng |
| Tác giả `j4avzckcy` | Có metadata | `Resources/ToolMetadata.plist` |
| Thiết lập feature lưu local | Đã triển khai | `LocalFeatureAccess.swift` + test |
| Mã gần đây lưu local | Đã triển khai | `RecentCodeStore.swift` + test; chưa nối vào callback QR của host |
| Phân tích nhịp offline | Đã triển khai source độc lập | `LocalBeatAnalyzer.swift`; chưa áp dụng marker vào project Video Star |
| Thành công không hiện thông báo | Đã triển khai policy | `SilentMediaLayerImportFeedback.swift` + test; chưa nối callback vào binary gốc |
| Objective-C API signature manifest | Đã tạo | `VideoStarRuntimeInspector.swift`, đối chiếu với IPA 15.0.3 build 1847; kiểm tra cả bundle/version/build |
| Kiểm tra runtime VSPlusUltra / VSFix1–4 / CydiaSubstrate | Đã có source read-only | Chưa chạy trên iPhone; không sửa/copy các module bên thứ ba |
| Replace Media thực tế | Chưa hoàn thành | Chỉ có bridge contract và signature observations |
| Multi Scene Apply thực tế | Chưa hoàn thành | Chỉ có bridge contract và signature observations; thiếu schema project/preset |
| Merge Scenes thực tế | Chưa hoàn thành | Chỉ có bridge contract; thiếu call sequence đã xác nhận |
| Last Code gắn vào Video Star QR | Chưa hoàn thành | Local store có; chưa nối vào host callback |
| Beat Split gắn vào timeline Video Star | Chưa hoàn thành | Local analyzer có; chưa có editor adapter |
| Loại server riêng của binary cũ | Chưa thực hiện | Binary gốc vẫn giữ endpoint `api.shopmduyk.site` và `VSKeyAuth`; source rebuild mới không gọi server |
| iOS ARM64 `.dylib` | Chưa build | Đã thử target SwiftPM `arm64-apple-ios17.2`; workspace thiếu xtool và Darwin Swift SDK. Xem `XTOOL_BUILD_GUIDE.md` và log `swift build --swift-sdk darwin`. |
| Ký và test trong Video Star | Chưa thực hiện | Cần Mac/Xcode, signing setup và thiết bị test phù hợp |

## Kiểm thử đã chạy

- `swift test`: **7 tests passed, 0 failures** trên `x86_64-unknown-linux-gnu`.
- `Scripts/audit-local-source.sh`: **PASS**; không tìm thấy `api.shopmduyk.site`, `URLSession` hoặc `URLRequest` trong source mới.
- Runtime API manifest: tests xác nhận target host, method uniqueness và có các dependency `VSPlusUltra`, `VSFix1`–`VSFix4`, `CydiaSubstrate`. Inspector trên iOS chỉ đọc `class_getInstanceMethod` / `method_getTypeEncoding` và danh sách ảnh dyld; không invoke method.

## Không được hiểu nhầm

- `swift test` trên Linux chỉ xác nhận phần Swift có thể biên dịch trên Linux và logic đã được test. Nó không kiểm tra nhánh UIKit, AVFoundation hay Objective-C runtime trên iOS.
- File `.build/.../libVideoStarToolLocal.so` là thư viện Linux. Nó **không phải** iOS `.dylib`.
- `VSPlusUltra` và `VSFix1`–`VSFix4` được giữ trong bản đồ dependency và được kiểm tra sự hiện diện ở runtime; project không sao chép, thay đổi hoặc can thiệp các hook mua hàng/subscription của chúng.
- Bản source mới không phụ thuộc server cũ, nhưng binary gốc chưa bị sửa và vẫn có code xác thực server.
- Không thể tuyên bố bản rebuild fully local hoặc feature-complete cho đến khi có editor adapter thật, chạy thành công trên thiết bị, và các luồng thao tác được xác thực trên project test.

## Thử nghiệm xtool trong môi trường hiện tại

- Repo xtool xác định đây là công cụ build/deploy iOS trên Linux/WSL/macOS; README phân biệt thao tác cài SDK (`xtool setup`, `xtool sdk`) và build/deploy SwiftPM package (`xtool dev`).
- Hướng dẫn Linux/Windows hiện tại yêu cầu Swift 6.4+ và `Xcode.xip`; `xtool setup` dùng Xcode XIP để tạo/cài Darwin Swift SDK. Sau đó `swift sdk list` cần hiển thị `darwin`.
- Workspace hiện tại: Linux x86_64, Swift 6.2.1; không có executable `xtool`, không có Swift SDK bundle nào (`swift sdk list`: `No Swift SDKs are currently installed`), không có Xcode.xip.
- Đã thử lệnh compile package phù hợp với SwiftPM dynamic product: `swift build --swift-sdk darwin --triple arm64-apple-ios17.2 -c release --product VideoStarToolLocal`.
- Kết quả thực tế: `error: No valid Swift SDK bundles found at /home/oai/.config/swiftpm/swift-sdks.` Vì vậy không thể tiếp tục compile ARM64 iOS trong container này.
- Đã thêm `Scripts/build-ios-xtool.sh` để build sau khi xtool + Swift 6.4 + Darwin SDK được cài đầy đủ; script kiểm tra yêu cầu trước khi build và xác minh artifact là Mach-O ARM64.
- Không tạo file giả `.dylib`: artifact `.so` trong `.build` chỉ phục vụ test Linux.

## GitHub Actions build path added (2026-11-23)

- Added `.github/workflows/build-ios-dylib.yml`, targeting GitHub-hosted `xcode-27` Apple Silicon runner.
- Added `Scripts/build-ios-macos-ci.sh`, which builds the SwiftPM dynamic-library product for `arm64-apple-ios17.2` using the iPhoneOS SDK supplied by Xcode, validates Mach-O/ARM64, and records platform/build information.
- Added `Docs/GITHUB_ACTIONS_BUILD.md` with repository setup and artifact download instructions.
- This workflow has been authored but **not executed** in this workspace because it cannot dispatch jobs into a user's GitHub repository. No iOS `.dylib` has been generated here.
- Expected result after a successful Actions run: an unsigned `VideoStarTool.dylib` artifact. It is a compiled source module, not proof of a complete editor integration; the EditorBridge implementation and on-device validation remain outstanding.
