# Sprint 1 — App Foundation

## Sprint goal

Create a stable Flutter foundation for Prana with Android support, branded screens, navigation, and an initial dashboard shell.

## Completed

- Git repository and monorepo folder structure
- Flutter mobile application created
- Android emulator configured and verified
- Initial Android build completed
- Prana welcome screen created
- `go_router` added
- Navigation from welcome screen to dashboard
- Initial dashboard shell created
- Material 3 enabled
- Basic light theme established

## Current route flow

`/` → Welcome screen  
`/dashboard` → Dashboard shell

## Current repository structure

```text
Prana/
├── .git/
├── apps/
│   └── mobile/
├── assets/
├── backend/
├── docs/
└── packages/
```

## Acceptance criteria

Sprint 1 is complete when:

- The app launches on the Android emulator
- The Prana welcome screen is displayed
- Tapping Get Started opens the dashboard
- The dashboard shows placeholder health summary cards
- The project builds without Gradle errors
- The code is committed to Git

## Known limitations

- Dashboard values are placeholders
- No user profile yet
- No calorie or macro calculations yet
- No local persistence yet
- No Firebase configuration yet
- No authentication yet
- iOS cannot be built on the current Windows machine

## Recommended commit

```bash
git add .
git commit -m "feat: complete Sprint 1 app foundation"
```
