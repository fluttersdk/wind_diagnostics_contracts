/// Pure abstract contracts for Wind UI diagnostic introspection.
///
/// Wind UI exposes its runtime widget state (className, breakpoint,
/// brightness, platform, states, bgColor, textColor) at snapshot time
/// via a `WindDebugResolver` implementation. Debug-tooling packages
/// (e.g., fluttersdk_dusk for E2E snapshots, future devtools-aware
/// inspectors) consume that state through `WindDebugRegistry.current`
/// without ever importing wind types directly.
///
/// Neither wind nor consumers of this contract package compile-time
/// depend on each other; this package is the neutral bridge.
library;

import 'package:flutter/widgets.dart' show Element;
import 'package:meta/meta.dart';

/// Resolves runtime Wind widget state for a given Element.
///
/// Implementations live in `fluttersdk_wind` (production) and test
/// fakes (debug-only). Consumers receive a Map and never need to
/// understand wind's internal types.
///
/// Frozen contract for the 1.0.0 line; additive changes only (new
/// keys in the returned Map allowed; renaming or removing existing
/// keys requires a major bump).
abstract class WindDebugResolver {
  /// Returns a Map of resolved Wind state for the given element.
  ///
  /// Implementations MUST return `const {}` for elements that are
  /// not Wind widgets, guaranteeing a graceful no-op for consumers
  /// walking arbitrary trees. The returned Map's key set is
  /// documented in the v1 contract:
  /// - `className`: String (required when widget is a W-widget with a className)
  /// - `breakpoint`: String (e.g., 'sm', 'md', 'lg')
  /// - `brightness`: String ('light' | 'dark')
  /// - `platform`: String (e.g., 'web', 'ios', 'android', 'macos')
  /// - `states`: `List<String>` (e.g., ['hover', 'focus'])
  /// - `bgColor`: String (hex, e.g., '#3B82F6'), present only when resolved
  /// - `textColor`: String (hex), present only when resolved
  Map<String, Object?> resolve(Element element);
}

/// Resolves aggregate Wind runtime performance statistics.
///
/// Implementations live in `fluttersdk_wind` (production) and test
/// fakes (debug-only). This is a SECOND, separate contract from
/// [WindDebugResolver]: that one resolves per-Element widget state,
/// this one resolves process-wide counters that have no single
/// Element to attach to (cache hits/misses/bypasses, build counts).
///
/// Frozen contract for the 1.x line; additive changes only (new keys
/// in the returned Map allowed; renaming or removing existing keys
/// requires a major bump).
abstract class WindPerfResolver {
  /// Returns a Map of aggregate Wind performance counters.
  ///
  /// The returned Map's key set is documented as the cross-repo
  /// contract read by `fluttersdk_dusk`'s performance snapshot:
  /// - `cacheHits`: `int`
  /// - `cacheMisses`: `int`
  /// - `cacheBypasses`: `int`
  /// - `cacheSize`: `int`
  /// - `wDivBuilds`: `int`
  /// - `wTextBuilds`: `int`
  Map<String, Object?> stats();
}

/// Process-global registry for the single active `WindDebugResolver`
/// and the single active `WindPerfResolver`.
///
/// Wind installs its concrete resolvers at app boot (gated by
/// `kDebugMode`); debug-tooling consumers look up the current
/// resolver via [current] / [currentPerf]. Never registered in
/// release builds.
class WindDebugRegistry {
  // Unreachable from a test by design: a private constructor whose only job is
  // to stop this static-only registry being instantiated.
  WindDebugRegistry._(); // coverage:ignore-line

  static WindDebugResolver? _resolver;
  static WindPerfResolver? _perfResolver;

  /// Returns the registered resolver or `null` when wind has not
  /// installed one (release build, or `Wind.installDebugResolver()`
  /// was never called).
  static WindDebugResolver? get current => _resolver;

  /// Returns the registered perf resolver or `null` when wind has
  /// not installed one (release build, or the perf resolver was
  /// never registered).
  static WindPerfResolver? get currentPerf => _perfResolver;

  /// Registers the resolver. Idempotent; the most recent call wins.
  ///
  /// Wind's `Wind.installDebugResolver()` is the canonical caller;
  /// tests may override via [registerForTesting].
  static void register(WindDebugResolver resolver) {
    _resolver = resolver;
  }

  /// Registers the perf resolver. Idempotent; the most recent call
  /// wins. Mirrors [register] but occupies a distinct slot so
  /// registering one never overwrites the other.
  static void registerPerf(WindPerfResolver resolver) {
    _perfResolver = resolver;
  }

  /// Test-only reset. Drops both the registered resolver and the
  /// registered perf resolver.
  @visibleForTesting
  static void resetForTesting() {
    _resolver = null;
    _perfResolver = null;
  }

  /// Test-only override. Reassigns the registered resolver to a
  /// test fake. Distinct from [register] to make test-only intent
  /// visible.
  @visibleForTesting
  static void registerForTesting(WindDebugResolver resolver) {
    _resolver = resolver;
  }
}
