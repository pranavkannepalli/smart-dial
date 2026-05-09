# Smart Productivity Dial — Event Schema + KPI Definitions

## Goal
Capture an evidence-able loop between:
- Pomodoro control loop (focus/rest)
- Dial UX interactions (spins + button taps)
- Phone pickup behavior during focus

This file defines the **analytics event schema** (JSON field shape) and **KPI computations** based on that schema.

---

## Event schema (single JSON shape)

All events share the same wide JSON shape:

- `type`: string enum
- `occurredAt`: ISO-8601 datetime
- `sessionId`: UUID (nullable)
- Optional fields (expected to be non-null only for specific `type` values):
  - `interactionKind`
  - `segment`, `segmentStartedAt`, `segmentEndedAt`
  - `phonePickupCountDelta`, `phonePickupSignalSource`
  - `spinRotationDegrees`, `spinAngularVelocityDegreesPerSecond`

The reference shape is represented in code as `DialTelemetryEvent`.

### `type` values

1) **Pomodoro interaction**
- `type`: `pomodoro_interaction`
- fields required:
  - `interactionKind` (enum: `spunToStart`, `pauseTapped`, `resumeTapped`, `skipTapped`)
  - `occurredAt`

2) **Pomodoro segment completed**
- `type`: `pomodoro_segment_completed`
- fields required:
  - `segment` (`focus` | `rest`)
  - `segmentStartedAt`
  - `segmentEndedAt`
  - `occurredAt` (typically equals `segmentEndedAt`)

3) **Pomodoro session completed**
- `type`: `pomodoro_session_completed`
- fields required:
  - `occurredAt`

4) **Phone pickup detected**
- `type`: `phone_pickup_detected`
- fields required:
  - `occurredAt`
- fields optional:
  - `phonePickupCountDelta` (default: 1)
  - `phonePickupSignalSource`

5) **Dial spin gesture**
- `type`: `dial_spin_gesture`
- fields required:
  - `occurredAt`
- fields optional:
  - `spinRotationDegrees`
  - `spinAngularVelocityDegreesPerSecond`

---

## KPI definitions

Unless otherwise noted, all KPIs are computed **per session**.

### Pomodoro KPIs

1) **Focus seconds observed**
- Sum of `segmentEndedAt - segmentStartedAt` for all focus segments.

2) **Rest seconds observed**
- Sum of `segmentEndedAt - segmentStartedAt` for all rest segments.

3) **Pomodoro sessions completed**
- Count of `pomodoro_session_completed` events.

4) **Skip-tap count**
- Count of `pomodoro_interaction` events where `interactionKind == skipTapped`.

### Dial UX KPIs

5) **Dial spin gesture count**
- Count of `dial_spin_gesture` events.

### Phone pickup KPIs

6) **Phone pickups during focus**
- Count of `phone_pickup_detected` events whose `occurredAt` falls inside ANY focus segment window.
- If `phonePickupCountDelta` is present, add the delta rather than count 1.

7) **Phone pickup rate (per minute of focus)**
- `phonePickupsDuringFocus / (focusSecondsObserved / 60)`
- If focus seconds is 0, rate is 0.

---

## Implementation hooks (what the app should emit)

### From `PomodoroDialEngine`
- Emit `pomodoro_interaction` on:
  - dial spin to start (`spunToStart`)
  - pause/resume button taps
  - skip taps
- Emit `pomodoro_segment_completed` when the engine completes a focus/rest segment.
  - Populate `segmentStartedAt` and `segmentEndedAt` (engine state must retain start time).

### From phone pickup detection
- Emit `phone_pickup_detected` with `occurredAt` and (optionally) `countDelta`.

### From dial gesture recognizer
- Emit `dial_spin_gesture` with rotation degrees / velocity (when available).
