import Foundation

/// Lưu mã gần đây hoàn toàn trên thiết bị. Không gửi dữ liệu qua mạng.
public final class RecentCodeStore {
    public struct Entry: Codable, Equatable {
        public let code: String
        public let savedAt: Date

        public init(code: String, savedAt: Date = Date()) {
            self.code = code
            self.savedAt = savedAt
        }
    }

    private let defaults: UserDefaults
    private let storageKey: String
    private let maximumEntries: Int

    public init(
        defaults: UserDefaults = .standard,
        storageKey: String = "com.j4avzckcy.videostartool.recent-codes",
        maximumEntries: Int = 30
    ) {
        self.defaults = defaults
        self.storageKey = storageKey
        self.maximumEntries = max(1, maximumEntries)
    }

    public func record(_ code: String) {
        let cleaned = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }

        var entries = allEntries().filter { $0.code != cleaned }
        entries.insert(Entry(code: cleaned), at: 0)
        save(Array(entries.prefix(maximumEntries)))
    }

    public func latest() -> Entry? {
        allEntries().first
    }

    public func entries() -> [Entry] {
        allEntries()
    }

    public func removeAll() {
        defaults.removeObject(forKey: storageKey)
    }

    private func allEntries() -> [Entry] {
        guard let data = defaults.data(forKey: storageKey),
              let entries = try? JSONDecoder().decode([Entry].self, from: data) else {
            return []
        }
        return entries
    }

    private func save(_ entries: [Entry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
