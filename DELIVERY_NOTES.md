# Delivery Notes — VideoStarTool Local 1.1.0

This source release adds independent offline services:

- LocalMediaVault: copies user-selected image/video files into an app-owned sandbox and rolls back partial batches on failure.
- LocalPresetStore: stores opaque preset payloads locally without claiming compatibility with a third-party project schema.
- LocalBeatMarkerExporter: writes marker timestamps to JSON or CSV.
- LocalToolKit: facade combining local media, preset, recent-code, beat analysis, and marker export APIs.
- CI workflow runs unit tests and builds an unsigned iOS ARM64 dynamic library on GitHub's Xcode 27 runner.

Tests: `swift test -c release` — 13 passed, 0 failed on Linux x86_64.

Not included: private Video Star method invocation, purchase/subscription manipulation, key/server circumvention, or an editor bridge implementation. Those require an authorized host integration API and cannot be inferred safely from selector names alone.
