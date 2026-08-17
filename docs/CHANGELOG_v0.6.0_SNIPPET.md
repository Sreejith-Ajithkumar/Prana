## v0.6.0 — Weight & Progress

### Added

- Historical weight logging and local persistence.
- Weight measurement source model for manual, Apple Health, Health Connect, smart scale, and unknown sources.
- Multi-day weight trend using the latest measurement from each calendar day.
- Goal-direction progress for weight loss, weight gain, and maintenance.
- Progress percentage, remaining weight, and goal-reached states.
- Dependency-free weight history/trend chart.
- Persistent weekly goal pace.
- Estimated target date with calendar-day/DST-safe calculation.
- Recent actual weight pace using a minimum-history gate and linear regression.
- Planned-vs-recent pace comparison.
- Swipeable Today ↔ Progress dashboard navigation.
- Independent scroll-position retention for Today and Progress.
- Embedded Progress experience with Log Weight.

### Changed

- Progress is now a first-class dashboard experience instead of being hidden behind Profile.
- Profile no longer contains a redundant Weight & Progress navigation card.
- Weight progress uses latest measurement until a reliable trend becomes available, then uses trend weight.
- Distant goal weight no longer distorts the recent chart scale.

### Product behavior

- Starting weight remains a historical baseline.
- New weigh-ins do not automatically overwrite the starting/reference weight.
- Recent pace does not automatically change nutrition targets.
- Goal pace and target dates are planning tools, not guaranteed outcomes.
- Short-term weight changes are not extrapolated into a weekly pace until sufficient history exists.

### Validation

- Sprint 6 development reached 69 passing automated tests before final release packaging.
- Today ↔ Progress navigation passed manual acceptance testing.
- Final format/analyze/test release gate must be recorded on the final v0.6.0 commit before tagging.
