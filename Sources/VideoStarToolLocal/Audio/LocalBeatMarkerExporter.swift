import Foundation

public struct LocalBeatMarkerDocument: Codable, Equatable, Sendable {
    public let audioFileName: String
    public let sampleRate: Double
    public let sensitivity: Double
    public let markers: [TimeInterval]
    public let generatedAt: Date

    public init(
        audioFileName: String,
        sampleRate: Double,
        sensitivity: Double,
        markers: [TimeInterval],
        generatedAt: Date = Date()
    ) {
        self.audioFileName = audioFileName
        self.sampleRate = sampleRate
        self.sensitivity = sensitivity
        self.markers = markers.filter { $0.isFinite && $0 >= 0 }.sorted()
        self.generatedAt = generatedAt
    }
}

public enum LocalBeatMarkerExporter {
    public static func jsonData(for document: LocalBeatMarkerDocument) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(document)
    }

    public static func csvData(for document: LocalBeatMarkerDocument) -> Data {
        var lines = ["index,time_seconds"]
        lines.append(contentsOf: document.markers.enumerated().map { index, time in
            "\(index + 1),\(String(format: "%.3f", locale: Locale(identifier: "en_US_POSIX"), time))"
        })
        return lines.joined(separator: "\n").appending("\n").data(using: .utf8) ?? Data()
    }

    public static func writeJSON(_ document: LocalBeatMarkerDocument, to url: URL) throws {
        try jsonData(for: document).write(to: url, options: .atomic)
    }

    public static func writeCSV(_ document: LocalBeatMarkerDocument, to url: URL) throws {
        try csvData(for: document).write(to: url, options: .atomic)
    }
}
