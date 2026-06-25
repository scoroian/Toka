import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/auth/domain/auth_user.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/application/dashboard_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/homes/domain/home_limits.dart';
import 'package:toka/features/subscription/application/plus_provider.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';
import 'package:toka/shared/widgets/ad_visibility_provider.dart';

const _uid = 'uid-me';

AuthState _authed(String uid) => AuthState.authenticated(
      AuthUser(
        uid: uid,
        email: 'u@u.com',
        displayName: 'U',
        photoUrl: null,
        emailVerified: true,
        providers: const [],
      ),
    );

class _FakeAuth extends Auth {
  _FakeAuth(this._state);
  final AuthState _state;
  @override
  AuthState build() => _state;
}

/// CurrentHome fake con `currentPayerUid` configurable. El estado premium lo
/// aporta el dashboard, no este Home, así que `premiumStatus` es irrelevante.
class _FakeCurrentHome extends CurrentHome {
  _FakeCurrentHome({this.payerUid});
  final String? payerUid;
  @override
  Future<Home?> build() async => Home(
        id: 'h1',
        name: 'Casa',
        ownerUid: 'owner',
        currentPayerUid: payerUid,
        lastPayerUid: null,
        premiumStatus: HomePremiumStatus.free,
        premiumPlan: null,
        premiumEndsAt: null,
        restoreUntil: null,
        autoRenewEnabled: false,
        limits: const HomeLimits(maxMembers: 5),
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
  @override
  Future<void> switchHome(String id) async {}
}

/// CurrentHome que nunca resuelve → se queda en AsyncLoading (fail-safe).
class _LoadingCurrentHome extends CurrentHome {
  @override
  Future<Home?> build() => Completer<Home?>().future;
  @override
  Future<void> switchHome(String id) async {}
}

HomeDashboard _dash({required bool isPremium}) => HomeDashboard.fromFirestore({
      'premiumFlags': {'isPremium': isPremium, 'showAds': !isPremium},
    });

Future<void> _pump() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

ProviderContainer _container({
  required HomeDashboard? dashboard,
  required String? payerUid,
  required bool hasPlus,
  String uid = _uid,
  CurrentHome Function()? currentHomeFake,
}) {
  return ProviderContainer(overrides: [
    dashboardProvider.overrideWith((ref) => Stream.value(dashboard)),
    currentHomeProvider
        .overrideWith(currentHomeFake ?? () => _FakeCurrentHome(payerUid: payerUid)),
    authProvider.overrideWith(() => _FakeAuth(_authed(uid))),
    plusActiveProvider.overrideWith((ref) => hasPlus),
  ]);
}

Future<AdVisibility> _resolve({
  required HomeDashboard? dashboard,
  required String? payerUid,
  required bool hasPlus,
  String uid = _uid,
}) async {
  final c = _container(
      dashboard: dashboard, payerUid: payerUid, hasPlus: hasPlus, uid: uid);
  addTearDown(c.dispose);
  await c.read(dashboardProvider.future);
  await c.read(currentHomeProvider.future);
  return c.read(adVisibilityProvider);
}

void main() {
  group('adVisibilityProvider — 5 filas (estado leído de Firestore)', () {
    test('Fila 1: Free, sin Plus → banner sí, intersticial sí', () async {
      final v = await _resolve(
          dashboard: _dash(isPremium: false), payerUid: null, hasPlus: false);
      expect(v, const AdVisibility(banner: true, interstitial: true));
    });

    test('Fila 2: Free, con Plus → ocultos', () async {
      final v = await _resolve(
          dashboard: _dash(isPremium: false), payerUid: null, hasPlus: true);
      expect(v, AdVisibility.hidden);
    });

    test('Fila 3: Premium, pagador (currentPayerUid==yo) → ocultos', () async {
      final v = await _resolve(
          dashboard: _dash(isPremium: true), payerUid: _uid, hasPlus: false);
      expect(v, AdVisibility.hidden);
    });

    test('Fila 4: Premium, miembro sin Plus → solo banner', () async {
      final v = await _resolve(
          dashboard: _dash(isPremium: true), payerUid: 'otro', hasPlus: false);
      expect(v, const AdVisibility(banner: true, interstitial: false));
    });

    test('Fila 5: Premium, miembro con Plus → ocultos', () async {
      final v = await _resolve(
          dashboard: _dash(isPremium: true), payerUid: 'otro', hasPlus: true);
      expect(v, AdVisibility.hidden);
    });
  });

  group('adVisibilityProvider — fail-safe (ocultar ambos mientras no se sabe)', () {
    test('dashboard aún null (cargando) → ocultos', () async {
      final v = await _resolve(
          dashboard: null, payerUid: null, hasPlus: false);
      expect(v, AdVisibility.hidden);
    });

    test('currentHome en loading (nunca resuelve) → ocultos', () async {
      final c = ProviderContainer(overrides: [
        dashboardProvider
            .overrideWith((ref) => Stream.value(_dash(isPremium: false))),
        currentHomeProvider.overrideWith(() => _LoadingCurrentHome()),
        authProvider.overrideWith(() => _FakeAuth(_authed(_uid))),
        plusActiveProvider.overrideWith((ref) => false),
      ]);
      addTearDown(c.dispose);
      await c.read(dashboardProvider.future);
      expect(c.read(adVisibilityProvider), AdVisibility.hidden);
    });
  });

  group('adVisibilityProvider — recálculo en caliente', () {
    test('el hogar pasa a Premium (miembro): intersticial se apaga, banner sigue',
        () async {
      final dashCtrl = StreamController<HomeDashboard?>();
      addTearDown(dashCtrl.close);
      final plusState = StateProvider<bool>((_) => false);
      final c = ProviderContainer(overrides: [
        dashboardProvider.overrideWith((ref) => dashCtrl.stream),
        currentHomeProvider.overrideWith(() => _FakeCurrentHome(payerUid: 'otro')),
        authProvider.overrideWith(() => _FakeAuth(_authed(_uid))),
        plusActiveProvider.overrideWith((ref) => ref.watch(plusState)),
      ]);
      addTearDown(c.dispose);
      final sub = c.listen(adVisibilityProvider, (_, __) {});
      addTearDown(sub.close);
      await c.read(currentHomeProvider.future);

      dashCtrl.add(_dash(isPremium: false));
      await _pump();
      expect(c.read(adVisibilityProvider),
          const AdVisibility(banner: true, interstitial: true));

      dashCtrl.add(_dash(isPremium: true));
      await _pump();
      expect(c.read(adVisibilityProvider),
          const AdVisibility(banner: true, interstitial: false));
    });

    test('el usuario activa Plus: ambos se apagan', () async {
      final plusState = StateProvider<bool>((_) => false);
      final c = ProviderContainer(overrides: [
        dashboardProvider
            .overrideWith((ref) => Stream.value(_dash(isPremium: false))),
        currentHomeProvider.overrideWith(() => _FakeCurrentHome(payerUid: null)),
        authProvider.overrideWith(() => _FakeAuth(_authed(_uid))),
        plusActiveProvider.overrideWith((ref) => ref.watch(plusState)),
      ]);
      addTearDown(c.dispose);
      final sub = c.listen(adVisibilityProvider, (_, __) {});
      addTearDown(sub.close);
      await c.read(dashboardProvider.future);
      await c.read(currentHomeProvider.future);

      expect(c.read(adVisibilityProvider),
          const AdVisibility(banner: true, interstitial: true));

      c.read(plusState.notifier).state = true;
      await _pump();
      expect(c.read(adVisibilityProvider), AdVisibility.hidden);
    });

    test('cambia el pagador a mí (Premium): banner se apaga', () async {
      // payer pasa de "otro" a "yo" → dejo de ver banner. Modelamos el cambio de
      // pagador recreando currentHome vía invalidación.
      final payerState = StateProvider<String?>((_) => 'otro');
      final c = ProviderContainer(overrides: [
        dashboardProvider
            .overrideWith((ref) => Stream.value(_dash(isPremium: true))),
        authProvider.overrideWith(() => _FakeAuth(_authed(_uid))),
        plusActiveProvider.overrideWith((ref) => false),
        // currentPayerUid derivado de payerState para poder mutarlo en caliente.
        currentHomeProvider.overrideWith(() => _PayerStateCurrentHome(payerState)),
      ]);
      addTearDown(c.dispose);
      final sub = c.listen(adVisibilityProvider, (_, __) {});
      addTearDown(sub.close);
      await c.read(dashboardProvider.future);
      await c.read(currentHomeProvider.future);

      expect(c.read(adVisibilityProvider),
          const AdVisibility(banner: true, interstitial: false));

      c.read(payerState.notifier).state = _uid;
      await _pump();
      await c.read(currentHomeProvider.future);
      expect(c.read(adVisibilityProvider), AdVisibility.hidden);
    });
  });
}

/// CurrentHome cuyo `currentPayerUid` sigue a un StateProvider (recálculo en
/// caliente del pagador).
class _PayerStateCurrentHome extends CurrentHome {
  _PayerStateCurrentHome(this._payerState);
  final StateProvider<String?> _payerState;
  @override
  Future<Home?> build() async {
    final payer = ref.watch(_payerState);
    return Home(
      id: 'h1',
      name: 'Casa',
      ownerUid: 'owner',
      currentPayerUid: payer,
      lastPayerUid: null,
      premiumStatus: HomePremiumStatus.active,
      premiumPlan: null,
      premiumEndsAt: null,
      restoreUntil: null,
      autoRenewEnabled: false,
      limits: const HomeLimits(maxMembers: 5),
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );
  }

  @override
  Future<void> switchHome(String id) async {}
}
