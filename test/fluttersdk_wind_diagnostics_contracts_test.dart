import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttersdk_wind_diagnostics_contracts/fluttersdk_wind_diagnostics_contracts.dart';

/// Fake resolver that always returns a fixed non-empty map.
class _FakeResolver implements WindDebugResolver {
  @override
  Map<String, Object?> resolve(Element element) {
    return const <String, Object?>{'className': 'fake-class'};
  }
}

/// Noop resolver that honors the contract: returns const {} for all elements.
class _NoopResolver implements WindDebugResolver {
  @override
  Map<String, Object?> resolve(Element element) => const <String, Object?>{};
}

/// Fake perf resolver that returns a fixed stats map.
class _FakePerfResolver implements WindPerfResolver {
  @override
  Map<String, Object?> stats() => const <String, Object?>{'cacheHits': 7};
}

void main() {
  setUp(() => WindDebugRegistry.resetForTesting());

  test('WindDebugRegistry.current returns null when not registered', () {
    expect(WindDebugRegistry.current, isNull);
  });

  test('register stores the resolver and current returns it', () {
    final _FakeResolver fake = _FakeResolver();
    WindDebugRegistry.register(fake);
    expect(WindDebugRegistry.current, same(fake));
  });

  test('register is idempotent: most-recent-call wins', () {
    final _FakeResolver fakeA = _FakeResolver();
    final _FakeResolver fakeB = _FakeResolver();
    WindDebugRegistry.register(fakeA);
    WindDebugRegistry.register(fakeB);
    expect(WindDebugRegistry.current, same(fakeB));
  });

  test('resetForTesting clears the registry', () {
    WindDebugRegistry.register(_FakeResolver());
    WindDebugRegistry.resetForTesting();
    expect(WindDebugRegistry.current, isNull);
  });

  test('registerForTesting overrides: visible test-only intent', () {
    final _FakeResolver fakeA = _FakeResolver();
    final _FakeResolver fakeB = _FakeResolver();
    WindDebugRegistry.register(fakeA);
    WindDebugRegistry.registerForTesting(fakeB);
    expect(WindDebugRegistry.current, same(fakeB));
  });

  testWidgets(
    'WindDebugResolver implementations return const {} for non-Wind elements (contract assertion)',
    (WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      final Element element = tester.element(find.byType(SizedBox));
      final _NoopResolver noop = _NoopResolver();
      expect(noop.resolve(element), equals(const <String, Object?>{}));
    },
  );

  test('WindDebugRegistry.currentPerf returns null when not registered', () {
    expect(WindDebugRegistry.currentPerf, isNull);
  });

  test('registerPerf stores the resolver and currentPerf returns its stats',
      () {
    final _FakePerfResolver fake = _FakePerfResolver();
    WindDebugRegistry.registerPerf(fake);
    expect(WindDebugRegistry.currentPerf?.stats()['cacheHits'], equals(7));
  });

  test('resetForTesting clears the perf slot', () {
    WindDebugRegistry.registerPerf(_FakePerfResolver());
    WindDebugRegistry.resetForTesting();
    expect(WindDebugRegistry.currentPerf, isNull);
  });

  test('registering a perf resolver leaves the debug slot untouched', () {
    final _FakeResolver fakeDebug = _FakeResolver();
    WindDebugRegistry.register(fakeDebug);
    WindDebugRegistry.registerPerf(_FakePerfResolver());
    expect(WindDebugRegistry.current, same(fakeDebug));
  });
}
