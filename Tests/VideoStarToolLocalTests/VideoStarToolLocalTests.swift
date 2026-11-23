import XCTest
@testable import VideoStarToolLocal

final class VideoStarToolLocalTests: XCTestCase {
    private final class MockBridge: VideoStarEditorBridge {
        func replaceMedia(layerIDs: [Int], with mediaURLs: [URL], completion: @escaping (Result<Int, Error>) -> Void) {
            completion(.success(layerIDs.count))
        }
        func applyBeatMarkers(_ beatTimes: [TimeInterval], toSceneID sceneID: Int, completion: @escaping (Result<Int, Error>) -> Void) {
            completion(.success(beatTimes.count))
        }
        func applyPreset(_ presetData: Data, toSceneIDs sceneIDs: [Int], completion: @escaping (Result<Int, Error>) -> Void) {
            completion(.success(sceneIDs.count))
        }
        func mergeScenes(_ sceneIDs: [Int], completion: @escaping (Result<Int, Error>) -> Void) {
            completion(.success(sceneIDs.count - 1))
        }
    }

    private func isolatedDefaults() -> UserDefaults {
        let name = "VideoStarToolLocalTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    func testFeaturePreferencesAreLocalAndResettable() {
        let defaults = isolatedDefaults()
        let access = LocalFeatureAccess(defaults: defaults)
        XCTAssertTrue(access.isEnabled(.replaceMedia))
        access.setEnabled(false, for: .replaceMedia)
        XCTAssertFalse(access.isEnabled(.replaceMedia))
        access.resetPreferences()
        XCTAssertTrue(access.isEnabled(.replaceMedia))
    }

    func testRecentCodeStoreDeduplicatesAndLimitsEntries() {
        let defaults = isolatedDefaults()
        let store = RecentCodeStore(defaults: defaults, storageKey: "codes", maximumEntries: 2)
        store.record("  alpha  ")
        store.record("beta")
        store.record("alpha")
        store.record("gamma")
        XCTAssertEqual(store.entries().map(\.code), ["gamma", "alpha"])
        XCTAssertEqual(store.latest()?.code, "gamma")
    }

    func testSilentFeedbackDoesNotEmitSuccessButEmitsFailure() {
        final class TestFailure: Error {}
        var received: [String] = []
        let feedback = SilentMediaLayerImportFeedback { received.append($0) }
        feedback.finish(changedLayerCount: 4, error: nil)
        XCTAssertTrue(received.isEmpty)
        feedback.finish(changedLayerCount: 0, error: TestFailure())
        XCTAssertEqual(received.count, 1)
    }

    func testFeatureExecutorUsesLocalBridgeAndKeepsSuccessSilent() {
        let feedback = SilentMediaLayerImportFeedback()
        let executor = LocalFeatureExecutor(bridge: MockBridge(), feedback: feedback)
        let expectation = expectation(description: "replace media completes")
        executor.execute(.replaceMedia(layerIDs: [1, 2], mediaURLs: [URL(fileURLWithPath: "/tmp/a.jpg")])) { result in
            XCTAssertEqual(try? result.get(), 2)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }

    func testFeatureExecutorDoesNotReportSuccessWithoutEditorBridge() {
        var errors: [String] = []
        let feedback = SilentMediaLayerImportFeedback { errors.append($0) }
        let executor = LocalFeatureExecutor(bridge: nil, feedback: feedback)
        let expectation = expectation(description: "missing bridge returns failure")
        executor.execute(.mergeScenes(sceneIDs: [1, 2])) { result in
            guard case .failure = result else { return XCTFail("Expected missing-bridge failure") }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(errors.count, 1)
    }
    func testVideoStarRuntimeManifestHasUniqueSelectorsAndExpectedHost() {
        XCTAssertEqual(VideoStarRuntimeInspector.targetBundleIdentifier, "com.frontierdesign.videostar")
        XCTAssertEqual(VideoStarRuntimeInspector.targetVersion, "15.0.3")
        XCTAssertEqual(VideoStarRuntimeInspector.targetBuild, "1847")
        let keys = VideoStarRuntimeInspector.methodRequirements.map { "\($0.className)::\($0.selector)" }
        XCTAssertEqual(Set(keys).count, keys.count, "Runtime method manifest must not contain duplicates")
        XCTAssertTrue(keys.contains("MultiLayerEngine::layerAtLayerNum:"))
        XCTAssertTrue(keys.contains("MultiLayerWizEffectVC::makePhotoLayer:"))
        XCTAssertTrue(keys.contains("QRCodeManager::validQRCheck:"))
    }

    func testRuntimeImageManifestRetainsSubmittedBaseDependencies() {
        let names = Set(VideoStarRuntimeInspector.imageRequirements.map(\.name))
        XCTAssertTrue(names.contains("VSPlusUltra"))
        XCTAssertTrue(names.contains("VSFix1"))
        XCTAssertTrue(names.contains("VSFix2"))
        XCTAssertTrue(names.contains("VSFix3"))
        XCTAssertTrue(names.contains("VSFix4"))
        XCTAssertTrue(names.contains("CydiaSubstrate"))
    }

}
