import Foundation

/// Facade cho các chức năng hoàn toàn local của thư viện.
/// Không gọi mạng, không thay đổi quyền mua/subscription và không gọi private API của host.
public final class LocalToolKit {
    public enum BeatExportFormat {
        case json
        case csv
    }

    public let mediaVault: LocalMediaVault
    public let presetStore: LocalPresetStore
    public let recentCodeStore: RecentCodeStore
    private let beatAnalyzer: LocalBeatAnalyzing

    public init(
        rootDirectoryURL: URL,
        defaults: UserDefaults = .standard,
        beatAnalyzer: LocalBeatAnalyzing = LocalBeatAnalyzer()
    ) throws {
        let root = rootDirectoryURL.standardizedFileURL
        self.mediaVault = try LocalMediaVault(
            directoryURL: root.appendingPathComponent("Media", isDirectory: true)
        )
        self.presetStore = try LocalPresetStore(
            directoryURL: root.appendingPathComponent("Presets", isDirectory: true)
        )
        self.recentCodeStore = RecentCodeStore(
            defaults: defaults,
            storageKey: "com.j4avzckcy.videostartool.recent-codes"
        )
        self.beatAnalyzer = beatAnalyzer
    }

    @discardableResult
    public func importMedia(_ urls: [URL]) throws -> [LocalMediaItem] {
        try mediaVault.importFiles(urls)
    }

    public func rememberCode(_ code: String) {
        recentCodeStore.record(code)
    }

    @discardableResult
    public func savePreset(_ data: Data, title: String) throws -> LocalPresetSummary {
        try presetStore.save(data, title: title)
    }

    /// Phân tích nhịp ngoại tuyến mà không yêu cầu editor bridge.
    public func analyzeBeats(
        in audioURL: URL,
        sensitivity: Double = 1.6,
        completion: @escaping (Result<[TimeInterval], Error>) -> Void
    ) {
        beatAnalyzer.analyze(audioURL: audioURL, sensitivity: sensitivity, completion: completion)
    }

    public func exportBeatMarkers(
        audioFileName: String,
        sampleRate: Double,
        sensitivity: Double,
        markers: [TimeInterval],
        format: BeatExportFormat,
        to destinationURL: URL
    ) throws {
        let document = LocalBeatMarkerDocument(
            audioFileName: audioFileName,
            sampleRate: sampleRate,
            sensitivity: sensitivity,
            markers: markers
        )
        switch format {
        case .json:
            try LocalBeatMarkerExporter.writeJSON(document, to: destinationURL)
        case .csv:
            try LocalBeatMarkerExporter.writeCSV(document, to: destinationURL)
        }
    }
}
