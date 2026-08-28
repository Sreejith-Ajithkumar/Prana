# Sprint 7 — Health & Wearables

## Status

Release preparation in progress.

## Branch

`feature/health-wearables`

## Objective

Add a platform-aware, read-only health integration layer so Prana can use approved weight and activity data from Android Health Connect and Apple Health without coupling the product to either platform.

Sprint 7 extends the existing offline-first weight and dashboard domains instead of creating a separate wearable-only system.

## Delivered scope

### Shared health domain

Prana now has platform-independent health types for:

- body weight
- steps
- active energy
- workouts

Supported platforms:

- Android Health Connect
- Apple Health / HealthKit
- unsupported fallback for other platforms

The domain keeps platform details behind repository interfaces so presentation and application services can consume the same models on Android and iOS.

### Android Health Connect

Implemented:

- Health Connect availability checks
- read-only permissions
- activity-recognition permission handling for steps
- Health Connect settings launcher
- body-weight reads
- steps reads
- active-energy reads
- workout reads
- per-category permission checks
- partial-access handling
- Health & Wearables connection UI
- Today activity dashboard
- 30-day weight synchronization
- deterministic Health Connect weight IDs and deduplication

Android permissions remain intentionally narrow. Prana requests read access only for the data currently used by the product.

### Apple Health / HealthKit

Implemented in shared Dart/iOS project configuration:

- HealthKit entitlement
- `NSHealthShareUsageDescription`
- iOS deployment target 15.0
- Apple Health repository
- body-weight reads
- steps reads
- active-energy reads
- workout reads
- platform-aware repository factory
- Apple-specific authorization-state handling
- Apple-specific dashboard copy
- Apple-specific Health & Wearables copy
- Apple-specific weight IDs and weight source values

HealthKit read authorization uses privacy-correct semantics. Apple does not expose whether individual read permissions were granted or denied. After the authorization sheet has been reviewed, Prana records the state as reviewed/unknown and attempts reads instead of falsely claiming per-type permission status.

Final iOS build, signing, HealthKit authorization, and physical-device validation still require macOS/Xcode and are not claimed as completed in Sprint 7.

### Weight synchronization

Health weight imports flow into the existing `WeightEntry` domain.

Health Connect records use:

```text
health-connect:<externalId>
WeightSource.healthConnect
```

Apple Health records use:

```text
apple-health:<externalId>
WeightSource.appleHealth
```

Sync behavior:

- default lookback is 30 days
- invalid samples are skipped
- duplicate external IDs are deduplicated
- unchanged re-syncs do not create duplicates
- changed records with the same platform/external ID update the imported entry
- manual weight entries are preserved
- Health Connect and Apple Health IDs remain distinct
- profile starting weight is not overwritten
- nutrition targets are not recalculated by sync

### Today activity dashboard

Today can display:

- steps
- active energy
- workout count
- workout duration

Android supports partial-permission presentation:

- connected metrics remain visible
- unavailable metrics are shown as not connected
- users can manage Health Connect access

Apple Health does not show false per-metric Connected / Not connected labels. Prana displays only the activity data Apple Health makes available.

Active energy is informational only and does not alter the daily nutrition target.

## Product and privacy rules

Sprint 7 preserves these rules:

- health integration is read-only
- users control permissions
- imported activity calories are not automatically added back to the food budget
- wearable/device estimates are treated as signals rather than exact truth
- Prana does not use health data to make medical diagnoses
- one activity or weight sample does not silently change nutrition targets
- manual weight history remains valid alongside imported measurements

## Android configuration

Current Android choices:

- `minSdk = 26`
- `compileSdk = 36`
- `permission_handler = ^12.0.3`
- `health = ^13.3.2`

`permission_handler` remains on 12.0.3 to preserve compileSdk 36 / AGP compatibility rather than raising compileSdk solely for a plugin major version.

## iOS configuration

Current iOS choices:

- deployment target: iOS 15.0
- HealthKit entitlement enabled
- `NSHealthShareUsageDescription` present
- app display name: Prana
- read-only HealthKit integration
- no HealthKit write permission behavior

The current bundle identifier remains development-oriented and must be replaced with Prana's permanent production identifier before TestFlight/App Store setup.

## Validation

Latest Windows/Android development gate:

```text
flutter analyze: no issues found
flutter test: 144 tests passed
flutter build apk --release: successful
release APK size: 51.0 MB
```

Android release build completed successfully.

### Android physical-device validation completed

Confirmed on a real Android device:

- Health Connect detected
- Prana appears in Health Connect app access
- connection state works
- Review access works
- Manage access opens Health Connect settings
- weight sync query executes
- empty weight-data result is handled correctly

### Android physical-device validation still desirable

A controlled record test with Health Connect Toolbox remains useful when suitable hardware is available:

1. add a known weight measurement
2. verify it in Health Connect
3. sync in Prana
4. confirm import in Progress
5. sync again
6. confirm deduplication

Controlled activity-record validation is also still desirable.

These are validation follow-ups rather than blockers for continued development.

### iOS validation pending

Requires macOS/Xcode and a real/suitable iOS environment:

- Xcode project build
- signing/capability validation
- HealthKit authorization sheet
- Apple Health weight read
- Apple Health steps read
- Apple Health active-energy read
- Apple Health workout read
- weight import/deduplication
- Today dashboard activity display
- authorization-copy review on device

## Known build warning

The `health` Flutter plugin still applies the legacy Kotlin Gradle Plugin.

Current Flutter/Android release builds succeed because Flutter still provides compatibility support.

Before a future Flutter/AGP upgrade, recheck whether the plugin has migrated to Flutter Built-in Kotlin. Do not rewrite Prana's Gradle configuration merely to silence the current warning.

## Key Sprint 7 checkpoints

Representative commits include:

- `c93f54a` — add health plugin type mapping
- `53ae33f` — add Health Connect permission repository
- `41e487a` — add Health & Wearables screen
- `1e893d3` — add Health Connect weight sync foundation
- `3894c4b` — add health activity domain foundation
- `a63be16` — map Health Connect activity data
- `b8f908b` — add today health activity service
- `ee6d37e` — add today health activity dashboard
- `1b1cbdd` — support partial Health Connect activity access
- `99f851b` — configure iOS HealthKit support
- `6871efc` — add Apple Health data repository
- `fa80751` — add Apple Health activity dashboard support
- `19806e7` — generalize health weight sync
- `6a08a27` — add platform-aware health connections UI

## Completion gate

Before tagging `v0.7.0`:

- documentation committed
- working tree clean
- formatting check passes
- analyzer reports no issues
- all tests pass
- Android release APK builds successfully
- known KGP warning documented
- iOS validation explicitly marked pending
- final release commit selected
- tag created only after the gate passes
