# Build `VideoStarTool.dylib` with GitHub Actions

This project now includes `.github/workflows/build-ios-dylib.yml`.
It uses GitHub's `xcode-27` macOS runner and the iPhoneOS SDK bundled with Xcode.
This route does not require installing xtool or downloading Xcode.xip into the Linux workspace.

## Run it

1. Create a **private** GitHub repository for this source if it is not already in one.
2. Upload/push the contents of this project folder to the repository root. Keep the `.github/workflows/` directory; it contains the workflow.
3. Open the repository's **Actions** tab.
4. Select **Build VideoStarTool iOS dylib** and choose **Run workflow**.
5. When the job finishes successfully, open the run and download the artifact named `VideoStarTool-dylib-arm64-ios`.

The workflow runs source audit + Swift tests, cross-compiles the SwiftPM dynamic-library product for `arm64-apple-ios17.2`, checks that the output is Mach-O ARM64, and uploads it as an artifact.

## What the artifact means

- It is an **unsigned iOS ARM64 dynamic library** compiled from this rebuild's current source.
- It is not a patch of the original `VideoStarTool(1).dylib`.
- It does not bypass or modify Video Star purchase/subscription checks or the original tool's server authorization.
- It does not yet provide the missing, validated Video Star editor adapter. In particular, Replace Media, Multi Scene Apply, Merge Scenes, Last Code host callback, and Beat Split timeline integration are not feature-complete.
- A successful compile does not prove that the library can be loaded into Video Star. Loading, signing, and runtime integration require an authorized development/injection environment and device testing.

Do not put Apple ID passwords, 2FA codes, signing certificates, or private keys in the repository or workflow logs. This workflow does not need those secrets because it does not sign the binary.
