# Phân tích tĩnh binary gốc

File: `VideoStarTool(1).dylib` — 1,665,240 bytes.

## Load commands đã quan sát

- `MH_MAGIC_64`, CPU `ARM64`, filetype `DYLIB`.
- `LC_BUILD_VERSION`: iOS, minimum OS 15.0, SDK 15.6; tool `lld`.
- `LC_ENCRYPTION_INFO_64`: `cryptid = 0` (không được đánh dấu mã hóa FairPlay trong load command).
- `LC_ID_DYLIB`: `@executable_path/Frameworks/VideoStarTool.dylib`.
- `LC_CODE_SIGNATURE` hiện diện.
- Linked Apple frameworks gồm Foundation, CoreFoundation, UIKit, CoreGraphics, AVFoundation, CoreImage, Security, SafariServices, CoreText, SystemConfiguration, QuartzCore, PhotosUI, CoreMedia và CFNetwork; cùng libobjc, libc++ và libSystem.

## Endpoint và xác thực

- Chuỗi endpoint: `https://api.shopmduyk.site`.
- Các class/nhóm: `VSKeyAuth`, `VSIntegrity`, `VSResponseVerifier`, `VSNetworkSecurity`.
- Selector: `verifySavedKeyWithCompletion:`, `verifyKey:allowOfflineGrace:isSavedKey:completion:`, `secretProofForKey:deviceID:timestamp:nonce:`, `handleResponse:status:error:key:allowOfflineGrace:isSavedKey:completion:`, `persistKey:expiresAt:`, `activateKey:completion:`.
- Có symbol liên quan `NSURLSession`, `CC_SHA256`, `CCHmac`, `SecKeyVerifySignature`, `SecKeyCreateWithData`.

## API editor và các feature

- `getMultiLayerEngine`, `layerAtLayerNum:`, `makePhotoLayer:`, `makeVideoLayer:frameTimes:volume:`, `confirmAddingLayer:object:object2:object3:isAbleToShowTheLayerActionMenu:`.
- Feature entry points: `startFeatureReplaceMedia`, `startFeatureLastCode`, `startFeatureBeatSplit`, `startFeatureMultiSceneApply`.
- Media workflow: `beginNativeMediaChoiceForEditor:mode:`, `beginMediaApplyForEditor:records:mode:`, `mediaApplyFinishChanged:error:`.
- Merge workflow: `showMergeScenes`, `beginNativeMergeCodeImportForEditor:offset:project:`, `mergeCreateSceneWithEditor:`.
- Alert selectors: `showCompletionAlertWaitingForOK:message:index:`, `showSimpleAlert:message:index:`.

## Giới hạn

Đây là kết quả static analysis (Mach-O load commands và printable strings/Objective-C selector names). Chưa có runtime trace, call graph symbolicated, class layout, method type encodings được giải đầy đủ, headers hoặc schema của project. Tên selector không đủ để suy ra toàn bộ contract/hành vi. Do đó không thể đảm bảo tái tạo chức năng editor từ các chuỗi này.
