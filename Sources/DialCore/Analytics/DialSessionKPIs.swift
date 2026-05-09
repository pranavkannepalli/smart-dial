import Foundation

public struct DialSessionKPIs: Equatable, Codable {
    public let focusSecondsObserved: TimeInterval
    public let restSecondsObserved: TimeInterval

    public let phonePickupsDuringFocus: Int
    public let phonePickupRatePerMinute: Double

    public let dialSpinGestureCount: Int
    public let skipTappedCount: Int

    public let pomodoroSessionsCompleted: Int
}

public struct DialSessionKPIComputer {
    public init() {}

    /// Computes KPIs for a single pomodoro session.
    ///
    /// Assumptions (driven by the event schema spec in `METRICS_SPEC.md`):
    /// - `pomodoro_segment_completed` events contain `segmentStartedAt` + `segmentEndedAt`.
    /// - `phone_pickup_detected` events contain `occurredAt`.
    public func computeSessionKPIs(events: [DialTelemetryEvent]) -> DialSessionKPIs {
        let completedCount = events.filter { $0.type == .pomodoroSessionCompleted }.count

        let segmentEvents = events.filter { $0.type == .pomodoroSegmentCompleted && $0.segment != nil }
        let focusSegments = segmentEvents.filter { $0.segment == .focus }
        let restSegments = segmentEvents.filter { $0.segment == .rest }

        let focusSeconds = focusSegments.reduce(0) { partial, e in
            guard let s = e.observedSegmentSeconds else { return partial }
            return partial + s
        }

        let restSeconds = restSegments.reduce(0) { partial, e in
            guard let s = e.observedSegmentSeconds else { return partial }
            return partial + s
        }

        let phonePickupsDuringFocus = events.filter { e in
            guard e.type == .phonePickupDetected else { return false }
            let pickupTime = e.occurredAt

            // Count pickup if it lands inside ANY focus segment window.
            return focusSegments.contains(where: { seg in
                guard let start = seg.segmentStartedAt, let end = seg.segmentEndedAt else { return false }
                return pickupTime >= start && pickupTime <= end
            })
        }.reduce(0) { partial, e in
            partial + max(0, e.phonePickupCountDelta ?? 1)
        }

        let focusMinutes = max(0, focusSeconds / 60)
        let phonePickupRatePerMinute: Double = focusMinutes > 0 ? (Double(phonePickupsDuringFocus) / focusMinutes) : 0

        let spinGestureCount = events.filter { $0.type == .dialSpinGesture }.count
        let skipTappedCount = events.filter {
            $0.type == .pomodoroInteraction && $0.interactionKind == .skipTapped
        }.count

        return DialSessionKPIs(
            focusSecondsObserved: focusSeconds,
            restSecondsObserved: restSeconds,
            phonePickupsDuringFocus: phonePickupsDuringFocus,
            phonePickupRatePerMinute: phonePickupRatePerMinute,
            dialSpinGestureCount: spinGestureCount,
            skipTappedCount: skipTappedCount,
            pomodoroSessionsCompleted: completedCount
        )
    }
}
