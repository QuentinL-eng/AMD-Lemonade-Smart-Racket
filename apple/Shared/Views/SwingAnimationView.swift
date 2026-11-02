import QuartzCore
import RacketKit
import SceneKit
import SwiftUI
import simd

/// What the animation shows. Changed from SwiftUI; read on SceneKit's render thread.
struct SwingShow: Equatable {
    enum Mode: String, CaseIterable, Identifiable { case auto = "Both", yours = "Yours", change = "Change"; var id: String { rawValue } }
    var before: ShotSimulator.Parameters
    var after: ShotSimulator.Parameters
    var beforeBall: (kmh: Double, rpm: Double)
    var afterBall: (kmh: Double, rpm: Double)
    var backhand: Bool
    var mode: Mode = .auto

    var hasChange: Bool { before != after }

    static func == (a: SwingShow, b: SwingShow) -> Bool {
        a.before == b.before && a.after == b.after && a.backhand == b.backhand && a.mode == b.mode
    }

    /// Fixed timing (same for every film): 2.6 s per half, contact 1.1 s in, 0.16x slow motion.
    static let half = 2.6, contactAt = 1.1, slowMo = 0.16

    /// Which half is playing and the real time from contact, at `clock` seconds since the start.
    func frame(_ clock: Double) -> (changed: Bool, t: Double) {
        let both = mode == .auto && hasChange
        let u = clock.truncatingRemainder(dividingBy: both ? 2 * Self.half : Self.half)
        let changed = both ? u >= Self.half : (mode == .change && hasChange)
        return (changed, ((both && changed ? u - Self.half : u) - Self.contactAt) * Self.slowMo)
    }
}

/// SceneKit side of the animation: builds the fixed set once, then poses it every frame.
final class SwingStage: NSObject, SCNSceneRendererDelegate, @unchecked Sendable {
    let scene = SCNScene()
    let camera = SCNNode()
    private let racket = SCNNode()
    private let ball = SCNNode()
    private let trail = SCNNode()
    private let ghost = SCNNode()
    private let lock = NSLock()
    private var show: SwingShow
    private var start = CACurrentMediaTime()
    private var ghostKey: ShotSimulator.Parameters?

    static let accent = PlatformColor(red: 0.867, green: 0.910, blue: 0.357, alpha: 1)   // #DDE85B
    static let background = PlatformColor(red: 0.043, green: 0.047, blue: 0.035, alpha: 1) // #0B0C09

    @MainActor
    init(_ show: SwingShow) {
        self.show = show
        super.init()
        scene.background.contents = Self.background
        scene.lightingEnvironment.intensity = 1

        camera.camera = SCNCamera()
        camera.camera?.zNear = 0.05
        camera.camera?.zFar = 30
        camera.position = SCNVector3(-0.75, 0.7, 1.45)
        camera.look(at: SCNVector3(0.05, -0.08, -0.45))
        scene.rootNode.addChildNode(camera)

        let key = SCNNode()
        key.light = SCNLight()
        key.light?.type = .directional
        key.light?.intensity = 1100
        key.eulerAngles = SCNVector3(-0.9, -0.5, 0)
        let fill = SCNNode()
        fill.light = SCNLight()
        fill.light?.type = .ambient
        fill.light?.intensity = 260
        let rim = SCNNode()
        rim.light = SCNLight()
        rim.light?.type = .omni
        rim.light?.color = Self.accent
        rim.light?.intensity = 900
        rim.position = SCNVector3(-0.8, 0.6, -1.6)
        [key, fill, rim].forEach(scene.rootNode.addChildNode)

        scene.rootNode.addChildNode(Self.grid())
        racket.addChildNode(RacketScene.loadDetailedRacket() ?? Self.simpleRacket())
        let ballMat = SCNMaterial()
        ballMat.diffuse.contents = PlatformColor(red: 0.85, green: 0.93, blue: 0.25, alpha: 1)
        ballMat.emission.contents = PlatformColor(red: 0.16, green: 0.18, blue: 0.04, alpha: 1)
        let sphere = SCNSphere(radius: CGFloat(SwingTemplate.ballRadius))
        sphere.segmentCount = 40
        sphere.materials = [ballMat]
        let seam = SCNNode(geometry: SCNTorus(ringRadius: CGFloat(SwingTemplate.ballRadius) * 1.002, pipeRadius: 0.0024))
        seam.geometry?.firstMaterial?.diffuse.contents = PlatformColor(white: 0.96, alpha: 1)
        seam.geometry?.firstMaterial?.lightingModel = .constant
        seam.eulerAngles.x = .pi / 2
        ball.geometry = sphere
        ball.addChildNode(seam)
        [ghost, trail, racket, ball].forEach(scene.rootNode.addChildNode)
    }

    /// Fit the whole swing (about 2.2 m wide, 1.2 m tall) in the card: wide cards fit the height, narrow ones the width.
    @MainActor
    func fit(aspect: CGFloat) {
        guard let cam = camera.camera, aspect.isFinite, aspect > 0 else { return }
        cam.projectionDirection = aspect > 1.8 ? .vertical : .horizontal
        cam.fieldOfView = aspect > 1.8 ? 42 : 70
    }

    func update(_ new: SwingShow) {
        lock.lock(); defer { lock.unlock() }
        if new.before != show.before || new.after != show.after || new.mode != show.mode { start = CACurrentMediaTime() }
        show = new
    }

    /// Seconds since the current loop started, for the SwiftUI labels.
    func clock() -> (SwingShow, Double) {
        lock.lock(); defer { lock.unlock() }
        return (show, CACurrentMediaTime() - start)
    }

    func renderer(_ renderer: any SCNSceneRenderer, updateAtTime time: TimeInterval) {
        let (show, clock) = clock()
        let (changed, t) = show.frame(clock)
        let params = changed ? show.after : show.before
        let pose = SwingTemplate.pose(params, t: t, backhand: show.backhand)
        racket.simdTransform = pose.racket

        // the string bed's path so far; in the changed half, the player's own swing stays as a ghost
        let points = stride(from: -0.32, through: min(t, 0.32), by: 0.0075).map {
            SwingTemplate.pose(params, t: $0, backhand: show.backhand).bed
        }
        trail.geometry = Self.tube(points, radius: 0.008, color: Self.accent)
        let ghostParams: ShotSimulator.Parameters? = changed ? show.before : nil
        if ghostParams != ghostKey {
            ghostKey = ghostParams
            ghost.geometry = ghostParams.flatMap { p in
                Self.tube(stride(from: -0.32, through: 0.32, by: 0.0075).map { SwingTemplate.pose(p, t: $0, backhand: show.backhand).bed },
                          radius: 0.006, color: PlatformColor(red: 0.49, green: 0.51, blue: 0.42, alpha: 0.7))
            }
        }

        // the ball: in toward the strings, then off the face at the estimated speed, spinning
        let b = changed ? show.afterBall : show.beforeBall
        ball.isHidden = t > SwingTemplate.ballShown
        if t < 0 {
            ball.simdPosition = simd_normalize(SIMD3<Float>(1, 0.04, 0)) * Float(params.incomingSpeedKmh / 3.6 * -t)
            ball.simdOrientation = simd_quatf(angle: 0, axis: SIMD3(0, 1, 0))
        } else {
            ball.simdPosition = pose.normal * Float(b.kmh / 3.6 * t)
            let contact = SwingTemplate.pose(params, t: 0, backhand: show.backhand)
            ball.simdOrientation = simd_quatf(angle: -Float(b.rpm / 60 * 2 * .pi * t), axis: contact.up)
        }
        ball.opacity = t > 0 ? CGFloat(1 - t / SwingTemplate.ballShown) : 1
    }

    // MARK: Geometry

    /// A glowing tube through `points`.
    static func tube(_ points: [SIMD3<Float>], radius: Float, color: PlatformColor) -> SCNGeometry? {
        guard points.count >= 2 else { return nil }
        let sides = 8
        var verts: [SCNVector3] = [], normals: [SCNVector3] = [], index: [Int32] = []
        var prevSide = SIMD3<Float>(0, 1, 0)
        for (i, p) in points.enumerated() {
            let a = points[max(i - 1, 0)], b = points[min(i + 1, points.count - 1)]
            let dir = simd_normalize(b - a + SIMD3(0, 0, 1e-6))
            var side = simd_cross(dir, prevSide)
            if simd_length(side) < 1e-4 { side = simd_cross(dir, SIMD3(1, 0, 0)) }
            side = simd_normalize(side)
            let up = simd_cross(side, dir)
            prevSide = up
            for k in 0..<sides {
                let ang = Float(k) / Float(sides) * 2 * .pi
                let nrm = cos(ang) * side + sin(ang) * up
                verts.append(SCNVector3(p + radius * nrm))
                normals.append(SCNVector3(nrm))
            }
        }
        for i in 0..<(points.count - 1) {
            for k in 0..<sides {
                let a = Int32(i * sides + k), b = Int32(i * sides + (k + 1) % sides)
                let c = a + Int32(sides), d = b + Int32(sides)
                index += [a, c, b, b, c, d]
            }
        }
        let geo = SCNGeometry(sources: [SCNGeometrySource(vertices: verts), SCNGeometrySource(normals: normals)],
                              elements: [SCNGeometryElement(indices: index, primitiveType: .triangles)])
        let mat = SCNMaterial()
        mat.lightingModel = .constant
        mat.diffuse.contents = color
        mat.emission.contents = color
        geo.materials = [mat]
        return geo
    }

    /// Floor lines: a fixed reference for "up".
    private static func grid() -> SCNNode {
        var verts: [SCNVector3] = [], index: [Int32] = []
        let y: Float = -0.75, half: Float = 3, step: Float = 0.25
        for i in stride(from: -half, through: half, by: step) {
            for (a, b) in [(SIMD3(i, y, -half), SIMD3(i, y, half)), (SIMD3(-half, y, i), SIMD3(half, y, i))] {
                index += [Int32(verts.count), Int32(verts.count + 1)]
                verts += [SCNVector3(a), SCNVector3(b)]
            }
        }
        let geo = SCNGeometry(sources: [SCNGeometrySource(vertices: verts)], elements: [SCNGeometryElement(indices: index, primitiveType: .line)])
        let mat = SCNMaterial()
        mat.lightingModel = .constant
        mat.diffuse.contents = PlatformColor(red: 0.16, green: 0.18, blue: 0.13, alpha: 1)
        geo.materials = [mat]
        return SCNNode(geometry: geo)
    }

    /// If the textured model is missing: hoop, throat and handle in the racket frame (tip toward +x).
    private static func simpleRacket() -> SCNNode {
        let mat = SCNMaterial()
        mat.diffuse.contents = PlatformColor(white: 0.15, alpha: 1)
        let hoop = SCNNode(geometry: SCNTorus(ringRadius: 0.125, pipeRadius: 0.009))
        hoop.geometry?.materials = [mat]
        hoop.eulerAngles.x = .pi / 2
        hoop.scale = SCNVector3(1.3, 1, 1)
        hoop.position = SCNVector3(0.512, 0, 0)
        let shaft = SCNNode(geometry: SCNBox(width: 0.36, height: 0.03, length: 0.03, chamferRadius: 0.008))
        shaft.geometry?.materials = [mat]
        shaft.position = SCNVector3(0.18, 0, 0)
        let node = SCNNode()
        [hoop, shaft].forEach(node.addChildNode)
        return node
    }
}

/// The What-if swing: your average stroke, then the same swing with the change, looping in slow motion.
struct SwingAnimationView: View {
    let show: SwingShow
    var title: String?
    @Binding var mode: SwingShow.Mode
    @State private var stage: SwingStage

    init(show: SwingShow, title: String? = nil, mode: Binding<SwingShow.Mode>) {
        self.show = show
        self.title = title
        _mode = mode
        _stage = State(initialValue: SwingStage(show))
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            GeometryReader { geo in
                SceneView(scene: stage.scene, pointOfView: stage.camera, options: [.rendersContinuously],
                          antialiasingMode: .multisampling4X, delegate: stage)
                    .onChange(of: geo.size, initial: true) { _, size in stage.fit(aspect: size.width / max(size.height, 1)) }
            }
            TimelineView(.periodic(from: .now, by: 0.1)) { _ in
                let (current, clock) = stage.clock()
                let changed = current.frame(clock).changed
                VStack(alignment: .leading, spacing: 4) {
                    Text(changed ? "TRY THIS" : "YOUR SWING")
                        .font(.caption.weight(.bold)).tracking(2)
                        .foregroundStyle(Color(SwingStage.accent))
                    if changed, let title { Text(title).font(.headline).foregroundStyle(.white) }
                }
                .padding(14)
            }
            Text("SLOW MOTION · RACKET DATA")
                .font(.caption2.monospaced()).foregroundStyle(.white.opacity(0.5))
                .padding(14)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            if show.hasChange {
                Picker("Show", selection: $mode) {
                    ForEach(SwingShow.Mode.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .fixedSize()
                .padding(10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
        }
        .frame(height: 340)
        .clipShape(.rect(cornerRadius: 22))
        .environment(\.colorScheme, .dark)
        .onChange(of: show, initial: true) { _, new in stage.update(new) }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Animation of your average swing\(show.hasChange ? " and the changed swing" : "")")
    }
}
