import Foundation

public enum LocalMediaKind: String, Codable, Sendable {
    case image
    case video
}

public struct LocalMediaItem: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let originalName: String
    public let storedFileName: String
    public let kind: LocalMediaKind
    public let byteCount: Int64
    public let importedAt: Date

    public init(
        id: UUID = UUID(),
        originalName: String,
        storedFileName: String,
        kind: LocalMediaKind,
        byteCount: Int64,
        importedAt: Date = Date()
    ) {
        self.id = id
        self.originalName = originalName
        self.storedFileName = storedFileName
        self.kind = kind
        self.byteCount = byteCount
        self.importedAt = importedAt
    }
}

public enum LocalMediaVaultError: LocalizedError, Equatable {
    case unsupportedFileType(String)
    case sourceMissing(String)
    case emptyBatch
    case importFailed(String)

    public var errorDescription: String? {
        switch self {
        case .unsupportedFileType(let ext):
            return "Định dạng tệp không được hỗ trợ: .\(ext)"
        case .sourceMissing(let name):
            return "Không tìm thấy tệp nguồn: \(name)"
        case .emptyBatch:
            return "Chưa chọn tệp ảnh hoặc video nào."
        case .importFailed(let reason):
            return "Không thể lưu media vào thiết bị: \(reason)"
        }
    }
}

/// Kho media riêng trên thiết bị. Chỉ sao chép tệp do người dùng chọn;
/// không tải lên mạng và không chỉnh sửa project của ứng dụng chủ.
public final class LocalMediaVault {
    private let fileManager: FileManager
    public let directoryURL: URL

    private static let imageExtensions: Set<String> = ["jpg", "jpeg", "png", "heic", "heif", "webp", "gif", "tif", "tiff"]
    private static let videoExtensions: Set<String> = ["mov", "mp4", "m4v"]

    public init(directoryURL: URL? = nil, fileManager: FileManager = .default) throws {
        self.fileManager = fileManager
        if let directoryURL {
            self.directoryURL = directoryURL.standardizedFileURL
        } else {
            let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? fileManager.temporaryDirectory
            self.directoryURL = base
                .appendingPathComponent("VideoStarToolLocal", isDirectory: true)
                .appendingPathComponent("Media", isDirectory: true)
        }
        try fileManager.createDirectory(at: self.directoryURL, withIntermediateDirectories: true)
    }

    /// Nhập theo batch có tính nguyên tử: nếu một tệp lỗi, các tệp đã sao chép
    /// trong batch đó sẽ được dọn lại để không để lại trạng thái nửa chừng.
    public func importFiles(_ sourceURLs: [URL]) throws -> [LocalMediaItem] {
        guard !sourceURLs.isEmpty else { throw LocalMediaVaultError.emptyBatch }

        var imported: [LocalMediaItem] = []
        var copiedURLs: [URL] = []
        do {
            for sourceURL in sourceURLs {
                let source = sourceURL.standardizedFileURL
                guard fileManager.fileExists(atPath: source.path) else {
                    throw LocalMediaVaultError.sourceMissing(source.lastPathComponent)
                }

                let ext = source.pathExtension.lowercased()
                let kind: LocalMediaKind
                if Self.imageExtensions.contains(ext) {
                    kind = .image
                } else if Self.videoExtensions.contains(ext) {
                    kind = .video
                } else {
                    throw LocalMediaVaultError.unsupportedFileType(ext)
                }

                #if os(iOS) || os(macOS)
                let didStartAccess = source.startAccessingSecurityScopedResource()
                defer {
                    if didStartAccess { source.stopAccessingSecurityScopedResource() }
                }
                #endif

                let id = UUID()
                let filename = "\(id.uuidString).\(ext)"
                let destination = directoryURL.appendingPathComponent(filename, isDirectory: false)
                try fileManager.copyItem(at: source, to: destination)
                copiedURLs.append(destination)

                let attributes = try fileManager.attributesOfItem(atPath: destination.path)
                let byteCount = (attributes[.size] as? NSNumber)?.int64Value ?? 0
                imported.append(LocalMediaItem(
                    id: id,
                    originalName: source.lastPathComponent,
                    storedFileName: filename,
                    kind: kind,
                    byteCount: byteCount
                ))
            }
            return imported
        } catch let error as LocalMediaVaultError {
            copiedURLs.forEach { try? fileManager.removeItem(at: $0) }
            throw error
        } catch {
            copiedURLs.forEach { try? fileManager.removeItem(at: $0) }
            throw LocalMediaVaultError.importFailed(error.localizedDescription)
        }
    }

    public func localURL(for item: LocalMediaItem) -> URL {
        directoryURL.appendingPathComponent(item.storedFileName, isDirectory: false)
    }

    public func remove(_ item: LocalMediaItem) throws {
        let target = localURL(for: item).standardizedFileURL
        guard target.deletingLastPathComponent() == directoryURL else {
            throw LocalMediaVaultError.importFailed("Đường dẫn media không hợp lệ.")
        }
        if fileManager.fileExists(atPath: target.path) {
            try fileManager.removeItem(at: target)
        }
    }
}
