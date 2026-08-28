# Changelog

## [0.7.0] - Unreleased

### Added

- Platform-independent health-data repository architecture.
- Android Health Connect integration for body weight, steps, active energy, and workouts.
- Apple Health / HealthKit repository foundation for the same shared health types.
- Platform-aware Health & Wearables screen.
- Platform-aware Today activity dashboard.
- Read-only health access model with user-controlled permissions.
- Android partial Health Connect activity access.
- 30-day health weight synchronization.
- Deterministic platform-specific imported weight IDs.
- Health weight deduplication and update behavior.
- Apple Health-specific weight source handling.
- iOS HealthKit entitlement and HealthKit read-purpose description.
- Apple Health authorization-state persistence for privacy-correct read semantics.

### Improved

- Profile health navigation is platform neutral.
- Health integrations now feed the existing weight-progress domain rather than a parallel wearable-only model.
- Today activity refreshes alongside existing dashboard data.
- Android connected/disconnected activity metrics remain useful when only some Health Connect permissions are granted.
- Apple Health UI avoids false per-metric Connected / Not connected claims.
- Weight re-sync preserves manual measurements and avoids duplicate imported entries.

### Product behavior

- Health integration remains read-only.
- Activity calories remain separate from nutrition targets.
- Prana does not automatically eat back wearable exercise calories.
- Imported weights do not overwrite the profile starting-weight baseline.
- Health sync does not silently recalculate nutrition targets.
- Wearable/device values are treated as signals rather than medical diagnoses or exact truth.

### Platform notes

- Android minimum SDK is 26.
- Android compile SDK remains 36.
- `permission_handler` is pinned to `^12.0.3` for current compileSdk/AGP compatibility.
- iOS deployment target is 15.0.
- Final iOS build, signing, and physical-device HealthKit validation require macOS/Xcode and remain pending.

### Quality

- `flutter analyze`: no issues found at the latest Sprint 7 gate.
- `flutter test`: 144 tests passed.
- `flutter build apk --release`: successful.
- Latest manual release APK build size: 51.0 MB.
- Android Health Connect connection/settings flow validated on a real device.

### Known issues / technical debt

- The `health` Flutter plugin still applies the legacy Kotlin Gradle Plugin.
- Current Android builds succeed through Flutter compatibility support.
- Recheck Built-in Kotlin migration before a future Flutter/AGP upgrade.
- Controlled Health Connect Toolbox import/deduplication and activity-record device validation remain follow-up checks.
- Apple Health physical-device validation is pending macOS/Xcode access.
- Production iOS bundle identifier is not finalized.

## [0.6.0] - 2026-08-17
### Added
- Historical weight logging and local persistence.
- Weight measurement source model for manual, Apple Health, Health Connect, smart scale, and unknown sources.
- Multi-day weight trend using the latest measurement from each calendar day.
- Goal-direction progress for weight loss, weight gain, and maintenance.
- Progress percentage, remaining weight, and goal-reached states.
- Dependency-free weight history and trend chart.
- Persistent weekly goal pace.
- Estimated target date with calendar-day and DST-safe calculation.
- Recent actual weight pace using minimum-history guardrails and linear regression.
- Planned-versus-recent pace comparison.
- Swipeable Today and Progress dashboard navigation.
- Independent scroll-position retention for Today and Progress.
- Embedded Progress experience with Log Weight.
### Improved
- Progress is now directly accessible from the main dashboard instead of being hidden behind Profile.
- Profile no longer contains a redundant Weight & Progress navigation card.
- Weight progress uses the latest measurement until a reliable trend becomes available, then uses trend weight.
- Distant goal weights no longer distort the recent chart scale.
- Short-term weight changes are not extrapolated into a weekly pace until sufficient history exists.
### Product behavior
- Starting weight remains a historical baseline.
- New weigh-ins do not automatically overwrite starting weight.
- Recent pace does not automatically change nutrition targets.
- Goal pace and target dates remain user-controlled planning tools.
- Target dates are estimates rather than guaranteed outcomes.
### Quality
- 69 automated tests passing before final release packaging.
- Today and Progress navigation manually validated across the Sprint 6 acceptance flow.
- Final release gate required before tagging v0.6.0.

### Deferred
Apple Health, Health Connect, wearable synchronization, smart-scale ingestion, and controlled nutrition-reference adaptation are planned for later sprints.

## [0.5.0] - 2026-08-12
### Added
- Personalized calorie, protein, carbohydrate, fat, and hydration targets.
- Profile screen and Edit Profile & Goals flow.
- Persistent daily water tracking.
- Animated dashboard values and progress indicators.
- Progress states: On track, Approaching target, Target reached, and Above target.
- Responsive dashboard metric layout.
### Improved
- Safer weight-loss calorie targeting for lower-TDEE profiles.
- Nutrition Engine integration with the dashboard.
- Meal totals/editing and hydration progress presentation.
- Reduced-motion accessibility behavior.

### Quality
- 73 files formatting checked with 0 changes.
- `flutter analyze`: no issues found.
- `flutter test`: 41 tests passed.
- Release tagged as `v0.5.0`.
### Deferred
Weight history/trends, goal pace, progress history, wearables, smarter food capture, advanced nutrition, recipes, workouts, and AI coaching are planned for later sprints.
