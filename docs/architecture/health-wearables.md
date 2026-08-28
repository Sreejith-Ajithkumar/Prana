# Health & Wearables Architecture

## Purpose

Prana's health integration is designed so Android Health Connect and Apple Health feed the same product domains without leaking platform-specific behavior throughout the app.

The integration is read-only in Sprint 7.

## High-level flow

```text
Presentation
    |
    +-- Today dashboard
    +-- Health & Wearables
            |
            v
Application/domain services
    |
    +-- HealthTodayActivityService
    +-- HealthWeightSyncService
            |
            v
Shared health repository interfaces
    |
    +-- HealthDataRepository
    +-- HealthWeightDataRepository
    +-- HealthActivityDataRepository
            |
            v
Platform-aware repository factory
    |
    +-- Android -> HealthConnectDataRepository
    +-- iOS     -> AppleHealthDataRepository
    +-- other   -> UnsupportedHealthDataRepository
            |
            v
Flutter health plugin / platform APIs
```

## Shared domain types

Initial health data types:

```text
bodyWeight
steps
activeEnergyBurned
workout
```

Platforms:

```text
appleHealth
healthConnect
unsupported
```

Access states:

```text
unknown
unavailable
notRequested
partiallyGranted
granted
denied
```

The access-state enum is shared, but platform adapters interpret it differently where the operating systems expose different information.

## Android Health Connect semantics

Health Connect supports explicit per-type permission checks.

Prana therefore evaluates requested categories independently and can represent:

- granted
- partially granted
- denied
- unavailable

Steps also require Android Activity Recognition permission.

The dashboard can show connected and disconnected activity categories independently.

## Apple Health semantics

HealthKit intentionally protects read-permission privacy. An app cannot reliably determine whether the user denied an individual read type.

Prana therefore does not map HealthKit read authorization to false per-type Connected / Not connected claims.

The Apple repository uses a small local authorization-state store to distinguish:

```text
notRequested -> authorization flow has not been reviewed

unknown -> authorization flow was reviewed; individual read choices remain private
```

After review, application services attempt reads and display only data Apple Health makes available.

## Health plugin boundary

`HealthPluginClient` wraps the Flutter `health` package.

This keeps plugin calls behind an injectable boundary for tests and prevents presentation code from depending directly on plugin APIs.

Mapped plugin types:

- weight -> `WEIGHT`
- steps -> `STEPS`
- active energy -> `ACTIVE_ENERGY_BURNED`
- workout -> `WORKOUT`

## Weight import architecture

Imported health weights become normal `WeightEntry` objects.

```text
HealthWeightSample
       |
       v
HealthWeightSyncService
       |
       v
WeightEntryStore / WeightStorage
       |
       +-- existing trend logic
       +-- existing goal progress
       +-- existing chart
       +-- existing recent pace
```

Platform identity is preserved:

```text
Health Connect
  id     = health-connect:<externalId>
  source = WeightSource.healthConnect

Apple Health
  id     = apple-health:<externalId>
  source = WeightSource.appleHealth
```

This prevents cross-platform ID collisions and avoids treating imported measurements as manual entries.

The sync service does not modify profile starting weight or nutrition targets.

## Activity architecture

Raw platform activity samples map to:

- `HealthStepsSample`
- `HealthActiveEnergySample`
- `HealthWorkoutSample`

`HealthDailyActivitySummaryService` deduplicates and summarizes them into:

- steps
- active energy kcal
- workout count
- workout duration

`HealthTodayActivityService` selects the local calendar-day window and reads only categories that can be attempted under the active platform's permission semantics.

## Workout mapping

The shared workout kind model currently normalizes supported plugin workout types into:

- walking
- running
- cycling
- swimming
- strength training
- other

Detailed workout tracking belongs to later workout sprints.

## Presentation rules

### Android

The Health & Wearables UI can use explicit Health Connect permission language such as:

- Connected
- Some access granted
- Access needed
- Manage access

The Today dashboard can show per-metric Connected / Not connected states.

### iOS

The UI uses privacy-correct language such as:

- Access not requested
- Access reviewed
- Review Apple Health access

The UI does not claim individual read categories are connected.

## Nutrition separation

Health activity never directly changes the nutrition target in Sprint 7.

Active energy is displayed as context only.

Future adaptive nutrition behavior must be a separate explicit policy with guardrails rather than a hidden consequence of wearable calorie estimates.

## Platform configuration

### Android

- minimum SDK 26
- compile SDK 36
- read-only Health Connect permissions
- Activity Recognition for steps
- Health Connect settings launcher via Android method channel

### iOS

- iOS 15.0 minimum deployment target
- HealthKit entitlement
- `NSHealthShareUsageDescription`
- read-only integration
- final build/signing/device validation pending macOS/Xcode

## Known dependency warning

The `health` Flutter plugin currently applies the legacy Kotlin Gradle Plugin.

Flutter still builds Prana successfully, but future Flutter releases may remove compatibility support. Recheck the plugin migration status before upgrading Flutter/AGP.
