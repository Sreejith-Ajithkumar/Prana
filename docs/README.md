# Prana v0.7.0 Documentation Package

This documentation set covers Sprint 7 — Health & Wearables and the `v0.7.0` internal release preparation.

## Included

- `docs/sprints/sprint_07/SPRINT_07.md`
- `docs/architecture/health-wearables.md`
- `docs/releases/v0.7.0.md`
- `docs/sprints/sprint_07/sprint-08-handoff.md`
- `docs/CHANGELOG.md`
- `docs/RELEASE_V0.7.0_CHECKLIST.md`

Existing Sprint 6 and earlier documentation remains in place.

## Current release status

Latest known Sprint 7 development validation:

```text
flutter analyze: no issues found
flutter test: 144 tests passed
flutter build apk --release: successful
Android release APK: 51.0 MB
```

Android Health Connect has received real-device connection/settings validation.

Apple Health architecture and iOS HealthKit project configuration are implemented, but final iOS build/signing/physical-device validation remains pending macOS/Xcode access.

## Important release rule

Do not create `v0.7.0` until:

- documentation is committed
- working tree is clean
- final analyzer/tests pass
- the release commit is selected
- known Health plugin KGP warning is documented
- iOS validation status is accurately marked pending

After tagging, use the existing safe release script to build the exact tag and generate the SHA256 artifact.
