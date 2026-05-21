# Changelog

All notable changes to this project will be documented in this file.

This project follows [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html). Entries follow the [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) shape.

---

## [Unreleased]

## [1.0.0] - 2026-05-21

Initial stable release. Neutral abstract contracts that let debug-tooling packages read Wind UI widget state at runtime without a compile-time dependency on `fluttersdk_wind`.

### Added

- **`WindDebugResolver` abstract class** (`lib/fluttersdk_wind_diagnostics_contracts.dart`): single-method interface `Map<String, Object?> resolve(Element element)`. Implementations live in `fluttersdk_wind` (production) and test fakes (debug-only). The returned map's key set is documented as the v1 frozen contract:
  - `className`: `String` (required when the widget is a W-prefixed widget with a non-empty `className`).
  - `breakpoint`: `String` (e.g. `'sm'`, `'md'`, `'lg'`).
  - `brightness`: `String` (`'light'` or `'dark'`).
  - `platform`: `String` (e.g. `'web'`, `'ios'`, `'android'`, `'macos'`).
  - `states`: `List<String>` (e.g. `['hover', 'focus']`).
  - `bgColor`: `String` hex (e.g. `'#3B82F6'`); present only when resolved.
  - `textColor`: `String` hex; present only when resolved.
  Implementations MUST return `const {}` for elements that are not Wind widgets, guaranteeing a graceful no-op for consumers walking arbitrary widget trees.

- **`WindDebugRegistry` static registry** (`lib/fluttersdk_wind_diagnostics_contracts.dart`): process-global single-slot registration for the active `WindDebugResolver`. Wind installs its concrete resolver at app boot (gated by `kDebugMode`) via `Wind.installDebugResolver()`; debug-tooling consumers look up the current resolver via `WindDebugRegistry.current`. The registry exposes:
  - `WindDebugRegistry.current` getter (returns `null` when no resolver is registered).
  - `WindDebugRegistry.register(resolver)` (canonical install path; idempotent, most-recent-call wins).
  - `WindDebugRegistry.resetForTesting()` and `WindDebugRegistry.registerForTesting(resolver)` (both `@visibleForTesting`; test-only seams).

- **6 contract tests** (`test/fluttersdk_wind_diagnostics_contracts_test.dart`): cover null-when-unregistered, register stores + lookup, idempotent register (last-wins), `resetForTesting` clears, `registerForTesting` overrides, and the contract assertion that resolver implementations return `const {}` for non-Wind elements.

- **GitHub Actions workflows** (`.github/workflows/ci.yml`, `.github/workflows/publish.yml`): CI runs `flutter pub get` + `dart format --set-exit-if-changed` + `dart analyze` + `flutter test --coverage` with an 80% line-coverage floor + `flutter pub publish --dry-run`. Publish runs on a SemVer tag push, validates, performs the OIDC publish to pub.dev, then creates a GitHub Release whose body is extracted from this CHANGELOG.

### Why this package

Wind UI exposes 6 widget-state fields (className, breakpoint, brightness, platform, states, bgColor, textColor) that debug-tooling packages such as [`fluttersdk_dusk`](https://github.com/fluttersdk/dusk) need to embed in their snapshot output. Shipping that handoff through `fluttersdk_wind`'s own surface would force every debug-tooling package to compile-time depend on Wind (heavy, transitively pulls Flutter's rendering surface), and would force Wind to compile-time depend on every debug-tooling package it wants to feed.

This package breaks the loop. Both sides depend on the abstract contract here; neither side imports the other. The pattern mirrors Flutter's `*_platform_interface` convention (4.97M downloads on `plugin_platform_interface` as the canonical precedent).
