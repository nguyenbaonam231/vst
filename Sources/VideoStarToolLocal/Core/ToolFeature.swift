import Foundation

public enum ToolFeature: String, CaseIterable, Codable {
    case replaceMedia
    case lastCode
    case beatSplit
    case multiSceneApply
    case mergeScenes

    public var displayTitle: String {
        switch self {
        case .replaceMedia: return "Nhập ảnh vào các lớp"
        case .lastCode: return "Mã đã dùng gần đây"
        case .beatSplit: return "Tách nhịp"
        case .multiSceneApply: return "Áp dụng nhiều phân cảnh"
        case .mergeScenes: return "Ghép phân cảnh"
        }
    }
}
