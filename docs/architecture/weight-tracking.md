# Weight Tracking Architecture

## Purpose

The weight-tracking feature provides an offline-first foundation for measurement history, trend analysis, progress calculation, goal planning, and future wearable ingestion.

The architecture intentionally separates raw measurements from derived health/product signals.

## Domain entity — WeightEntry

A `WeightEntry` represents a historical measurement.

Fields:
- `id`
- `weightKg`
- `measuredAt`
- `source`
- `note`

Sources:
- `manual`
- `appleHealth`
- `healthConnect`
- `smartScale`
- `unknown`

Validation requires weight to be greater than zero. Entries support JSON serialization for local persistence.

## WeightStorage

Current backend:
- `SharedPreferencesAsync`

Storage key:
- `prana_weight_entries`

Responsibilities:
- load all entries
- save entries
- add entry
- update entry
- delete entry
- load entries for a calendar date
- load latest entry
- clear entries

Stored entries are sorted chronologically. Storage does not calculate trend or goal progress.

## WeightTrendService

If multiple measurements exist on the same calendar day, the latest measurement from that day is used for trend computation. All raw entries remain in history.

Trend readiness:
- minimum 3 distinct measurement days

Before readiness:
- latest measurement is used for progress

After readiness:
- trend weight is used

Trend window:
- up to 7 recent representative measurement days

Trend calculation:
- arithmetic average of the recent daily representative values

The method is intentionally simple, deterministic, explainable, and dependency-free.

Goal direction:
- lose
- gain
- maintain

The service exposes starting weight, goal weight, latest entry, trend weight, measurement-day count, latest weight, reliable-trend state, progress weight, change from start, distance to goal, goal direction, progress amount, total goal change, progress fraction, progress percentage, and goal-reached state.

Goal tolerance is approximately 0.05 kg. Progress percentage is clamped between 0 and 100.

## GoalPaceService

`GoalPaceService` is pure planning math.

Inputs:
- goal direction
- current progress weight
- goal weight
- selected weekly pace
- starting calendar date

Outputs:
- remaining kilograms
- estimated weeks
- estimated days
- estimated target date
- goal-reached state

Maintenance goals do not receive a directional estimate.

Target dates are calendar dates rather than exact elapsed instants. Calendar components are normalized through UTC date arithmetic to avoid DST shifts.

## GoalPaceStorage

Goal pace is persisted independently from weight measurements.

Separate values are stored for:
- weight-loss pace
- weight-gain pace

Maintenance has no directional pace.

## RecentWeightPaceService

Input preparation:
- raw entries sorted
- latest measurement per calendar day retained
- calendar-day arithmetic UTC-normalized
- recent lookback only

Default reliability rules:
- minimum measurement days: 3
- minimum span: 14 days
- maximum lookback: 28 days
- close-to-plan tolerance: 20%

Regression:
- x-axis: calendar day offset
- y-axis: weight in kg
- slope: kg/day
- reported pace: slope × 7

For loss goals, negative raw weight change becomes positive goal-directed progress. For gain goals, positive raw change becomes positive goal-directed progress.

Comparison states:
- insufficientData
- movingAwayFromGoal
- slowerThanPlan
- closeToPlan
- fasterThanPlan
- notApplicable

Recent pace is informational and must not silently change nutrition targets.

## WeightTrendChart

Implemented with Flutter `CustomPainter`; no external chart package is required.

Behavior:
- daily representative measurement
- up to 14 displayed days
- raw daily line
- rolling trend
- goal reference
- axes/grid/date labels
- semantic label
- legend

A distant goal is excluded from chart scaling so recent variation stays readable. If outside the visible range, the UI states whether the goal lies above or below the chart range.

## Presentation reuse

`WeightTrackingScreen` supports standalone mode via `/weight` and embedded mode inside Dashboard → Progress. This avoids duplicating weight-progress business logic.

## Dashboard integration

`DashboardScreen` owns:

```text
Today | Progress
```

using `TabController`, `TabBar`, and `TabBarView`.

Both tap and swipe navigation are available. Today and Progress maintain independent scroll positions.

## Separation from nutrition calculations

`UserProfile.weightKg` currently remains the starting/reference value used by existing nutrition calculations.

Sprint 6 does not automatically replace this value with latest weight, trend weight, or recent pace output.

A future architecture should introduce an explicit nutrition calculation/reference weight with a controlled update policy.

## Future wearable integration

Imported platform data should create normal domain measurements rather than bypass the feature architecture:

```text
Apple Health / Health Connect / Device API
                  ↓
         Health data adapter
                  ↓
            WeightEntry
                  ↓
            WeightStorage
                  ↓
       Existing trend/progress logic
```
