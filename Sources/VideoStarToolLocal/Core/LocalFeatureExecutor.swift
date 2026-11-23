import Foundation

public enum LocalFeatureCommand {
    case replaceMedia(layerIDs: [Int], mediaURLs: [URL])
    case beatSplit(sceneID: Int, audioURL: URL, sensitivity: Double)
    case multiSceneApply(sceneIDs: [Int], presetData: Data)
    case mergeScenes(sceneIDs: [Int])
}

/// Điều phối yêu cầu xử lý local tới adapter của editor.
/// Không thực hiện request mạng và không giả mạo trạng thái thành công.
public final class LocalFeatureExecutor {
    private let bridge: VideoStarEditorBridge?
    private let feedback: SilentMediaLayerImportFeedback
    private let beatAnalyzer: LocalBeatAnalyzing

    public init(
        bridge: VideoStarEditorBridge?,
        feedback: SilentMediaLayerImportFeedback = SilentMediaLayerImportFeedback(),
        beatAnalyzer: LocalBeatAnalyzing = LocalBeatAnalyzer()
    ) {
        self.bridge = bridge
        self.feedback = feedback
        self.beatAnalyzer = beatAnalyzer
    }

    public func execute(
        _ command: LocalFeatureCommand,
        completion: @escaping (Result<Int, Error>) -> Void
    ) {
        guard let bridge else {
            let error = EditorBridgeError.notInstalled
            feedback.finish(changedLayerCount: 0, error: error)
            completion(.failure(error))
            return
        }

        let finish: (Result<Int, Error>) -> Void = { [feedback] result in
            switch result {
            case .success(let changedCount):
                feedback.finish(changedLayerCount: changedCount, error: nil)
            case .failure(let error):
                feedback.finish(changedLayerCount: 0, error: error)
            }
            completion(result)
        }

        switch command {
        case .replaceMedia(let layerIDs, let mediaURLs):
            guard !layerIDs.isEmpty, !mediaURLs.isEmpty else {
                finish(.failure(EditorBridgeError.invalidRequest("Cần chọn ít nhất một lớp và một tệp ảnh/video.")))
                return
            }
            bridge.replaceMedia(layerIDs: layerIDs, with: mediaURLs, completion: finish)

        case .beatSplit(let sceneID, let audioURL, let sensitivity):
            beatAnalyzer.analyze(audioURL: audioURL, sensitivity: sensitivity) { result in
                switch result {
                case .success(let times):
                    guard !times.isEmpty else {
                        finish(.failure(EditorBridgeError.invalidRequest("Không phát hiện được nhịp rõ ràng trong âm thanh.")))
                        return
                    }
                    bridge.applyBeatMarkers(times, toSceneID: sceneID, completion: finish)
                case .failure(let error):
                    finish(.failure(error))
                }
            }

        case .multiSceneApply(let sceneIDs, let presetData):
            guard !sceneIDs.isEmpty, !presetData.isEmpty else {
                finish(.failure(EditorBridgeError.invalidRequest("Cần chọn phân cảnh và preset hợp lệ.")))
                return
            }
            bridge.applyPreset(presetData, toSceneIDs: sceneIDs, completion: finish)

        case .mergeScenes(let sceneIDs):
            guard sceneIDs.count >= 2 else {
                finish(.failure(EditorBridgeError.invalidRequest("Cần chọn ít nhất hai phân cảnh để ghép.")))
                return
            }
            bridge.mergeScenes(sceneIDs, completion: finish)
        }
    }
}
