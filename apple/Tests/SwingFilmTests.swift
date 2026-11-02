import XCTest
import RacketKit
import simd

@MainActor
final class SwingFilmTests: XCTestCase {
    func args(_ overrides: [String: Any] = [:]) -> [String: Any] {
        ["stroke": "forehand", "swing_percent": 10, "face_deg": 0, "path_deg": 5, "contact_x_cm": 0, "contact_y_cm": 0,
         "title": "Brush up faster", "cue": "Swing quicker and brush up the back of the ball", "why": "Pace and spin together"]
            .merging(overrides) { $1 }
    }
    let tested: Set<SwingFilm.Key> = [SwingFilm.Key(WhatIf.Deltas(swingPercent: 10, pathDeg: 5))]

    func testValidScriptBecomesAFilm() throws {
        let film = try SwingFilm.validate(args(), stroke: .forehand, tested: tested).get()
        XCTAssertEqual(film.deltas, WhatIf.Deltas(swingPercent: 10, pathDeg: 5))
        XCTAssertEqual(film.title, "Brush up faster")
    }

    func testLimitsRejectEveryProblem() {
        guard case .failure(let r) = SwingFilm.validate(args(["swing_percent": 25, "face_deg": 1, "path_deg": 5,
                                                              "title": "Hit 3 more over the net"]), stroke: .forehand, tested: tested)
        else { return XCTFail("accepted") }
        let all = r.reasons.joined(separator: " | ")
        XCTAssertTrue(all.contains("swing_percent=25"))
        XCTAssertTrue(all.contains("face_deg=1"))
        XCTAssertTrue(all.contains("one or two levers"))
        XCTAssertTrue(all.contains("not tested"))
        XCTAssertTrue(all.contains("title must not contain digits"))
        XCTAssertTrue(all.contains("title must not use: net"))
    }

    func testUntestedDeltasAndWrongStrokeAreRejected() {
        guard case .failure(let r) = SwingFilm.validate(args(["path_deg": 6]), stroke: .backhand, tested: tested)
        else { return XCTFail("accepted") }
        XCTAssertTrue(r.reasons.contains("stroke must be backhand"))
        XCTAssertTrue(r.reasons.contains { $0.contains("not tested") })
    }

    func testTemplatePutsTheStringsOnTheBallAtContact() {
        let p = ShotSimulator.Parameters(swingSpeedKmh: 100, pathAngleDeg: 10, faceAngleDeg: 3, contactXcm: 1, contactYcm: -2)
        for stroke in SwingFilm.strokes {
            let pose = SwingTemplate.pose(p, t: 0, stroke: stroke)
            let butt = SIMD3<Float>(pose.racket.columns.3.x, pose.racket.columns.3.y, pose.racket.columns.3.z)
            let r = SIMD3<Float>(pose.racket.columns.0.x, pose.racket.columns.0.y, pose.racket.columns.0.z)
            let across = SIMD3<Float>(pose.racket.columns.1.x, pose.racket.columns.1.y, pose.racket.columns.1.z)
            let contact = butt + SwingTemplate.bedFromButt * r + 0.01 * across - 0.02 * r
            XCTAssertLessThan(simd_length(contact), 1e-4)                      // ball at the origin
            XCTAssertEqual(simd_determinant(pose.racket), 1, accuracy: 1e-4)   // a rotation, not a mirror
            XCTAssertGreaterThan(pose.normal.x, 0.9)                           // face toward the target
            var open = p; open.faceAngleDeg += 5
            XCTAssertGreaterThan(SwingTemplate.pose(open, t: 0, stroke: stroke).normal.y, pose.normal.y, "\(stroke)")
        }
        // the serve meets the ball overhead: the shoulder pivot sits below contact
        let serve = SwingTemplate.pose(p, t: -0.05, stroke: .serve)
        XCTAssertLessThan(serve.bed.y, 0)
    }

    /// Muse tests a change, tries an untested one, gets the reasons back, then makes the tested film.
    final class Director: MuseTransport {
        var step = 0
        var requests: [[[String: Any]]] = []
        func call(_ name: String, _ args: String) -> [String: Any] {
            ["role": "assistant", "content": NSNull(), "tool_calls": [
                ["id": "c\(step)", "type": "function", "function": ["name": name, "arguments": args]]]]
        }
        func complete(messages: [[String: Any]], tools: [[String: Any]]) async throws -> [String: Any] {
            requests.append(messages)
            step += 1
            switch step {
            case 1: return call("simulate_change", #"{"type":"forehand","swing_percent":10,"path_deg":5}"#)
            case 2: return call("make_swing_film", #"{"stroke":"forehand","swing_percent":12,"face_deg":0,"path_deg":5,"contact_x_cm":0,"contact_y_cm":0,"title":"Faster","cue":"Swing quicker","why":"More pace"}"#)
            default: return call("make_swing_film", #"{"stroke":"forehand","swing_percent":10,"face_deg":0,"path_deg":5,"contact_x_cm":0,"contact_y_cm":0,"title":"Faster","cue":"Swing quicker","why":"More pace"}"#)
            }
        }
    }

    func testDirectorRetriesUntilTheFilmIsValid() async throws {
        let s = SessionRecord()
        s.shotRecords = [ShotRecord(metrics: CoachToolsTests().shot(date: s.startDate))]
        let fake = Director()
        let film = try await SwingFilmDirector(client: fake, tools: CoachTools(current: s, app: nil, sessions: { [s] })).direct(.forehand)
        XCTAssertEqual(film.deltas, WhatIf.Deltas(swingPercent: 10, pathDeg: 5))
        XCTAssertEqual(fake.step, 3)
        let rejected = fake.requests[2].last { $0["tool_call_id"] as? String == "c2" }?["content"] as? String
        XCTAssertTrue(rejected?.contains("not tested") == true)
        XCTAssertTrue((fake.requests[0][0]["content"] as? String)?.contains("make_swing_film") == true)
    }
}
