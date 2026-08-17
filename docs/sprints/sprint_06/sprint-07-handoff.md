# Sprint 7 Handoff — Health & Wearables

## Starting point

Sprint 6 leaves Prana with a stable offline-first weight domain. Imported measurements should feed the existing domain rather than create a separate wearable-only progress system.

## Sprint 7 objective

Create a platform-independent health-data integration layer that can ingest supported health/device signals on iOS and Android.

Primary platforms:
- Apple Health
- Android Health Connect

## Architecture direction

```text
Presentation
    ↓
Health sync/application service
    ↓
Health data repository interface
    ↓
Platform adapter
    ├── Apple Health
    └── Health Connect
```

Weight imports should map to normal `WeightEntry` objects with `appleHealth` or `healthConnect` source values and then flow through WeightStorage, trend, goal progress, chart, and recent pace logic.

## Initial data candidates

Start with:
- body weight
- active energy
- steps
- workouts/activity sessions

Later candidates:
- resting heart rate
- heart-rate variability
- sleep
- respiratory rate
- other readiness-oriented signals

## Product rules

Wearable data is a signal, not a diagnosis.

Prefer trends, personal baselines, explainable summaries, explicit permissions, and user control.

Avoid medical diagnosis language, automatic calorie changes from one wearable signal, treating device estimates as perfect, or hidden sync behavior.

## Interaction with nutrition

Activity should remain separate from food intake. Do not automatically “eat back” all exercise calories. Any future nutrition adaptation should be a separate, controlled policy.

## Deferred from Sprint 6

Sprint 7 should not rewrite WeightTrendService, GoalPaceService, or RecentWeightPaceService unless integration exposes a real domain requirement.

Prefer adapting imported platform data into existing entities.
