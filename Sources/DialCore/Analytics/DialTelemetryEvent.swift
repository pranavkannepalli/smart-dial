import Foundation

public enum DialTelemetryEventType: String, Codable {
    case pomodoroInteraction = "pomodoro_interaction"
    case pomodoroSegmentCompleted = "pomodoro_segment_completed"
    case pomodoroSessionCompleted = "pomodoro_session_completed"
    case phonePickupDetected = "phone_pickup_detected"
    case dialSpinGesture = "dial_spin_gesture"
}

public enum PomodoroInteractionKind: String, Codable {
    case spunToStart
    case pauseTapped
    case resumeTapped
    case skipTapped
}

/// A single analytics event emitted by the Smart Productivity Dial.
///
/// Schema note:
/// - This is intentionally “wide” so one JSON shape can represent multiple event types.
/// - For each `type`, only a documented subset of fields is expected to be non-nil.
public struct DialTelemetryEvent: Codable, Equatable {
    public let type: DialTelemetryEventType
    public let occurredAt: Date

    /// Correlates all events belonging to the same pomodoro session.
    public var sessionId: UUID?

    // --- Pomodoro interaction ---
    public var interactionKind: PomodoroInteractionKind?

    // --- Pomodoro segment ---
    public var segment: PomodoroSegment?
    public var segmentStartedAt: Date?
    public var segmentEndedAt: Date?

    // --- Phone pickup ---
    public var phonePickupCountDelta: Int?
    public var phonePickupSignalSource: String?

    // --- Dial spin gesture ---
    public var spinRotationDegrees: Double?
    public var spinAngularVelocityDegreesPerSecond: Double?

    public init(
        type: DialTelemetryEventType,
        occurredAt: Date,
        sessionId: UUID? = nil,
        interactionKind: PomodoroInteractionKind? = nil,
        segment: PomodoroSegment? = nil,
        segmentStartedAt: Date? = nil,
        segmentEndedAt: Date? = nil,
        phonePickupCountDelta: Int? = nil,
        phonePickupSignalSource: String? = nil,
        spinRotationDegrees: Double? = nil,
        spinAngularVelocityDegreesPerSecond: Double? = nil
    ) {
        self.type = type
        self.occurredAt = occurredAt
        self.sessionId = sessionId
        self.interactionKind = interactionKind
        self.segment = segment
        self.segmentStartedAt = segmentStartedAt
        self.segmentEndedAt = segmentEndedAt
        self.phonePickupCountDelta = phonePickupCountDelta
        self.phonePickupSignalSource = phonePickupSignalSource
        self.spinRotationDegrees = spinRotationDegrees
        self.spinAngularVelocityDegreesPerSecond = spinAngularVelocityDegreesPerSecond
    }
}

public extension DialTelemetryEvent {
    /// Observed segment duration in seconds when the event carries both endpoints.
    var observedSegmentSeconds: TimeInterval? {
        guard let started = segmentStartedAt, let ended = segmentEndedAt else { return nil }
        return max(0, ended.timeIntervalSince(started))
    }
}
