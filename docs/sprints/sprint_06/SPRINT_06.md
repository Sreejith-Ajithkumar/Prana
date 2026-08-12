# Sprint 6 — Weight Progress

## Status
In progress

## Branch
`feature/weight-progress`

## Objective
Build the first persistent weight-progress experience so Prana can move beyond a single reference weight toward meaningful progress tracking.

## Planned scope
- Add weight-entry/history data model.
- Persist weight history locally.
- Allow users to record a new weight.
- Show recent weight entries.
- Show progress toward goal weight.
- Add an initial weight trend/progress visualization where appropriate.
- Keep the existing profile reference weight and nutrition calculations consistent with the new history model.
- Add tests for storage, calculations, and UI behavior.

## Product direction
This sprint is the foundation for later progress intelligence. Future versions can use weight history together with nutrition, activity, workouts, and wearable signals to improve recommendations.

## Not in Sprint 6
Unless explicitly pulled into scope later:
- Full wearable integration.
- AI workout coaching.
- Gym exercise/set/rep/weight tracking.
- Athletic, cycling, or swimming coaching.
- Menstrual-cycle-aware workout/nutrition recommendations.
- Full recipe/world-map experience.

These remain later roadmap capabilities.

## Completion gate
Before Sprint 6 release:
- `dart format` / formatting check passes.
- `flutter analyze` reports no issues.
- `flutter test` passes.
- Sprint documentation and changelog are updated.
- Release version/tag is decided after completed scope is verified.
