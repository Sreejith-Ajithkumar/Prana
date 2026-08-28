# Prana v0.7.0 Release Checklist

## 1. Confirm clean Sprint 7 branch

```powershell
cd D:\Development\Projects\Prana

git status --short
git log -8 --oneline
```

Working tree must be clean before the final release workflow.

## 2. Add Sprint 7 documentation

Add/update:

```text
docs/CHANGELOG.md
docs/README.md
docs/architecture/health-wearables.md
docs/releases/v0.7.0.md
docs/sprints/sprint_07/SPRINT_07.md
docs/sprints/sprint_07/sprint-08-handoff.md
docs/RELEASE_V0.7.0_CHECKLIST.md
```

Before the documentation commit, replace the v0.7.0 changelog date placeholder if the release date is known.

## 3. Review Sprint 7 platform status

Android must be documented as implemented and release-build validated.

iOS must be documented accurately:

```text
HealthKit architecture/configuration implemented
macOS/Xcode build and physical-device validation pending
```

Do not mark iOS signing/device validation complete until it has actually been performed.

## 4. Confirm dependency/platform decisions

Record:

```text
Android minSdk: 26
Android compileSdk: 36
health: ^13.3.2
permission_handler: ^12.0.3
iOS deployment target: 15.0
```

Also confirm the known `health` KGP warning remains documented.

## 5. Run final mobile gate on the release commit

From the mobile app:

```powershell
cd D:\Development\Projects\Prana\apps\mobile

dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --release
```

Expected current baseline:

```text
Formatting: 0 changed
Analyzer:   no issues found
Tests:      144 passed
APK build:  successful
```

The `health` plugin legacy Kotlin Gradle Plugin warning is currently known and non-blocking because the release APK still builds successfully.

## 6. Confirm release APK exists

```powershell
Get-Item `
  .\build\app\outputs\flutter-apk\app-release.apk |
  Select-Object FullName, Length, LastWriteTime
```

The latest manual Sprint 7 release build was approximately 51.0 MB.

## 7. Commit documentation

```powershell
cd D:\Development\Projects\Prana

git status --short

git add `
  docs\CHANGELOG.md `
  docs\README.md `
  docs\architecture\health-wearables.md `
  docs\releases\v0.7.0.md `
  docs\sprints\sprint_07\SPRINT_07.md `
  docs\sprints\sprint_07\sprint-08-handoff.md `
  docs\RELEASE_V0.7.0_CHECKLIST.md

git diff --cached --check
git diff --cached --stat

git commit -m "docs: complete sprint 7 and v0.7.0 release notes"
git push

git status --short
```

## 8. Run the release gate again after the documentation commit

```powershell
cd D:\Development\Projects\Prana\apps\mobile

dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test

cd D:\Development\Projects\Prana
git status --short
```

If documentation-only changes were made after the successful APK build, the safe tagged release script will perform analyzer/tests/build again from the exact tag.

## 9. Select the final release commit

```powershell
git log -5 --oneline
git status --short
```

Verify:

- intended Sprint 7 code is present
- Sprint 7 documentation is present
- working tree is clean
- no unrelated files are staged
- `v0.7.0` does not already exist

```powershell
git tag --list v0.7.0
```

## 10. Tag v0.7.0

Only after all previous gates pass:

```powershell
git tag -a v0.7.0 -m "Prana v0.7.0 - Health & Wearables"
git push origin v0.7.0
```

Verify:

```powershell
git tag --list v0.7.0
git show --stat --oneline v0.7.0
```

## 11. Build the exact tag with the safe release script

From repository root:

```powershell
cd D:\Development\Projects\Prana

powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File .\scripts\build_releases.ps1 `
  -Tag v0.7.0
```

The script builds from a temporary detached worktree, runs dependency resolution, analyzer, tests, release APK build, and SHA256 generation without disturbing the current branch.

Expected artifacts:

```text
dist/Prana-v0.7.0.apk
dist/Prana-v0.7.0.sha256.txt
```

## 12. Verify release hash

```powershell
Get-Content .\dist\Prana-v0.7.0.sha256.txt

Get-FileHash `
  .\dist\Prana-v0.7.0.apk `
  -Algorithm SHA256
```

The hashes must match.

## 13. Copy internal release artifacts if desired

If continuing the current internal convention:

```powershell
Copy-Item `
  .\dist\Prana-v0.7.0.apk `
  .\releases\Prana-v0.7.0.apk

Copy-Item `
  .\dist\Prana-v0.7.0.sha256.txt `
  .\releases\Prana-v0.7.0.sha256.txt
```

`dist/` and release binaries remain ignored by Git under the existing repository policy.

## 14. Record pending iOS validation

Do not lose these follow-ups after the Android/internal tag:

- choose permanent production bundle identifier
- open project on macOS/Xcode
- verify HealthKit capability/signing
- build iOS target
- test authorization on iPhone
- test Apple Health weight import/deduplication
- test steps/active energy/workouts
- validate Apple-specific dashboard and connection copy

## 15. Begin Sprint 8

Sprint 8 — Smarter Food Tracking.
