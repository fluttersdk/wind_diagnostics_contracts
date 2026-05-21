<p align="center">
  <img src="https://raw.githubusercontent.com/fluttersdk/wind/v1/.github/wind-logo.svg" width="120" alt="Wind Diagnostics Contracts Logo" />
</p>

<h1 align="center">Wind Diagnostics Contracts</h1>

<p align="center">
  <strong>Neutral abstract contracts that let debug-tooling packages read Wind UI widget state without coupling to fluttersdk_wind.</strong><br/>
  Abstract resolver interface plus process-global registry. Tiny, frozen v1 contract, ~80 LoC.
</p>

<p align="center">
  <a href="https://pub.dev/packages/fluttersdk_wind_diagnostics_contracts"><img src="https://img.shields.io/pub/v/fluttersdk_wind_diagnostics_contracts.svg" alt="pub package"></a>
  <a href="https://github.com/fluttersdk/wind_diagnostics_contracts/actions"><img src="https://img.shields.io/github/actions/workflow/status/fluttersdk/wind_diagnostics_contracts/ci.yml?branch=develop&label=CI" alt="CI"></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT"></a>
  <a href="https://pub.dev/packages/fluttersdk_wind_diagnostics_contracts/score"><img src="https://img.shields.io/pub/points/fluttersdk_wind_diagnostics_contracts" alt="pub points"></a>
  <a href="https://github.com/fluttersdk/wind_diagnostics_contracts/stargazers"><img src="https://img.shields.io/github/stars/fluttersdk/wind_diagnostics_contracts?style=flat" alt="GitHub stars"></a>
</p>

<p align="center">
  <a href="https://fluttersdk.com/wind">Documentation</a> ·
  <a href="https://pub.dev/packages/fluttersdk_wind_diagnostics_contracts">pub.dev</a> ·
  <a href="https://github.com/fluttersdk/wind_diagnostics_contracts/issues">Issues</a>
</p>

---

## Why this package exists

[Wind UI](https://github.com/fluttersdk/wind) exposes runtime widget state (`className`, `breakpoint`, `brightness`, `platform`, `states`, `bgColor`, `textColor`) that debug-tooling packages such as [`fluttersdk_dusk`](https://github.com/fluttersdk/dusk) embed in their snapshot YAML so LLM agents can reason about the rendered tree.

Shipping that handoff through `fluttersdk_wind`'s own surface would force every debug-tool to compile-time depend on Wind, dragging the full rendering surface and bumping debug-tool builds on every Wind release. Shipping it the other way (Wind depending on each debug tool) is even worse.

**This package breaks the loop.** Both sides depend on the abstract contract here; neither side imports the other.

```
                    fluttersdk_wind_diagnostics_contracts
                              |
              +---------------+---------------+
              |                               |
       fluttersdk_wind                  fluttersdk_dusk
       (registers a resolver)         (reads the resolver
                                       at snapshot time)
```

The pattern mirrors Flutter's `*_platform_interface` convention. `plugin_platform_interface` (the canonical precedent) sits at 4.97M downloads on pub.dev for exactly this reason.

---

## Install

```bash
flutter pub add fluttersdk_wind_diagnostics_contracts
```

Most consumers never add this dep by hand. `fluttersdk_wind` declares it as a direct production dependency, so any app that already depends on Wind picks it up transitively. Add it explicitly when you are authoring a debug-tooling package that reads Wind state without depending on Wind itself.

---

## Usage

### Registering a resolver (in `fluttersdk_wind`)

Wind installs its concrete resolver at app boot, gated by `kDebugMode` so release builds tree-shake the entire registration site:

```dart
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:fluttersdk_wind/fluttersdk_wind.dart';

void main() {
  if (kDebugMode) {
    Wind.installDebugResolver();
  }
  runApp(const MyApp());
}
```

`Wind.installDebugResolver()` is a one-liner inside `fluttersdk_wind` that does:

```dart
import 'package:fluttersdk_wind_diagnostics_contracts/fluttersdk_wind_diagnostics_contracts.dart';

WindDebugRegistry.register(const WindDebugResolverImpl());
```

### Reading the resolver (in a debug-tooling package)

The consumer looks up the currently-installed resolver and calls `resolve(element)` per `Element` it wants to inspect. The resolver returns `const {}` for non-Wind widgets, so the walk is safe for any element:

```dart
import 'package:fluttersdk_wind_diagnostics_contracts/fluttersdk_wind_diagnostics_contracts.dart';

void emitWindBlock(StringBuffer buffer, Element element) {
  final WindDebugResolver? resolver = WindDebugRegistry.current;
  if (resolver == null) return; // wind not in this app, or release build.

  final Map<String, Object?> data = resolver.resolve(element);
  if (data.isEmpty) return; // not a Wind widget.

  buffer.writeln('wind:');
  data.forEach((key, value) {
    buffer.writeln('  $key: $value');
  });
}
```

The returned map's key set is documented as the v1 frozen contract (see [CHANGELOG.md](CHANGELOG.md) for the full key list).

### Test seams

`WindDebugRegistry` exposes two `@visibleForTesting` helpers so debug-tool tests can register fake resolvers without going through Wind:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttersdk_wind_diagnostics_contracts/fluttersdk_wind_diagnostics_contracts.dart';

class _FakeResolver implements WindDebugResolver {
  @override
  Map<String, Object?> resolve(Element element) {
    return const <String, Object?>{
      'className': 'flex p-4',
      'breakpoint': 'lg',
      'brightness': 'light',
      'platform': 'web',
      'states': <String>['hover'],
    };
  }
}

void main() {
  setUp(() => WindDebugRegistry.resetForTesting());

  testWidgets('observe emits wind block from registry', (tester) async {
    WindDebugRegistry.registerForTesting(_FakeResolver());
    // ... rest of the test ...
  });
}
```

---

## Versioning

This package follows [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html). The `WindDebugResolver.resolve` return-map key set is the load-bearing v1 contract: additive changes (new keys in the returned map) are non-breaking; renaming or removing existing keys requires a major bump.

---

## License

MIT. See [LICENSE](LICENSE).
