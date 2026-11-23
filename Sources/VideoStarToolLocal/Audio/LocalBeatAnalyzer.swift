import Foundation

public protocol LocalBeatAnalyzing {
    func analyze(
        audioURL: URL,
        sensitivity: Double,
        completion: @escaping (Result<[TimeInterval], Error>) -> Void
    )
}

public enum LocalBeatAnalyzerError: LocalizedError {
    case unsupportedPlatform
    case noAudioTrack
    case invalidAudioFormat

    public var errorDescription: String? {
        switch self {
        case .unsupportedPlatform: return "Bộ phân tích âm thanh chỉ hỗ trợ iOS/macOS."
        case .noAudioTrack: return "Không đọc được dữ liệu âm thanh từ tệp đã chọn."
        case .invalidAudioFormat: return "Định dạng âm thanh không được hỗ trợ."
        }
    }
}

#if canImport(AVFoundation)
import AVFoundation

/// Phân tích biên độ âm thanh hoàn toàn trên thiết bị để ước lượng các điểm nhịp.
/// Đây là engine mới độc lập, không phải bản sao thuật toán Beat Split gốc.
public final class LocalBeatAnalyzer: LocalBeatAnalyzing {
    public init() {}

    public func analyze(
        audioURL: URL,
        sensitivity: Double = 1.6,
        completion: @escaping (Result<[TimeInterval], Error>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let times = try Self.detect(audioURL: audioURL, sensitivity: sensitivity)
                DispatchQueue.main.async { completion(.success(times)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }

    private static func detect(audioURL: URL, sensitivity: Double) throws -> [TimeInterval] {
        let file = try AVAudioFile(forReading: audioURL, commonFormat: .pcmFormatFloat32, interleaved: false)
        let format = file.processingFormat
        guard format.sampleRate > 0, format.channelCount > 0 else {
            throw LocalBeatAnalyzerError.invalidAudioFormat
        }

        let samplesPerWindow = max(1, Int(format.sampleRate * 0.05)) // cửa sổ 50 ms
        let chunkCapacity: AVAudioFrameCount = 8192
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: chunkCapacity),
              let channelData = buffer.floatChannelData else {
            throw LocalBeatAnalyzerError.invalidAudioFormat
        }

        var energies: [Double] = []
        var squareSum = 0.0
        var samplesInWindow = 0
        var remaining = file.length

        while remaining > 0 {
            let count = AVAudioFrameCount(min(Int64(chunkCapacity), remaining))
            try file.read(into: buffer, frameCount: count)
            let frameCount = Int(buffer.frameLength)
            if frameCount == 0 { break }

            for frame in 0..<frameCount {
                var samplePower = 0.0
                for channel in 0..<Int(format.channelCount) {
                    let sample = Double(channelData[channel][frame])
                    samplePower += sample * sample
                }
                squareSum += samplePower / Double(format.channelCount)
                samplesInWindow += 1

                if samplesInWindow >= samplesPerWindow {
                    energies.append(sqrt(squareSum / Double(samplesInWindow)))
                    squareSum = 0
                    samplesInWindow = 0
                }
            }
            remaining -= Int64(frameCount)
        }

        if samplesInWindow > 0 {
            energies.append(sqrt(squareSum / Double(samplesInWindow)))
        }
        guard energies.count >= 5 else { throw LocalBeatAnalyzerError.noAudioTrack }

        let windowSeconds = Double(samplesPerWindow) / format.sampleRate
        let strengths = energies.indices.map { index -> Double in
            guard index > 0 else { return 0 }
            return max(0, energies[index] - energies[index - 1])
        }
        let historyWindow = max(8, Int(1.5 / windowSeconds))
        let thresholdScale = min(max(sensitivity, 1.05), 4.0)
        var beats: [TimeInterval] = []
        var lastBeat = -Double.infinity

        if strengths.count > 2 {
            for index in 2..<(strengths.count - 1) {
                let start = max(0, index - historyWindow)
                let history = strengths[start..<index]
                let baseline = history.reduce(0, +) / Double(max(1, history.count))
                let value = strengths[index]
                let isLocalPeak = value >= strengths[index - 1] && value > strengths[index + 1]
                let time = Double(index) * windowSeconds
                if isLocalPeak && value > max(0.0005, baseline * thresholdScale) && time - lastBeat >= 0.25 {
                    beats.append(time)
                    lastBeat = time
                }
            }
        }
        return beats
    }
}
#else
/// Stub để package vẫn kiểm tra cấu trúc trên nền tảng không có AVFoundation.
public final class LocalBeatAnalyzer: LocalBeatAnalyzing {
    public init() {}
    public func analyze(
        audioURL: URL,
        sensitivity: Double = 1.6,
        completion: @escaping (Result<[TimeInterval], Error>) -> Void
    ) {
        completion(.failure(LocalBeatAnalyzerError.unsupportedPlatform))
    }
}
#endif
