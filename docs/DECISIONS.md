# Architecture Decision Log

## ADR-001 — Flutter for mobile

Flutter is used to support Android and iOS from a single codebase.

## ADR-002 — Android first

Development starts on Android because the current machine is Windows. iOS support will be validated later on macOS.

## ADR-003 — Guest-first onboarding

Users should be able to begin without creating an account. Local persistence will be added before Firebase authentication.

## ADR-004 — Feature-first folder structure

Features are isolated to reduce coupling and support future growth.

## ADR-005 — Incremental dependency adoption

Packages are added only when required by the current feature. This reduces build risk and makes debugging easier.

## ADR-006 — go_router for navigation

`go_router` is used for declarative navigation and future route guards.

## ADR-007 — User profile before nutrition calculations

Personalized calorie and macro targets require onboarding data, so onboarding is the next major feature after Sprint 1.
