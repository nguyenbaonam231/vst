import Foundation

public protocol FeatureAccessProviding {
    func isEnabled(_ feature: ToolFeature) -> Bool
}

/// Cài đặt hiển thị cục bộ, KHÔNG phải hệ thống cấp phép và không mở khóa
/// hoặc giả mạo quyền truy cập trong binary khác.
public final class LocalFeatureAccess: FeatureAccessProviding {
    private let defaults: UserDefaults
    private let keyPrefix = "com.j4avzckcy.videostartool.feature."

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func isEnabled(_ feature: ToolFeature) -> Bool {
        let key = keyPrefix + feature.rawValue
        guard defaults.object(forKey: key) != nil else { return true }
        return defaults.bool(forKey: key)
    }

    public func setEnabled(_ enabled: Bool, for feature: ToolFeature) {
        defaults.set(enabled, forKey: keyPrefix + feature.rawValue)
    }

    public func resetPreferences() {
        ToolFeature.allCases.forEach {
            defaults.removeObject(forKey: keyPrefix + $0.rawValue)
        }
    }
}
