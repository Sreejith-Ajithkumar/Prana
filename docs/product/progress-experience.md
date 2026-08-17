# Progress Experience

## Product goal

Progress should be easy to find, calm to interpret, and resistant to overreacting to short-term changes.

Users should not need to enter Profile to understand whether they are moving toward their goal.

## Main navigation

The Prana dashboard now exposes:

```text
Today | Progress
```

Users can tap either tab or swipe horizontally between them.

The tab treatment is intentionally lightweight and uses an underline-style selector.

## Today

Today remains the daily behavior view:

- greeting
- health summary
- goal
- calories
- protein
- water
- carbohydrates
- fat
- today's meals
- Add Meal

Scroll position is preserved when switching away and returning.

## Progress

Progress is the long-term outcome view:

- starting weight
- latest weight
- goal weight
- change from start
- distance to goal
- goal progress
- weight trend
- goal pace
- estimated target date
- recent pace
- weight history chart
- measurement history
- Log Weight

Progress also preserves its scroll position.

## Why Progress is not in Profile

Profile should primarily contain identity, personal information, goal settings, activity level, and editable inputs.

Progress is a frequently revisited outcome. Requiring `Home → Profile → Weight & Progress` adds unnecessary friction, so the redundant Profile navigation card was removed.

The standalone `/weight` route remains available for deep links and future internal navigation.

## Weight language

The UI distinguishes:

**Starting weight** — baseline captured from profile/onboarding.  
**Latest weight** — most recent historical measurement.  
**Weight trend** — smoothed recent signal.  
**Goal weight** — selected target.

These should not be collapsed into one generic current-weight value.

## Trend messaging

Before enough history exists:
- show that more data is needed
- explain the measurement-day requirement
- avoid pretending a robust trend exists

After a reliable trend exists:
- use the trend for progress
- explain that day-to-day noise is being smoothed

## Goal progress messaging

Directional goals show percentage complete, kilograms progressed, kilograms remaining, and start/goal values.

If moving away from goal:
- do not show negative progress percentage
- explain calmly
- do not punish the user

If goal reached:
- cap visual progress at 100%
- show a goal-reached state

Maintenance:
- avoid directional percentage
- focus on closeness to target

## Goal pace

Goal pace is user controlled. Changing it changes the planning estimate but does not silently alter nutrition targets.

## Estimated target date

The target date is explicitly a planning estimate. It can move as selected pace or current progress weight changes and is not a guaranteed outcome.

## Recent pace

Recent pace is withheld until at least 3 measurement days and 14 days of history are available.

Before readiness:
- `More data needed`

After readiness:
- planned pace
- recent pace
- comparison state

Possible states:
- close to plan
- slower than plan
- faster than plan
- moving away from goal

The comparison is neutral and informational rather than judgmental.

## Product principles

Prana should:
- treat weight as a noisy signal
- prefer trends over isolated weigh-ins
- make estimates explainable
- preserve user control
- avoid automatic aggressive adjustments
- avoid medical claims

Prana should not:
- automatically eat back all exercise calories
- punish tomorrow for today's intake
- recalculate nutrition targets from every weigh-in
- imply a target date is guaranteed
- diagnose health status from recent weight pace
- silently overwrite the user's starting baseline

## Future expansion

Progress may later include activity trends, wearable health data, workouts, training volume, personal records, running/cycling/swimming performance, readiness, achievements, and streaks/challenges.
