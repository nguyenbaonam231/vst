# VideoStarTool Local — source rebuild for Video Star 15.0.3

**Author metadata:** `j4avzckcy`  
**Source version:** `1.0.0-local`  
**Target host inspected:** `com.frontierdesign.videostar` version `15.0.3`, build `1847`  
**Target architecture:** iOS ARM64

## What is actually implemented

- UIKit tool panel in the requested original-style layout: Vietnamese text, centered labels, pastel pink/yellow gradient frame/background, and Paytone One lookup (`PaytoneOne-Regular` if the host has registered the font).
- Local feature preferences stored with `UserDefaults`.
- Local recent-code history (deduplicated, capped, and stored on device).
- An independent offline audio onset/energy analyzer. It is a new implementation and is not claimed to reproduce the original tool's Beat Split algorithm.
- Silent-success feedback policy: successful media changes do not trigger a success popup/toast; failures can still be reported.
- `VideoStarRuntimeInspector`: read-only checks for the host app's bundle/version/build, Objective-C method type encodings, and runtime images `VSPlusUltra`, `VSFix1`–`VSFix4`, and CydiaSubstrate. It never invokes host methods.
- `VideoStarEditorBridge`: an interface contract for the operations that still need an authorized, tested editor adapter.

## Feature status

| Feature | Rebuild status |
|---|---|
| Last Code | Local storage is implemented; host QR callback is not connected. |
| Beat Split | Offline beat/onset analysis is implemented; applying the results to a Video Star project still needs an editor adapter. |
| Replace Media | UI + bridge contract + read-only API checks; actual host project mutation is not implemented. |
| Multi Scene Apply | UI + bridge contract + read-only API checks; preset/project schema and mutation flow are not implemented. |
| Merge Scenes | UI + bridge contract; merge sequence is not implemented. |

Do not treat the feature buttons as proof that their editor operations are already working. The executor deliberately reports a missing bridge as an error rather than faking a success state.

## Server / authorization scope

The newly written source code has no endpoint or networking client for `api.shopmduyk.site`; the static source audit checks for the old endpoint and common URL request APIs. The old `VideoStarTool(1).dylib` has not been modified and still contains `VSKeyAuth` and the old server endpoint. The rebuild is separate source, not a patch of the original binary.

The rebuild also does not patch Video Star's own StoreModel / StoreKit purchase or subscription checks. `VSPlusUltra` and `VSFix1`–`VSFix4` remain in the compatibility manifest because the supplied IPA weak-links or contains them and you identified them as part of your target runtime. The new project checks their runtime presence only. It does not package, copy, modify, or redistribute their third-party binaries.

## Runtime API findings

See [`VIDEO_STAR_15_0_3_RUNTIME_API.md`](VIDEO_STAR_15_0_3_RUNTIME_API.md) for the exact type encodings recovered from the supplied main executable, observed runtime dependency names, and per-feature evidence/status.

The method inspector is read-only. Exact method encodings are not enough to infer private method argument semantics, object lifetime, threading rules, or project data structure. A genuine editor adapter still needs vendor documentation/headers or authorized device-level validation with a reversible test project. The runtime inspector is a compatibility diagnostic, not an adapter and not a guarantee that an undocumented method is safe to call.

## Build the iOS dynamic library

### Linux / WSL with xtool

See [`XTOOL_BUILD_GUIDE.md`](XTOOL_BUILD_GUIDE.md). After installing Swift 6.4+, xtool, and the `darwin` Swift SDK generated from Xcode XIP, run `bash Scripts/build-ios-xtool.sh`. This builds the SwiftPM dynamic-library product for ARM64 iOS and stages `dist/VideoStarTool.dylib`.

### macOS with Xcode

The current workspace is Linux and does not have xtool or a Darwin Swift SDK installed, so no iOS `.dylib` has been built here. The xtool Linux path is documented above.

On a Mac with Xcode and the iOS SDK:

1. Open this Swift Package in Xcode.
2. Add the licensed `PaytoneOne-Regular.ttf` to the host app's resources and register it in the host app's `UIAppFonts` if you want that font rendered.
3. Complete and validate the editor bridge for the target host build. Do not assume a selector is safe to call merely because it exists.
4. Run `Scripts/build-ios.sh` to build an ARM64 iOS dynamic library and stage it as `dist/VideoStarTool.dylib`.
5. Inspect the result's Mach-O architecture and install name, then sign/load it only through an authorized development or tweak environment that you control.

The build script intentionally fails when Xcode/iOS SDK is missing. A Linux `.so` in `.build` is only a test artifact; it is not an iOS library and must not be renamed to `.dylib`.

## Tests performed in this workspace

- `swift test`: 7 tests passed, 0 failures on `x86_64-unknown-linux-gnu`.
- `Scripts/audit-local-source.sh`: passed; no old API endpoint, `URLSession`, or `URLRequest` was found in the new `Sources/` folder.
- UIKit/AVFoundation/Objective-C runtime branches have not been compiled or executed against an Apple iOS SDK/device in this workspace.

## Handoff documents

- [`DELIVERY_NOTES.md`](DELIVERY_NOTES.md) – what is included and what is still blocked.
- [`Docs/VideoStar_IPA_API_Report.md`](Docs/VideoStar_IPA_API_Report.md) – recovered app metadata and method signatures.
- [`Docs/VideoStar_VS_Dependency_Map.md`](Docs/VideoStar_VS_Dependency_Map.md) – VSPlusUltra / VSFix / Substrate dependency observations.

## Build with GitHub Actions (recommended alternative)

If you do not have Xcode locally, push this project folder to a private GitHub repository and run the manual workflow at `.github/workflows/build-ios-dylib.yml`. It uses the GitHub-hosted `xcode-27` Apple Silicon runner and the iPhoneOS SDK included with Xcode, then uploads `VideoStarTool.dylib` as an unsigned artifact. See [`Docs/GITHUB_ACTIONS_BUILD.md`](Docs/GITHUB_ACTIONS_BUILD.md).

This build path produces a compile artifact from the current source; it does not complete or validate the missing Video Star editor adapter, change the original binary's authorization checks, or guarantee runtime loading.

## Chức năng local độc lập (bản source 1.1.0)

`LocalToolKit` gom các chức năng có thể chạy không cần server:

- `importMedia(_:)`: sao chép ảnh/video người dùng chọn vào kho media riêng; import theo batch có rollback nếu một tệp lỗi.
- `rememberCode(_:)`: lưu mã gần đây trên thiết bị thông qua `RecentCodeStore`.
- `savePreset(_:title:)`: lưu payload preset opaque tại chỗ; không diễn giải định dạng riêng của ứng dụng chủ.
- `analyzeBeats(in:sensitivity:completion:)`: phân tích nhịp âm thanh offline bằng AVFoundation trên iOS/macOS.
- `exportBeatMarkers(...)`: xuất beat markers thành JSON hoặc CSV.

Ví dụ khởi tạo từ một host app do bạn kiểm soát:

```swift
let root = FileManager.default.urls(
    for: .applicationSupportDirectory,
    in: .userDomainMask
)[0].appendingPathComponent("MyLocalVideoTools", isDirectory: true)
let kit = try LocalToolKit(rootDirectoryURL: root)

// Copy media into the host app's local sandbox.
let imported = try kit.importMedia(selectedFileURLs)

// Store a code locally (for example, from the host app's own QR callback).
kit.rememberCode("MY-CODE-001")

// Keep preset bytes locally without assuming a third-party project schema.
let savedPreset = try kit.savePreset(presetData, title: "Preset pastel")
```

Các chức năng này không tự động sửa timeline của Video Star. `VideoStarEditorBridge` vẫn là hợp đồng tích hợp cho một host/SDK được phép; project không tự gọi private selector hoặc thay đổi purchase/subscription checks của ứng dụng khác.
