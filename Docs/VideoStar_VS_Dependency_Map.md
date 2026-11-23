# Video Star / Tool dependency map (static analysis)

## Scope and evidence

This report is based on the uploaded split ZIP reconstructed as one IPA, the Video Star 15.0.3 build 1847 main executable, the bundled `VSPlusUltra.dylib`, `VSFix1.dylib` through `VSFix4.dylib`, and the uploaded `VideoStarTool(1).dylib`.

The observations below are static evidence (Mach-O load commands and printable Objective-C / symbol strings). They do not prove that an undocumented method can be called safely at runtime or reveal all method argument semantics.

## User's integration note

The user states that `VSPlusUltra` and the `VSFix` modules are part of the tool base and should not be removed from the compatibility target. Accordingly, this map treats them as existing runtime components to account for, not as files to strip out of the app.

## `VSPlusUltra.dylib`

Observed install name:

`/Library/MobileSubstrate/DynamicLibraries/VSPlusUltra.dylib`

Observed dependency:

`@rpath/CydiaSubstrate.framework/CydiaSubstrate`

Other linked frameworks/libraries include Objective-C runtime, Foundation, CoreFoundation, libc++, libSystem, CoreGraphics, QuartzCore, and UIKit.

### Hook groups observed

**QR / code workflow hooks**

- `QRCodeManager selectedCode:withImageData:`
- `QRCodeManager startQRImport`
- `QRCodeManager saveCodeToPlist:desc:`
- `QRCodeManager setQRCodeUsed:`
- `QRCodeManager validQRCheck:`
- `QRCodeManager exists:`
- `QRCodeManager makeQRImageForCode:text:icon:`

These overlap with selectors in the uploaded tool (`startQRImport`, `validQRCheck:`, `selectedCode:withImageData:`), so this is a concrete compatibility point for QR-related workflows.

**Editor / UI hooks observed**

- `MultiLayerWizEffectVC viewDidAppear:`
- `RootViewController showDefaultLovePage`
- `RootViewController vsPLus:`
- `RootViewController viewDidAppear:`
- `RootViewController showAlertWithMessage:`
- `RootViewController viewDidLayoutSubviews`

The hook names indicate that the module also changes editor/UI behavior, not just exposes a normal library API.

**Store / entitlement hooks observed**

- `StoreModel boughtProduct:`
- `StoreModel purchasedCount`
- `StoreModel numberOfPacksOwned`
- `StoreModel numberOfTheseProductsOwned:`
- `StoreModel buyProduct:inPlace:`
- `StoreModel subscriptionActive`
- `StoreModel expirationDateForSubscriptionID:`
- `StoreModel ownedProducts`
- `StoreModel autoRenewON`

The dylib contains Logos-generated `logos_method` / `logos_orig` symbols for these hooks. This is strong evidence that it intercepts StoreModel purchase/subscription methods. This analysis does not modify or reproduce those entitlement hooks.

## `VSFix1.dylib` ... `VSFix4.dylib`

Observed install names and notable load relationships:

| Bundled file | Install name | Observed notable dependency / evidence |
|---|---|---|
| `VSFix1.dylib` | `@rpath/ipacrack_ioscodevn.dylib` | Loads `@executable_path/Frameworks/VSFix4.dylib`; has strings including `BZRSubscriptionState` and `setRootViewController:` |
| `VSFix2.dylib` | `@rpath/LeTi.dylib` | Upward-loads `@executable_path/Frameworks/VSFix4.dylib` |
| `VSFix3.dylib` | `/Library/MobileSubstrate/DynamicLibraries/FireStore.dylib` | Loads `@executable_path/Frameworks/VSFix4.dylib` and SpringBoardServices, UIKit, CoreImage, Accelerate, AudioToolbox |
| `VSFix4.dylib` | `@executable_path/Frameworks/libsubstrate.dylib` | Substrate-like loader dependency; links Objective-C runtime, libgcc, libstdc++, libSystem |

The bundled filenames and Mach-O install names are not the same in every case. Do not rename or repack these binaries as if they were interchangeable libraries.

## Original tool overlap

The original tool contains these matching strings:

- `getMultiLayerEngine`
- `showMultiLayer`
- `showMergeScenes`
- `makePhotoLayer:`
- `makeVideoLayer:frameTimes:volume:`
- `startQRImport`
- `validQRCheck:`
- `selectedCode:withImageData:`
- `rootViewController`
- `setRootViewController:`

This supports treating the uploaded Video Star build and its bundled tweak layer as a compatibility environment for further investigation. It does not establish a stable public API or exact ABI signatures.

## Integration guidance

1. Preserve and account for the existing runtime environment when testing tool compatibility; do not silently remove `VSPlusUltra` or `VSFix` from the test target.
2. Build feature adapters against observed editor/QR hooks only after the actual method type encodings, owning classes, and runtime behavior have been confirmed on an authorized test device.
3. Keep the tool's own `VSKeyAuth` separate from Video Star's StoreModel / StoreKit entitlement layer. They are different systems.
4. A local replacement can remove the tool's own remote key-server dependency from newly written code, but it does not make Video Star itself fully offline.
5. Do not patch StoreModel purchase/subscription results or falsify entitlements. The adapter should respect the host app's real entitlement state.
6. Do not copy/re-distribute the extracted third-party dylibs in the new package unless you have rights to redistribute them. Treat already-installed components as runtime dependencies where appropriate.

## Current limitation

The current materials do not include vendor headers, source code, or a clean documented plugin SDK. The next implementation step is to determine Objective-C type encodings and runtime ownership for the allowed feature selectors, then develop and test an adapter on-device. Static strings alone are insufficient to produce a reliable replacement `.dylib`.


## ABI signatures recovered in the Video Star 15.0.3 executable

The rebuild now contains a read-only runtime inspector for the verified non-entitlement editor/QR methods. Selected signatures include:

| Class | Selector | Type encoding |
|---|---|---|
| `MultiLayerEngine` | `layerAtLayerNum:` | `@24@0:8Q16` |
| `MultiLayerEngine` | `setupImage:layerNum:layerType:clearMask:` | `@40@0:8@16Q24i32B36` |
| `MultiLayerWizEffectVC` | `getMultiLayerEngine` | `@16@0:8` |
| `MultiLayerWizEffectVC` | `makePhotoLayer:` | `v24@0:8@16` |
| `MultiLayerWizEffectVC` | `makeVideoLayer:frameTimes:volume:` | `v40@0:8@16@24@32` |
| `QRCodeManager` | `validQRCheck:` | `B24@0:8@16` |
| `QRCodeManager` | `selectedCode:withImageData:` | `v32@0:8@16@24` |

These encodings are used only for a runtime compatibility diagnostic. They do not implement Replace Media, Multi Scene Apply, Merge Scenes, or host QR callbacks.

## Rebuild compatibility policy

- `VSPlusUltra`, `VSFix1`–`VSFix4`, and CydiaSubstrate remain in the runtime dependency manifest, as requested for the supplied target environment.
- The project checks for their loaded image names only. It does not bundle, copy, modify, or redistribute them.
- StoreModel purchase/subscription hooks are not used, modified, or recreated.
- The original tool's `VSKeyAuth` and `api.shopmduyk.site` endpoint are not part of the new source project. The original binary itself remains unchanged.
