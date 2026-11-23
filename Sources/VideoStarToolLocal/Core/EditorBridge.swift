import Foundation

/// Các yêu cầu chỉnh sửa mà một adapter hợp lệ của ứng dụng chủ cần triển khai.
/// Những API editor thực tế không có trong file dylib được cung cấp dưới dạng
/// headers/source, vì vậy không cài đặt giả một adapter không hoạt động.
public protocol VideoStarEditorBridge: AnyObject {
    func replaceMedia(
        layerIDs: [Int],
        with mediaURLs: [URL],
        completion: @escaping (Result<Int, Error>) -> Void
    )

    func applyBeatMarkers(
        _ beatTimes: [TimeInterval],
        toSceneID sceneID: Int,
        completion: @escaping (Result<Int, Error>) -> Void
    )

    func applyPreset(
        _ presetData: Data,
        toSceneIDs sceneIDs: [Int],
        completion: @escaping (Result<Int, Error>) -> Void
    )

    func mergeScenes(
        _ sceneIDs: [Int],
        completion: @escaping (Result<Int, Error>) -> Void
    )
}

public enum EditorBridgeError: LocalizedError {
    case notInstalled
    case invalidRequest(String)

    public var errorDescription: String? {
        switch self {
        case .notInstalled:
            return "Chưa kết nối bộ điều khiển Video Star. Cần adapter tương thích với phiên bản ứng dụng đang dùng."
        case .invalidRequest(let message):
            return message
        }
    }
}
