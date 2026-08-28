# Sprint 8 Handoff — Smarter Food Tracking

## Starting point

Sprint 7 leaves Prana with a platform-aware health integration layer for weight and daily activity.

Nutrition targets remain stable and separate from wearable calorie estimates.

## Sprint 8 objective

Make food logging substantially faster and broader while keeping every AI/provider result editable and user controlled.

## Primary scope

### Food data abstraction

Introduce a provider/repository boundary so Prana is not coupled to one external food database.

The app should be able to combine:

- local/custom foods
- external catalog foods
- barcode matches
- recent foods
- favorites
- AI meal-photo suggestions

### Barcode capture

Support common UPC/EAN flows.

Expected interaction:

```text
Scan barcode
    |
    v
Resolve candidate food
    |
    v
Review serving + nutrition
    |
    v
User confirms or edits
    |
    v
Add to meal
```

A scan result must not be silently added without review.

### AI meal-photo confirmation

Photo recognition should produce editable suggestions rather than authoritative entries.

The confirmation experience should allow users to:

- remove incorrect foods
- add missing foods
- change serving size
- adjust quantity
- review calories/macros
- confirm before saving

### Custom foods

Users should be able to create and reuse foods that are missing from providers.

### Recents and favorites

Reduce repeated search effort by surfacing frequently/recently used foods.

### Regional coverage

Architecture should support regional and world foods instead of assuming one country's packaged-food catalog.

## Product rules carried forward

- daily nutrition targets generally stay stable
- workouts/activity remain separate from food intake
- do not automatically eat back all exercise calories
- AI suggestions are editable
- source/provider data should be explainable where practical
- users confirm meaningful food-log changes
- offline-first behavior should remain usable for existing local data

## Do not pull forward yet

Unless a genuine Sprint 8 dependency requires it:

- micronutrient deep dives belong to Sprint 9
- recipes and meal planning belong to Sprint 10
- workout tracking belongs to Sprint 11
- AI personal training belongs to Sprint 12
- adaptive readiness coaching belongs to Sprint 13
- social/community remains later

## Sprint 8 completion direction

Before release:

- search/provider architecture tested
- barcode path tested
- AI confirmation/edit path tested
- custom foods persist correctly
- meal totals remain correct
- existing nutrition and health behavior does not regress
- analyzer/tests/release build pass
