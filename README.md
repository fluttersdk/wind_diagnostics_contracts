# fluttersdk_wind_diagnostics_contracts

Pure abstract contracts for Wind UI diagnostic introspection. This package provides a neutral bridge between the Wind UI rendering layer (`fluttersdk_wind`) and debug-tooling packages (such as `fluttersdk_dusk`) without introducing a compile-time dependency between them. Wind registers a concrete `WindDebugResolver` via the static `WindDebugRegistry`; debug tools look up that resolver at runtime to extract widget state (breakpoint, brightness, platform, states, bgColor, textColor) without ever importing Wind directly.

## Usage

**Registering a resolver (in Wind or any UI package):**

```dart
import 'package:fluttersdk_wind_diagnostics_contracts/fluttersdk_wind_diagnostics_contracts.dart';

WindDebugRegistry.register(MyConcreteWindDebugResolver());
```

**Looking up the resolver (in a debug-tooling package):**

```dart
import 'package:fluttersdk_wind_diagnostics_contracts/fluttersdk_wind_diagnostics_contracts.dart';

final resolver = WindDebugRegistry.current;
if (resolver != null) {
  final info = resolver.resolve(element);
  // info is a `Map<String, Object?>` with keys:
  // className, breakpoint, brightness, platform, states, bgColor, textColor.
  // bgColor and textColor are present only when resolved.
}
```
