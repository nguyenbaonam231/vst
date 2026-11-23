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

    func testLocalMediaVaultCopiesImageAndVideoIntoSandbox() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let sourceRoot = root.appendingPathComponent("source", isDirectory: true)
        let vaultRoot = root.appendingPathComponent("vault", isDirectory: true)
        try FileManager.default.createDirectory(at: sourceRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let image = sourceRoot.appendingPathComponent("cover.JPG")
        let video = sourceRoot.appendingPathComponent("clip.MP4")
        try Data([0xFF, 0xD8, 0xFF]).write(to: image)
        try Data([0x00, 0x00, 0x00, 0x18]).write(to: video)

        let vault = try LocalMediaVault(directoryURL: vaultRoot)
        let items = try vault.importFiles([image, video])
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items.map(\.kind), [.image, .video])
        XCTAssertTrue(items.allSatisfy { FileManager.default.fileExists(atPath: vault.localURL(for: $0).path) })
        XCTAssertEqual(items.map(\.originalName), ["cover.JPG", "clip.MP4"])
    }

    func testLocalMediaVaultRollsBackBatchOnUnsupportedFile() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let sourceRoot = root.appendingPathComponent("source", isDirectory: true)
        let vaultRoot = root.appendingPathComponent("vault", isDirectory: true)
        try FileManager.default.createDirectory(at: sourceRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let image = sourceRoot.appendingPathComponent("ok.png")
        let unknown = sourceRoot.appendingPathComponent("bad.bin")
        try Data([1, 2, 3]).write(to: image)
        try Data([4, 5, 6]).write(to: unknown)

        let vault = try LocalMediaVault(directoryURL: vaultRoot)
        XCTAssertThrowsError(try vault.importFiles([image, unknown]))
        let remaining = try FileManager.default.contentsOfDirectory(atPath: vaultRoot.path)
        XCTAssertTrue(remaining.isEmpty)
    }

    func testLocalPresetStoreRoundTripsPayloadAndDeletes() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = try LocalPresetStore(directoryURL: root)
        let payload = Data("local-preset-payload".utf8)
        let summary = try store.save(payload, title: "  Preset hồng  ")

        XCTAssertEqual(summary.title, "Preset hồng")
        XCTAssertEqual(try store.load(id: summary.id), payload)
        XCTAssertEqual(try store.summaries().map(\.id), [summary.id])
        try store.delete(id: summary.id)
        XCTAssertTrue(try store.summaries().isEmpty)
        XCTAssertThrowsError(try store.load(id: summary.id))
    }

    func testLocalPresetStoreRejectsEmptyTitleAndPayload() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = try LocalPresetStore(directoryURL: root)
        XCTAssertThrowsError(try store.save(Data([1]), title: "   "))
        XCTAssertThrowsError(try store.save(Data(), title: "Preset"))
    }

    func testBeatMarkerExporterFiltersInvalidValuesAndExportsCSV() {
        let document = LocalBeatMarkerDocument(
            audioFileName: "song.m4a",
            sampleRate: 44_100,
            sensitivity: 1.6,
            markers: [2.1256, -1, .nan, 0.5]
        )
        XCTAssertEqual(document.markers, [0.5, 2.1256])
        let csv = String(data: LocalBeatMarkerExporter.csvData(for: document), encoding: .utf8)
        XCTAssertEqual(csv, "index,time_seconds\n1,0.500\n2,2.126\n")
    }

    func testLocalToolKitCoordinatesOfflineStoresAndBeatExport() throws {
        final class FixedBeatAnalyzer: LocalBeatAnalyzing {
            func analyze(audioURL: URL, sensitivity: Double, completion: @escaping (Result<[TimeInterval], Error>) -> Void) {
                completion(.success([0.25, 0.75, 1.25]))
            }
        }

        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let defaults = isolatedDefaults()
        defer { try? FileManager.default.removeItem(at: root) }
        let kit = try LocalToolKit(rootDirectoryURL: root, defaults: defaults, beatAnalyzer: FixedBeatAnalyzer())

        kit.rememberCode("QR-LOCAL-001")
        XCTAssertEqual(kit.recentCodeStore.latest()?.code, "QR-LOCAL-001")
        let preset = try kit.savePreset(Data("preset".utf8), title: "Preset local")
        XCTAssertEqual(try kit.presetStore.load(id: preset.id), Data("preset".utf8))

        let audio = root.appendingPathComponent("audio.m4a")
        let beatExpectation = expectation(description: "offline beat analysis")
        kit.analyzeBeats(in: audio) { result in
            XCTAssertEqual(try? result.get(), [0.25, 0.75, 1.25])
            beatExpectation.fulfill()
        }
        wait(for: [beatExpectation], timeout: 1)

        let csvURL = root.appendingPathComponent("markers.csv")
        try kit.exportBeatMarkers(
            audioFileName: "audio.m4a", sampleRate: 44_100, sensitivity: 1.6,
            markers: [0.25, 0.75, 1.25], format: .csv, to: csvURL
        )
        let csv = try String(contentsOf: csvURL, encoding: .utf8)
        XCTAssertTrue(csv.contains("2,0.750"))
    }

}
