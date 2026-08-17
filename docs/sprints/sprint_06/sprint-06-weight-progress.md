# Sprint 6 — Weight, Goal Pace & Progress

**Release target:** v0.6.0  
**Branch:** `feature/weight-progress`  
**Latest known code checkpoint:** `ac1baf5`  
**Status:** Feature complete; final release gate and release documentation commit required before tagging.

## Sprint objective

Sprint 6 turns weight tracking from a simple profile value into a real progress system. The sprint adds historical weigh-ins, trend handling, goal progress, planning pace, estimated target dates, recent actual pace analysis, a visual history chart, and a first-class Progress experience on the main dashboard.

The guiding principle is that body weight is noisy. Prana should not overreact to a single measurement or silently change nutrition targets every time weight changes.

## Completed product features

### Weight logging and history

Prana now supports historical `WeightEntry` records with:

- unique ID
- weight in kilograms
- measurement timestamp
- measurement source
- optional note
- add
- update
- delete
- daily lookup
- latest measurement lookup
- persistent local storage

Supported source values:

- manual
- Apple Health
- Health Connect
- smart scale
- unknown

Apple Health, Health Connect, and smart-scale ingestion are model-ready but are not connected in Sprint 6.

### Starting, latest, trend, and goal weight

**Starting weight**
- profile/onboarding baseline
- historical origin for progress
- does not automatically change after new weigh-ins

**Latest weight**
- most recent recorded `WeightEntry`

**Trend weight**
- smoothed measurement used to reduce day-to-day noise
- latest measurement from each calendar day
- minimum 3 distinct measurement days
- average of up to 7 recent daily representative measurements

**Goal weight**
- user-selected target stored in the profile

Before a reliable trend exists, progress calculations use the latest measurement. After the minimum trend requirement is met, progress uses trend weight.

### Goal-direction progress

Prana supports weight-loss, weight-gain, and maintenance goals.

For directional goals, Sprint 6 calculates:

- progress toward goal in kilograms
- total required goal change
- progress fraction
- progress percentage
- remaining distance to goal
- goal-reached state

Displayed percentage is clamped between 0% and 100%. If weight temporarily moves away from the goal, displayed progress remains at 0% rather than showing a negative percentage. Maintenance goals do not use a directional percentage.

### Weight trend chart

A dependency-free Flutter `CustomPainter` chart was added.

Chart behavior:

- latest measurement per calendar day
- up to 14 displayed days
- daily measurement line/points
- rolling trend line
- goal reference
- responsive axes and date labels
- semantic description
- daily/trend/goal legend

A distant goal does not distort the visible chart scale. If the goal sits outside the displayed range, the UI explains whether it is above or below the current chart range.

### Goal pace

Users can select a planned weekly pace.

Current planning ranges:

**Weight loss**
- 0.10–0.90 kg/week
- default 0.40 kg/week

**Weight gain**
- 0.10–0.50 kg/week
- default 0.25 kg/week

The selected value is persisted locally using `SharedPreferencesAsync`.

Goal pace is a planning input. It is not a clinical prescription and does not automatically change nutrition targets.

### Estimated target date

The Goal Pace service calculates:

- remaining directional kilograms
- estimated weeks remaining
- estimated days remaining
- estimated target calendar date

Target-date calculation is calendar-day based and avoids daylight-saving-time errors by performing date arithmetic on UTC-normalized calendar dates.

Target dates are estimates, not promises. Real weight change is not assumed to be perfectly linear. Maintenance goals do not receive a directional target date.

### Recent actual pace

Sprint 6 adds a recent weight-pace analysis service.

Rules:

- latest measurement per calendar day
- minimum 3 measurement days
- minimum 14-day measurement span
- maximum 28-day lookback
- linear regression across recent measurements
- output expressed as kg/week

For weight-loss and weight-gain goals, actual pace is converted into the direction of the user's goal and compared with planned pace.

Comparison states:

- insufficient data
- moving away from goal
- slower than plan
- close to plan
- faster than plan
- not applicable

The initial close-to-plan tolerance is ±20% of the selected pace.

Recent pace is informational only. It does not automatically modify the selected pace, target date logic, or nutrition targets.

### Today ↔ Progress dashboard experience

Progress is now a first-class dashboard destination rather than something users need to find through Profile.

The main Prana dashboard contains two visible tabs:

- Today
- Progress

Users can tap either tab or swipe horizontally between tabs.

The Today tab retains the nutrition dashboard and Add Meal action. The Progress tab embeds the existing weight-progress experience and exposes Log Weight. Each tab preserves its scroll position when the user switches away and returns.

The existing `/weight` route remains available as a standalone screen for deep links and future secondary navigation.

### Profile cleanup

The redundant Profile → Weight & Progress navigation card was removed because Progress is now directly available from the dashboard.

Profile remains focused on personal information, starting/reference weight, goals, activity level, and profile editing.

## Architecture

```text
lib/features/weight_tracking/
├── data/
│   ├── goal_pace_storage.dart
│   └── weight_storage.dart
├── domain/
│   ├── entities/
│   │   └── weight_entry.dart
│   └── services/
│       ├── goal_pace_service.dart
│       ├── recent_weight_pace_service.dart
│       └── weight_trend_service.dart
└── presentation/
    ├── screens/
    │   └── weight_tracking_screen.dart
    └── widgets/
        └── weight_trend_chart.dart
```

Dashboard integration:

```text
lib/features/dashboard/presentation/dashboard_screen.dart
```

## Storage

Sprint 6 remains offline-first.

Weight history key:
- `prana_weight_entries`

Goal pace:
- separate persisted values for weight-loss and weight-gain planning

Cloud sync is deferred.

## Important product rules preserved

Sprint 6 intentionally does **not**:

- automatically change nutrition targets after every weigh-in
- treat a single weigh-in as a trend
- punish the following day for today's intake
- automatically eat back all exercise calories
- treat planned pace as a guaranteed outcome
- treat recent actual pace as a diagnosis
- silently overwrite the user's starting weight

A future nutrition-reference mechanism may use sustained trend change and explicit user control.

## Manual acceptance testing completed

The Today ↔ Progress refactor was manually verified with the following behavior:

1. App opens on Today.
2. Tapping Progress opens the progress experience.
3. Swipe Progress → Today works.
4. Swipe Today → Progress works.
5. Add Meal appears only on Today.
6. Log Weight appears on Progress.
7. Logging a weight refreshes Progress.
8. Pull-to-refresh works independently on both tabs.
9. Today scroll position is retained when switching tabs.
10. Profile icon works from either tab.
11. The standalone `/weight` route remains functional.

## Automated validation

Known automated state before final release packaging:

- `flutter analyze`: clean after recent pace service work
- `flutter test`: 69 tests passed after recent pace service work
- dashboard/progress navigation subsequently passed manual acceptance testing

**Required before v0.6.0 tag:** rerun the complete format/analyze/test release gate after documentation is committed and after any final wording changes.

## Sprint 6 Git checkpoints

- `4c7b6e1` — add weight history trend chart
- `c1c10d2` — add goal pace and target date calculations
- `aff6bd4` — add persistent goal pace and target date
- `6174fdc` — add recent weight pace analysis
- `ac1baf5` — add swipeable progress dashboard

## Known limitations

- kilograms only
- local persistence only
- no Apple Health ingestion yet
- no Health Connect ingestion yet
- no smart-scale ingestion yet
- no editable measurement timestamp UI yet
- no measurement notes UI yet
- trend is intentionally simple and explainable rather than a medical forecasting model
- recent pace needs at least 14 days of history
- recent pace uses at most 28 days
- target dates remain planning estimates
- nutrition reference weight is not automatically adapted

## Sprint acceptance criteria

Sprint 6 is complete when:

- historical weights can be logged and deleted
- trend weight is calculated from multiple days
- progress toward a goal is visible
- gain/loss/maintenance directions are handled
- a chart displays daily weight and trend
- goal pace persists
- estimated target date is displayed
- recent pace avoids premature short-history extrapolation
- Progress is easily accessible from the main dashboard
- Today and Progress can be tapped or swiped
- profile navigation is no longer required to reach Progress
- automated release gate passes
- documentation is committed
- v0.6.0 is tagged and pushed
