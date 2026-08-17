# Prana v0.6.0 Release Checklist

## 1. Confirm clean feature branch

```powershell
cd D:\Development\Projects\Prana
git status --short
git log -5 --oneline
```

## 2. Add Sprint 6 documentation

Copy the new Markdown files into the repository. Merge `docs/CHANGELOG_v0.6.0_SNIPPET.md` into the existing `docs/CHANGELOG.md`; do not overwrite previous changelog history.

## 3. Validate mobile app

```powershell
cd D:\Development\Projects\Prana\apps\mobile

dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Release gate:
- formatting: 0 changed
- analyzer: no issues
- tests: all pass

## 4. Commit documentation

```powershell
cd D:\Development\Projects\Prana

git status
git add docs RELEASE_V0.6.0_CHECKLIST.md
git commit -m "docs: complete sprint 6 and v0.6.0 release notes"
git push
git status --short
```

## 5. Merge to the repository's release branch

Use the same release-branch workflow used for prior Prana releases. Do not create the tag until Sprint 6 code and documentation are on the intended release commit and the release gate passes there.

## 6. Run final release gate after merge

```powershell
cd D:\Development\Projects\Prana\apps\mobile

dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test

cd D:\Development\Projects\Prana
git status --short
```

## 7. Tag v0.6.0

```powershell
git tag -a v0.6.0 -m "Prana v0.6.0 - Weight & Progress"
git push origin v0.6.0
```

Verify:

```powershell
git tag --list v0.6.0
git show --stat --oneline v0.6.0
```

## 8. Build v0.6.0 using the existing safe release script

From repository root:

```powershell
cd D:\Development\Projects\Prana

powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\build_releases.ps1 -Tag v0.6.0
```

The existing script is preferred because it builds the requested tag in a temporary detached worktree, runs dependency resolution, analyzer/tests, builds the release APK, writes SHA256 output, and does not disturb the current development branch.

## 9. Expected release artifacts

```text
dist/Prana-v0.6.0.apk
dist/Prana-v0.6.0.sha256.txt
```

If you continue the current internal convention, these may then be copied/moved into `releases/`.

## 10. Begin Sprint 7

Sprint 7 — Health & Wearables.
