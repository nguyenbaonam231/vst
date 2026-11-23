import Foundation

public struct LocalPresetSummary: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let title: String
    public let createdAt: Date
    public let byteCount: Int

    public init(id: UUID, title: String, createdAt: Date, byteCount: Int) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.byteCount = byteCount
    }
}

public enum LocalPresetStoreError: LocalizedError, Equatable {
    case emptyTitle
    case emptyData
    case tooLarge
    case notFound
    case storageFailure(String)

    public var errorDescription: String? {
        switch self {
        case .emptyTitle: return "Tên preset không được để trống."
        case .emptyData: return "Dữ liệu preset đang trống."
        case .tooLarge: return "Preset vượt quá giới hạn lưu trữ 8 MB."
        case .notFound: return "Không tìm thấy preset trên thiết bị."
        case .storageFailure(let detail): return "Không thể lưu preset: \(detail)"
        }
    }
}

/// Lưu payload preset opaque tại chỗ. Store không diễn giải hoặc áp dụng
/// định dạng riêng của ứng dụng bên thứ ba.
public final class LocalPresetStore {
    private struct StoredPreset: Codable {
        let summary: LocalPresetSummary
        let payload: Data
    }

    private let directoryURL: URL
    private let fileManager: FileManager
    private let maximumPayloadBytes: Int

    public init(
        directoryURL: URL? = nil,
        maximumPayloadBytes: Int = 8 * 1024 * 1024,
        fileManager: FileManager = .default
    ) throws {
        self.fileManager = fileManager
        self.maximumPayloadBytes = max(1, maximumPayloadBytes)
        if let directoryURL {
            self.directoryURL = directoryURL.standardizedFileURL
        } else {
            let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? fileManager.temporaryDirectory
            self.directoryURL = base
                .appendingPathComponent("VideoStarToolLocal", isDirectory: true)
                .appendingPathComponent("Presets", isDirectory: true)
        }
        try fileManager.createDirectory(at: self.directoryURL, withIntermediateDirectories: true)
    }

    @discardableResult
    public func save(_ payload: Data, title: String) throws -> LocalPresetSummary {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { throw LocalPresetStoreError.emptyTitle }
        guard !payload.isEmpty else { throw LocalPresetStoreError.emptyData }
        guard payload.count <= maximumPayloadBytes else { throw LocalPresetStoreError.tooLarge }

        let summary = LocalPresetSummary(id: UUID(), title: cleanTitle, createdAt: Date(), byteCount: payload.count)
        let stored = StoredPreset(summary: summary, payload: payload)
        let destination = fileURL(for: summary.id)
        do {
            let data = try JSONEncoder().encode(stored)
            try data.write(to: destination, options: [.atomic, .completeFileProtectionUnlessOpen])
            return summary
        } catch {
            throw LocalPresetStoreError.storageFailure(error.localizedDescription)
        }
    }

    public func summaries() throws -> [LocalPresetSummary] {
        let urls = try fileManager.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ).filter { $0.pathExtension == "json" }

        return urls.compactMap { url in
            guard let data = try? Data(contentsOf: url),
                  let stored = try? JSONDecoder().decode(StoredPreset.self, from: data) else { return nil }
            return stored.summary
        }.sorted { $0.createdAt > $1.createdAt }
    }

    public func load(id: UUID) throws -> Data {
        let url = fileURL(for: id)
        guard fileManager.fileExists(atPath: url.path) else { throw LocalPresetStoreError.notFound }
        do {
            let stored = try JSONDecoder().decode(StoredPreset.self, from: Data(contentsOf: url))
            return stored.payload
        } catch {
            throw LocalPresetStoreError.storageFailure(error.localizedDescription)
        }
    }

    public func delete(id: UUID) throws {
        let url = fileURL(for: id)
        guard fileManager.fileExists(atPath: url.path) else { throw LocalPresetStoreError.notFound }
        do {
            try fileManager.removeItem(at: url)
        } catch {
            throw LocalPresetStoreError.storageFailure(error.localizedDescription)
        }
    }

    private func fileURL(for id: UUID) -> URL {
        directoryURL.appendingPathComponent("\(id.uuidString).json", isDirectory: false)
    }
}
