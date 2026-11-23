# Video Star IPA – verified static compatibility report

The recovered IPA is the user-supplied Video Star 15.0.3 (build 1847) package. The supplied two ZIP volumes were reassembled and the IPA archive passed CRC validation.

## App identity

- Bundle ID: `com.frontierdesign.videostar`
- Version/build: `15.0.3` / `1847`
- Main executable: `Video Star`
- Architecture: ARM64
- Minimum iOS: 17.2
- SDK: iPhoneOS 26.0
- `cryptid = 0` in the supplied IPA (not FairPlay-encrypted)

## Objective-C method metadata

The exact encodings recovered from the app executable are recorded in `VIDEO_STAR_15_0_3_RUNTIME_API.md` and in `Sources/VideoStarToolLocal/Resources/VideoStar15_0_3_API.json`. These confirm ABI-level method signatures, not public API status, argument semantics, object ownership, thread constraints, or safe execution order.



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
| Last Code | App `QRCodeManager` has `readQRCode:`, `validQRCheck:`, `selectedCode:withImageData:`, `saveCodeToPlist:desc:`. | Local recent-code store implemented; not yet connected to the host QR callback. |
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
