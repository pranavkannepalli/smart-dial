import XCTest
@testable import DialCore

final class DialSessionKPIsTests: XCTestCase {
    func testCodableRoundTrip() throws {
        let e = DialTelemetryEvent(
            type: .phonePickupDetected,
            occurredAt: Date(timeIntervalSince1970: 1_700_000_000),
            sessionId: UUID(uuidString: "11111111-1111-1111-1111-111111111111"),
            phonePickupCountDelta: 3,
            phonePickupSignalSource: "screen_time"
        )

        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601

        let data = try enc.encode(e)
        let decoded = try dec.decode(DialTelemetryEvent.self, from: data)
        XCTAssertEqual(decoded, e)
    }

    func testComputeSessionKPIs() {
        let sessionId = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

        let t0 = Date(timeIntervalSince1970: 1_700_000_100)
        let focusStart = t0
        let focusEnd = t0.addingTimeInterval(10)
        let restStart = focusEnd
        let restEnd = focusEnd.addingTimeInterval(5)

        let events: [DialTelemetryEvent] = [
            DialTelemetryEvent(
                type: .pomodoroSegmentCompleted,
                occurredAt: focusEnd,
                sessionId: sessionId,
                segment: .focus,
                segmentStartedAt: focusStart,
                segmentEndedAt: focusEnd
            ),
            DialTelemetryEvent(
                type: .pomodoroSegmentCompleted,
                occurredAt: restEnd,
                sessionId: sessionId,
                segment: .rest,
                segmentStartedAt: restStart,
                segmentEndedAt: restEnd
            ),
            DialTelemetryEvent(
                type: .phonePickupDetected,
                occurredAt: t0.addingTimeInterval(3),
                sessionId: sessionId,
                phonePickupCountDelta: 1,
                phonePickupSignalSource: "screen_time"
            ),
            DialTelemetryEvent(
                type: .phonePickupDetected,
                occurredAt: t0.addingTimeInterval(12),
                sessionId: sessionId,
                phonePickupCountDelta: 2
            ),
            DialTelemetryEvent(
                type: .dialSpinGesture,
                occurredAt: t0.addingTimeInterval(1),
                sessionId: sessionId,
                spinRotationDegrees: 120
            ),
            DialTelemetryEvent(
                type: .dialSpinGesture,
                occurredAt: t0.addingTimeInterval(2),
                sessionId: sessionId,
                spinRotationDegrees: 80
            ),
            DialTelemetryEvent(
                type: .pomodoroInteraction,
                occurredAt: t0.addingTimeInterval(4),
                sessionId: sessionId,
                interactionKind: .skipTapped
            ),
            DialTelemetryEvent(
                type: .pomodoroSessionCompleted,
                occurredAt: restEnd,
                sessionId: sessionId
            )
        ]

        let kpis = DialSessionKPIComputer().computeSessionKPIs(events: events)
        XCTAssertEqual(kpis.focusSecondsObserved, 10, accuracy: 0.000_001)
        XCTAssertEqual(kpis.restSecondsObserved, 5, accuracy: 0.000_001)
        XCTAssertEqual(kpis.phonePickupsDuringFocus, 1) // pickup at t0+12 is in rest window
        XCTAssertEqual(kpis.phonePickupRatePerMinute, 6.0, accuracy: 0.000_001) // 1 / (10/60) = 6
        XCTAssertEqual(kpis.dialSpinGestureCount, 2)
        XCTAssertEqual(kpis.skipTappedCount, 1)
        XCTAssertEqual(kpis.pomodoroSessionsCompleted, 1)
    }
}
