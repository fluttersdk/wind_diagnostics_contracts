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

/// Process-global registry for the single active `WindDebugResolver`.
///
/// Wind installs its concrete resolver at app boot (gated by
/// `kDebugMode`); debug-tooling consumers look up the current
/// resolver via [current]. Never registered in release builds.
class WindDebugRegistry {
  WindDebugRegistry._();

  static WindDebugResolver? _resolver;

  /// Returns the registered resolver or `null` when wind has not
  /// installed one (release build, or `Wind.installDebugResolver()`
  /// was never called).
  static WindDebugResolver? get current => _resolver;

  /// Registers the resolver. Idempotent; the most recent call wins.
  ///
  /// Wind's `Wind.installDebugResolver()` is the canonical caller;
  /// tests may override via [registerForTesting].
  static void register(WindDebugResolver resolver) {
    _resolver = resolver;
  }

  /// Test-only reset. Drops the registered resolver.
  @visibleForTesting
  static void resetForTesting() {
    _resolver = null;
  }

  /// Test-only override. Reassigns the registered resolver to a
  /// test fake. Distinct from [register] to make test-only intent
  /// visible.
  @visibleForTesting
  static void registerForTesting(WindDebugResolver resolver) {
    _resolver = resolver;
  }
}
