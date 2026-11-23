# Video Star 15.0.3 (1847) — runtime API map

## Evidence / target

- Bundle ID: `com.frontierdesign.videostar`
- App version/build: `15.0.3` / `1847`
- Main executable: ARM64 Mach-O, minimum iOS 17.2, SDK 26.0
- Main executable is not FairPlay-encrypted in the supplied IPA (`cryptid = 0`).
- Objective-C class/method metadata was parsed from the main executable. The signatures below are the method type encodings recorded in that binary. They are private implementation details, not a supported plugin SDK.

## Confirmed editor method encodings

| Class | Selector | Type encoding |
|---|---|---|
| `MultiLayerEngine` | `layerAtLayerNum:` | `@24@0:8Q16` |
| `MultiLayerEngine` | `layerTypeForLayer:` | `i24@0:8Q16` |
| `MultiLayerEngine` | `setupImage:layerNum:layerType:clearMask:` | `@40@0:8@16Q24i32B36` |
| `MultiLayerEngine` | `setupVideoLayer:forLayer:withInitialVolume:multiCheck:` | `@40@0:8@16Q24f32B36` |
| `MultiLayerEngine` | `setupPresetLayer:fromLayer:` | `v32@0:8@16@24` |
| `MultiLayerEngine` | `copyContentFromLayerNum:toLayerNum:forScene:` | `v40@0:8Q16Q24Q32` |
| `MultiLayerWizEffectVC` | `getMultiLayerEngine` | `@16@0:8` |
| `MultiLayerWizEffectVC` | `importNewPreset:keyFrameAction:qrDurationInFrames:` | `v40@0:8@16@24q32` |
| `MultiLayerWizEffectVC` | `selectLayerNum:flash:` | `v28@0:8Q16B24` |
| `MultiLayerWizEffectVC` | `makePhotoLayer:` | `v24@0:8@16` |
| `MultiLayerWizEffectVC` | `makeVideoLayer:frameTimes:volume:` | `v40@0:8@16@24@32` |
| `QRCodeManager` | `readQRCode:` | `@24@0:8@16` |
| `QRCodeManager` | `validQRCheck:` | `B24@0:8@16` |
| `QRCodeManager` | `selectedCode:withImageData:` | `v32@0:8@16@24` |
| `QRCodeManager` | `saveCodeToPlist:desc:` | `v32@0:8@16@24` |

These encodings are also embedded in `VideoStarRuntimeInspector.swift`. The inspector checks the host bundle identifier/version/build, that the host exposes those methods with the expected encodings, and reports loaded dependency images. It does not invoke any of the private methods.

## Feature map (evidence vs implementation)

| Requested feature | Static evidence in the supplied app/tool | Current rebuild status |
|---|---|---|
| Replace Media / import images into layers | `MultiLayerWizEffectVC.makePhotoLayer:`, `makeVideoLayer:frameTimes:volume:`, `selectLayerNum:flash:`; engine `setupImage...`, `setupVideoLayer...`, `layerAtLayerNum:`. Original tool has a `VSToolOverlay` media-apply workflow. | Bridge contract and runtime signature checks only. Exact editor state, object lifecycle and safe call sequence are not established. |
| Last Code | App `QRCodeManager` has `readQRCode:`, `validQRCheck:`, `selectedCode:withImageData:`, `saveCodeToPlist:desc:`. | Local recent-code store + Vietnamese history page + public recordRecentCode(_:) entry point implemented; automatic host QR callback is not connected. |
| Beat Split | Original tool contains `startFeatureBeatSplit`, `beatSplitAdvanceStepWithAttempt:`, `finishBeatSplitNativeWorkflow`. | Independent offline onset/energy analyzer exists; applying markers to a Video Star project still requires an adapter. |
| Multi Scene Apply | `MultiLayerWizEffectVC.importNewPreset:keyFrameAction:qrDurationInFrames:` and `MultiLayerEngine.setupPresetLayer:fromLayer:`. | Bridge contract and runtime signature checks only; preset/project data schema is not documented by the IPA. |
| Merge Scenes | Original tool has a native merge workflow. The submitted app binary contains related selector strings, but this pass did not establish a verified implementation owner + full runtime contract for the complete merge sequence. | Bridge contract only; not implemented. |

## Base modules present in the submitted IPA

The main executable weak-links these components:

- `@rpath/VSPlusUltra.dylib`
- `@executable_path/Frameworks/VSFix1.dylib`
- `@executable_path/Frameworks/VSFix2.dylib`
- `@executable_path/Frameworks/VSFix3.dylib`
- `@executable_path/Frameworks/VSFix4.dylib`

Additional observed install names / relationships:

| Bundled file | Mach-O install name | Notable dependency |
|---|---|---|
| `VSPlusUltra.dylib` | `/Library/MobileSubstrate/DynamicLibraries/VSPlusUltra.dylib` | `@rpath/CydiaSubstrate.framework/CydiaSubstrate` |
| `VSFix1.dylib` | `@rpath/ipacrack_ioscodevn.dylib` | `@executable_path/Frameworks/VSFix4.dylib` |
| `VSFix2.dylib` | `@rpath/LeTi.dylib` | Upward-loads `VSFix4.dylib` |
| `VSFix3.dylib` | `/Library/MobileSubstrate/DynamicLibraries/FireStore.dylib` | `VSFix4.dylib` and private `SpringBoardServices` |
| `VSFix4.dylib` | `@executable_path/Frameworks/libsubstrate.dylib` | Substrate-style loader dependency |

The rebuild keeps these names in its runtime diagnostic manifest as requested for this compatibility target. It does not copy, rename, modify, or redistribute the third-party binaries. `VSPlusUltra` also contains purchase/subscription hooks; the rebuild does not call or alter those entitlement methods.

## Important limits

- Selector strings and type encodings do not document argument semantics, ownership, threading, active-editor requirements, project schema, or rollback rules.
- The supplied IPA is modified and should only be used as the user's authorized compatibility test target. It is not a clean reference for official purchase-entitlement behavior.
- A local rebuild can have its own code and settings run locally, but this does not make Video Star's own services or entitlements offline.
- The original `VideoStarTool(1).dylib` is unchanged and still contains `https://api.shopmduyk.site` and `VSKeyAuth`. The current source rebuild does not link to that old authorization system.
- The source package does not bypass the old key/license mechanism or alter Video Star's StoreModel / subscription checks.
