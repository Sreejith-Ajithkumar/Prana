# Architecture

## Technology

- Flutter
- Dart
- Material 3
- go_router
- Android first
- iOS supported later from macOS

## Architecture direction

Prana uses a feature-first structure with clean separation between presentation, domain, and data layers as the app grows.

```text
lib/
├── app/
│   ├── app.dart
│   └── router.dart
├── core/
│   ├── constants/
│   ├── services/
│   ├── theme/
│   ├── utils/
│   └── widgets/
├── features/
│   ├── splash/
│   ├── dashboard/
│   ├── onboarding/
│   ├── profile/
│   ├── meals/
│   ├── activity/
│   └── coach/
└── main.dart
```

## Layer responsibilities

### Presentation

Screens, widgets, UI state, and navigation.

### Domain

Entities, enums, business rules, and use cases.

### Data

Local storage, Firebase, APIs, repositories, and DTO mapping.

## Important rule

Business models such as `UserProfile` belong in the domain layer, not directly inside a screen.
