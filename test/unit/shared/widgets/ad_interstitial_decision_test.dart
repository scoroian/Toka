import 'package:flutter_test/flutter_test.dart';
import 'package:toka/shared/widgets/ad_interstitial_decision.dart';
import 'package:toka/shared/widgets/ad_visibility_provider.dart';

final _now = DateTime(2026, 6, 24, 12, 0, 0);
const _visOn = AdVisibility(banner: true, interstitial: true);
const _visOff = AdVisibility(banner: true, interstitial: false);

bool _decide({
  bool enabled = true,
  AdVisibility visibility = _visOn,
  DateTime? lastShownAt,
  int sessionCount = 0,
  int minIntervalSeconds = 210,
  int maxPerSession = 3,
}) =>
    shouldShowInterstitial(
      enabled: enabled,
      visibility: visibility,
      now: _now,
      lastShownAt: lastShownAt,
      sessionCount: sessionCount,
      minIntervalSeconds: minIntervalSeconds,
      maxPerSession: maxPerSession,
    );

void main() {
  group('shouldShowInterstitial', () {
    test('caso feliz: enabled, visible, sin previas, sesión 0 → true', () {
      expect(_decide(), isTrue);
    });

    test('enabled=false → false', () {
      expect(_decide(enabled: false), isFalse);
    });

    test('visibility.interstitial=false → false (aunque banner sí)', () {
      expect(_decide(visibility: _visOff), isFalse);
    });

    test('intervalo NO cumplido (100s < 210s) → false', () {
      expect(
        _decide(lastShownAt: _now.subtract(const Duration(seconds: 100))),
        isFalse,
      );
    });

    test('intervalo justo cumplido (210s == 210s) → true', () {
      expect(
        _decide(lastShownAt: _now.subtract(const Duration(seconds: 210))),
        isTrue,
      );
    });

    test('intervalo superado (300s > 210s) → true', () {
      expect(
        _decide(lastShownAt: _now.subtract(const Duration(seconds: 300))),
        isTrue,
      );
    });

    test('tope de sesión alcanzado (count==max) → false', () {
      expect(_decide(sessionCount: 3, maxPerSession: 3), isFalse);
    });

    test('tope de sesión superado (count>max) → false', () {
      expect(_decide(sessionCount: 5, maxPerSession: 3), isFalse);
    });

    test('por debajo del tope de sesión y con intervalo ok → true', () {
      expect(
        _decide(
          sessionCount: 2,
          maxPerSession: 3,
          lastShownAt: _now.subtract(const Duration(seconds: 250)),
        ),
        isTrue,
      );
    });

    test('lastShownAt null siempre pasa el gate de intervalo', () {
      expect(_decide(lastShownAt: null), isTrue);
    });

    test('cap de tope=0 → nunca se muestra', () {
      expect(_decide(maxPerSession: 0, sessionCount: 0), isFalse);
    });
  });
}
