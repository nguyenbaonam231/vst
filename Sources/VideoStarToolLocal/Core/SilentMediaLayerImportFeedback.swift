import Foundation

/// Thành công thì im lặng; chỉ chuyển lỗi cho giao diện gọi xử lý.
public final class SilentMediaLayerImportFeedback {
    public var onFailure: ((String) -> Void)?

    public init(onFailure: ((String) -> Void)? = nil) {
        self.onFailure = onFailure
    }

    public func finish(changedLayerCount: Int, error: Error?) {
        guard let error else {
            // Không hiện UIAlertController, toast hoặc thông báo thành công.
            return
        }
        onFailure?(error.localizedDescription)
    }
}
