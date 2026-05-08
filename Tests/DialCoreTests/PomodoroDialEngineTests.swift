import XCTest
import DialCore

final class PomodoroDialEngineTests: XCTestCase {
    func testSpunToStartTransitionsToRunningFocus() {
        let focus: TimeInterval = 1_500
        let rest: TimeInterval = 300

        var engine = PomodoroDialEngine(focusDurationSeconds: focus, restDurationSeconds: rest)
        let analytics = engine.handle(.spunToStart)

        XCTAssertTrue(analytics.isEmpty)
        XCTAssertEqual(engine.state.status, .running)
        XCTAssertEqual(engine.state.segment, .focus)
        XCTAssertEqual(engine.state.remainingSeconds, focus)
    }

    func testPauseAndResumeTransitions() {
        let focus: TimeInterval = 1500
        let rest: TimeInterval = 300

        var engine = PomodoroDialEngine(focusDurationSeconds: focus, restDurationSeconds: rest)
        _ = engine.handle(.spunToStart)

        _ = engine.handle(.pauseTapped)
        XCTAssertEqual(engine.state.status, .paused)

        _ = engine.handle(.resumeTapped)
        XCTAssertEqual(engine.state.status, .running)
        XCTAssertEqual(engine.state.segment, .focus)
    }

    func testSkipTappedCompletesSegmentsAndSession() {
        let focus: TimeInterval = 3
        let rest: TimeInterval = 2

        var engine = PomodoroDialEngine(focusDurationSeconds: focus, restDurationSeconds: rest)
        _ = engine.handle(.spunToStart)

        let firstSkip = engine.handle(.skipTapped)
        XCTAssertEqual(firstSkip, [.segmentCompleted(.focus)])
        XCTAssertEqual(engine.state.status, .running)
        XCTAssertEqual(engine.state.segment, .rest)
        XCTAssertEqual(engine.state.remainingSeconds, rest)

        let secondSkip = engine.handle(.skipTapped)
        XCTAssertEqual(secondSkip, [.segmentCompleted(.rest), .sessionCompleted])
        XCTAssertEqual(engine.state.status, .completed)
        XCTAssertNil(engine.state.segment)
        XCTAssertEqual(engine.state.remainingSeconds, 0)
    }

    func testTickedCarriesLeftoverTimeAcrossSegments() {
        let focus: TimeInterval = 3
        let rest: TimeInterval = 2

        var engine = PomodoroDialEngine(focusDurationSeconds: focus, restDurationSeconds: rest)
        _ = engine.handle(.spunToStart)

        let analytics = engine.handle(.ticked(seconds: 5))
        XCTAssertEqual(analytics, [.segmentCompleted(.focus), .segmentCompleted(.rest), .sessionCompleted])

        XCTAssertEqual(engine.state.status, .completed)
        XCTAssertNil(engine.state.segment)
        XCTAssertEqual(engine.state.remainingSeconds, 0)
    }

    func testTickedOvershootsAndCompletesSession() {
        let focus: TimeInterval = 1
        let rest: TimeInterval = 1

        var engine = PomodoroDialEngine(focusDurationSeconds: focus, restDurationSeconds: rest)
        _ = engine.handle(.spunToStart)

        let analytics = engine.handle(.ticked(seconds: 2))
        XCTAssertEqual(analytics, [.segmentCompleted(.focus), .segmentCompleted(.rest), .sessionCompleted])

        XCTAssertEqual(engine.state.status, .completed)
        XCTAssertNil(engine.state.segment)
        XCTAssertEqual(engine.state.remainingSeconds, 0)
    }
}
