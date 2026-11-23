# Build VideoStarTool Local bằng xtool trên Linux / WSL

## Khả năng và giới hạn

xtool là bộ công cụ build/deploy iOS đa nền tảng. Trên Linux, xtool cần Swift 6.4+, và một Darwin Swift SDK được tạo/cài từ Xcode XIP. xtool không tự cung cấp iOS SDK độc lập với Xcode.

Project này là Swift Package có dynamic-library product `VideoStarToolLocal`, không phải app executable. Sau khi cài Darwin SDK, script dùng SwiftPM với SDK do xtool cài để build trực tiếp dynamic library ARM64 iOS.

## Chuẩn bị trên Linux / WSL

1. Cài Swift 6.4 theo hướng dẫn chính thức: <https://xtool.sh/documentation/xtool/installation-linux/>
2. Cài xtool release phù hợp từ <https://github.com/xtool-org/xtool/releases>.
3. Tải Xcode XIP từ Apple Developer Downloads (cần đăng nhập Apple ID và chấp nhận điều khoản Apple).
4. Chạy `xtool setup`, hoàn tất đăng nhập theo lựa chọn của xtool và chỉ đường dẫn tới file `Xcode.xip`.
5. Xác nhận `swift sdk list` hiển thị `darwin`.

Không gửi Apple ID, mật khẩu, mã 2FA, App Store Connect private key hay signing certificate lên chat.

## Build

Từ thư mục project:

```bash
bash Scripts/build-ios-xtool.sh
```

Mặc định build target `arm64-apple-ios17.2`, phù hợp deployment target đang khai báo trong Package.swift. Có thể đổi target bằng biến môi trường `IOS_TARGET_TRIPLE` nếu đã kiểm tra compatibility.

Artifact dự kiến:

```text
dist/VideoStarTool.dylib
```

Script kiểm tra Mach-O và ARM64 khi có `file` trên máy build. Artifact không tự động được ký và việc compile thành công không chứng minh plugin có thể được load an toàn trong host.

## Quan trọng

- Build thành công chỉ có nghĩa source hiện có được compile thành ARM64 iOS dylib.
- Các workflow Replace Media, Multi Scene Apply, Merge Scenes, Last Code host callback và Beat Split timeline vẫn cần editor adapter đã được triển khai, xác thực và test trong Video Star 15.0.3.
- Project không sửa `StoreModel` / StoreKit, không giả mạo subscription và không sao chép/đóng gói lại các dylib bên thứ ba `VSPlusUltra` / `VSFix1–4` / CydiaSubstrate.
- Không dùng `.so` Linux làm iOS dylib và không đổi đuôi `.so` thành `.dylib`.
