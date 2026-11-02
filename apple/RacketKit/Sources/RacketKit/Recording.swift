import Foundation
import simd

/// Recorder input preserves whether samples arrived as a continuous stream or
/// as a window whose pose was tracked by the racket during unrecorded motion.
public enum RecordingEvent: Sendable {
    case samples([IMUSample])
    case impact(window: ImpactWindow, calibration: Calibration, profile: RacketProfile, model: ImpactModel, calibrationMode: Bool = false)
}

/// One JSON line next to the binary recording. Samples stay in the existing
/// format; this supplies the state required to replay an impact window exactly.
public struct RecordedImpactContext: Codable, Sendable {
    public var formatVersion = 1
    public var sampleOffset: Int
    public var sampleCount: Int
    public var impactIndex: Int
    public var seq: UInt16
    public var boot: UInt16?
    public var backlog: Bool
    /// Quaternion in x,y,z,w order, sensor to world at the first recorded sample.
    public var startOrientationXYZW: [Float]
    public var calibration: Calibration
    public var profile: RacketProfile
    /// RacketProfile deliberately omits this player-owned field when saving
    /// settings, so a recording must snapshot it explicitly for exact replay.
    public var forehandBodySign: Float
    public var model: ImpactModel
    public var calibrationMode: Bool

    init(window: ImpactWindow, sampleOffset: Int, calibration: Calibration,
         profile: RacketProfile, model: ImpactModel, calibrationMode: Bool = false) {
        self.sampleOffset = sampleOffset
        sampleCount = window.samples.count
        impactIndex = window.impactIndex
        seq = window.seq
        boot = window.boot
        backlog = window.backlog
        let q = window.startOrientation.vector
        startOrientationXYZW = [q.x, q.y, q.z, q.w]
        self.calibration = calibration
        self.profile = profile
        forehandBodySign = profile.forehandBodySign
        self.model = model
        self.calibrationMode = calibrationMode
    }

    private enum CodingKeys: String, CodingKey {
        case formatVersion, sampleOffset, sampleCount, impactIndex, seq, boot, backlog
        case startOrientationXYZW, calibration, profile, forehandBodySign, model, calibrationMode
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        formatVersion = try c.decode(Int.self, forKey: .formatVersion)
        sampleOffset = try c.decode(Int.self, forKey: .sampleOffset)
        sampleCount = try c.decode(Int.self, forKey: .sampleCount)
        impactIndex = try c.decode(Int.self, forKey: .impactIndex)
        seq = try c.decode(UInt16.self, forKey: .seq)
        boot = try c.decodeIfPresent(UInt16.self, forKey: .boot)
        backlog = try c.decode(Bool.self, forKey: .backlog)
        startOrientationXYZW = try c.decode([Float].self, forKey: .startOrientationXYZW)
        calibration = try c.decode(Calibration.self, forKey: .calibration)
        profile = try c.decode(RacketProfile.self, forKey: .profile)
        forehandBodySign = try c.decode(Float.self, forKey: .forehandBodySign)
        profile.forehandBodySign = forehandBodySign
        model = try c.decode(ImpactModel.self, forKey: .model)
        calibrationMode = try c.decodeIfPresent(Bool.self, forKey: .calibrationMode) ?? false
    }

    public enum ReplayError: Error { case invalidContext }

    public func window(from recording: [IMUSample]) throws -> ImpactWindow {
        guard formatVersion == 1, sampleOffset >= 0, sampleOffset <= recording.count,
              sampleCount > 0, sampleCount <= recording.count - sampleOffset,
              impactIndex >= 0, impactIndex < sampleCount,
              startOrientationXYZW.count == 4, startOrientationXYZW.allSatisfy(\.isFinite) else {
            throw ReplayError.invalidContext
        }
        let q = SIMD4(startOrientationXYZW[0], startOrientationXYZW[1],
                      startOrientationXYZW[2], startOrientationXYZW[3])
        guard abs(simd_length(q) - 1) < 0.01 else { throw ReplayError.invalidContext }
        var window = ImpactWindow(seq: seq, impactIndex: impactIndex, startOrientation: simd_quatf(vector: q),
                                  samples: Array(recording[sampleOffset..<(sampleOffset + sampleCount)]), boot: boot)
        window.backlog = backlog
        return window
    }
}

/// Raw sensor recordings (`.tbrec`): little-endian records of `f64 time` + 9 × `f32`
/// (accel xyz g, gyro xyz rad/s, high-g xyz g), all in sensor axes.
public enum RecordingFormat {
    public static let fileExtension = "tbrec"
    static let recordSize = 8 + 9 * 4

    public static func encode(_ samples: [IMUSample]) -> Data {
        var data = Data(capacity: samples.count * recordSize)
        for s in samples {
            var t = s.time
            withUnsafeBytes(of: &t) { data.append(contentsOf: $0) }
            for v in [s.accel.x, s.accel.y, s.accel.z, s.gyro.x, s.gyro.y, s.gyro.z, s.highG.x, s.highG.y, s.highG.z] {
                var f = v
                withUnsafeBytes(of: &f) { data.append(contentsOf: $0) }
            }
        }
        return data
    }

    public static func decode(_ data: Data) -> [IMUSample] {
        let n = data.count / recordSize
        var out: [IMUSample] = []
        out.reserveCapacity(n)
        data.withUnsafeBytes { raw in
            for i in 0..<n {
                let o = i * recordSize
                let t = raw.loadUnaligned(fromByteOffset: o, as: Double.self)
                func f(_ k: Int) -> Float { raw.loadUnaligned(fromByteOffset: o + 8 + k * 4, as: Float.self) }
                out.append(IMUSample(time: t, accel: SIMD3(f(0), f(1), f(2)),
                                     gyro: SIMD3(f(3), f(4), f(5)), highG: SIMD3(f(6), f(7), f(8))))
            }
        }
        return out
    }

    public static func csv(_ samples: [IMUSample]) -> String {
        var s = "time_s,ax_g,ay_g,az_g,gx_rads,gy_rads,gz_rads,hx_g,hy_g,hz_g\n"
        for x in samples {
            s += String(format: "%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.3f,%.3f,%.3f\n", x.time,
                        x.accel.x, x.accel.y, x.accel.z, x.gyro.x, x.gyro.y, x.gyro.z, x.highG.x, x.highG.y, x.highG.z)
        }
        return s
    }
}

/// Appends raw samples to a `.tbrec` file while recording.
public final class Recorder: @unchecked Sendable {
    private let lock = NSLock()
    private var handle: FileHandle?
    private var contextHandle: FileHandle?
    public private(set) var url: URL?
    public private(set) var sampleCount = 0
    public private(set) var missingImpactContexts = 0

    public init() {}

    public var isRecording: Bool { lock.withLock { handle != nil } }

    public func start(in directory: URL, name: String) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(name).appendingPathExtension(RecordingFormat.fileExtension)
        FileManager.default.createFile(atPath: url.path, contents: nil)
        let h = try FileHandle(forWritingTo: url)
        let contextURL = url.deletingPathExtension().appendingPathExtension("windows.jsonl")
        FileManager.default.createFile(atPath: contextURL.path, contents: nil)
        let contexts: FileHandle
        do { contexts = try FileHandle(forWritingTo: contextURL) }
        catch { try? h.close(); throw error }
        lock.withLock {
            handle = h
            contextHandle = contexts
            self.url = url
            sampleCount = 0
            missingImpactContexts = 0
        }
    }

    public func append(_ samples: [IMUSample]) {
        lock.withLock {
            guard let handle else { return }
            handle.write(RecordingFormat.encode(samples))
            sampleCount += samples.count
        }
    }

    public func append(_ event: RecordingEvent) {
        switch event {
        case .samples(let samples): append(samples)
        case .impact(let window, let calibration, let profile, let model, let calibrationMode):
            lock.withLock {
                guard let handle else { return }
                let context = RecordedImpactContext(window: window, sampleOffset: sampleCount,
                                                    calibration: calibration, profile: profile, model: model, calibrationMode: calibrationMode)
                // Binary samples and their offset metadata share the same lock,
                // including against stopping the recorder on the main thread.
                handle.write(RecordingFormat.encode(window.samples))
                if let data = try? JSONEncoder().encode(context), let contextHandle {
                    contextHandle.write(data + Data([0x0A]))
                } else {
                    missingImpactContexts += 1
                }
                sampleCount += window.samples.count
            }
        }
    }

    @discardableResult
    public func stop() -> URL? {
        lock.withLock {
            try? handle?.close()
            try? contextHandle?.close()
            handle = nil
            contextHandle = nil
            return url
        }
    }
}

/// Plays a recording back in real time as if it were the live racket.
public final class ReplaySource: SampleSource, @unchecked Sendable {
    public var onSamples: (([IMUSample]) -> Void)?
    public var nativeCalibration: Calibration? { nil }
    public var loop = true

    private let samples: [IMUSample]
    private var cursor = 0
    private var timer: DispatchSourceTimer?
    private let queue = DispatchQueue(label: "tennisbuddy.replay", qos: .userInitiated)
    private var timeOffset: Double = 0

    public init(url: URL) throws {
        samples = RecordingFormat.decode(try Data(contentsOf: url))
    }

    public var duration: Double { (samples.last?.time ?? 0) - (samples.first?.time ?? 0) }

    public func start() {
        stop()
        guard !samples.isEmpty else { return }
        let t = DispatchSource.makeTimerSource(queue: queue)
        t.schedule(deadline: .now(), repeating: .milliseconds(10), leeway: .milliseconds(2))
        t.setEventHandler { [weak self] in self?.tick() }
        timer = t
        t.resume()
    }

    public func stop() {
        timer?.cancel()
        timer = nil
    }

    private func tick() {
        var batch: [IMUSample] = []
        for _ in 0..<10 {
            if cursor >= samples.count {
                guard loop else { stop(); break }
                timeOffset += duration + 0.001
                cursor = 0
            }
            var s = samples[cursor]
            s.time += timeOffset
            batch.append(s)
            cursor += 1
        }
        if !batch.isEmpty { onSamples?(batch) }
    }
}
