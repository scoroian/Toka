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
import 'package:toka/shared/widgets/ad_banner_notice_provider.dart';

const _uid = 'uid-me';

AuthState _authed(String uid) => AuthState.authenticated(AuthUser(
      uid: uid,
      email: 'u@u.com',
      displayName: 'U',
      photoUrl: null,
      emailVerified: true,
      providers: const [],
    ));

class _FakeAuth extends Auth {
  _FakeAuth(this._s);
  final AuthState _s;
  @override
  AuthState build() => _s;
}

class _FakeCurrentHome extends CurrentHome {
  _FakeCurrentHome({this.payerUid, this.id = 'h1'});
  final String? payerUid;
  final String id;
  @override
  Future<Home?> build() async => Home(
        id: id,
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
  Future<void> switchHome(String i) async {}
}

HomeDashboard _dash({required bool isPremium}) => HomeDashboard.fromFirestore({
      'premiumFlags': {'isPremium': isPremium, 'showAds': !isPremium},
    });

ProviderContainer _c({
  required HomeDashboard? dashboard,
  required String? payerUid,
  required bool hasPlus,
  String id = 'h1',
}) =>
    ProviderContainer(overrides: [
      dashboardProvider.overrideWith((ref) => Stream.value(dashboard)),
      currentHomeProvider
          .overrideWith(() => _FakeCurrentHome(payerUid: payerUid, id: id)),
      authProvider.overrideWith(() => _FakeAuth(_authed(_uid))),
      plusActiveProvider.overrideWith((ref) => hasPlus),
    ]);

void main() {
  group('computeBannerNoticeEligible — tabla de verdad', () {
    test('elegible solo si Premium ∧ no pagador ∧ sin Plus', () {
      for (final premium in [false, true]) {
        for (final payer in [false, true]) {
          for (final plus in [false, true]) {
            final r = computeBannerNoticeEligible(
                homeIsPremium: premium, isPayer: payer, hasPlus: plus);
            expect(r, equals(premium && !payer && !plus),
                reason: 'premium=$premium payer=$payer plus=$plus');
          }
        }
      }
    });
  });

  group('adBannerNoticeVisibleProvider', () {
    test('Premium + miembro no pagador + sin Plus → visible', () async {
      final c =
          _c(dashboard: _dash(isPremium: true), payerUid: 'otro', hasPlus: false);
      addTearDown(c.dispose);
      await c.read(dashboardProvider.future);
      await c.read(currentHomeProvider.future);
      expect(c.read(adBannerNoticeVisibleProvider), isTrue);
    });

    test('pagador → no visible', () async {
      final c =
          _c(dashboard: _dash(isPremium: true), payerUid: _uid, hasPlus: false);
      addTearDown(c.dispose);
      await c.read(dashboardProvider.future);
      await c.read(currentHomeProvider.future);
      expect(c.read(adBannerNoticeVisibleProvider), isFalse);
    });

    test('hogar Free → no visible', () async {
      final c = _c(
          dashboard: _dash(isPremium: false), payerUid: 'otro', hasPlus: false);
      addTearDown(c.dispose);
      await c.read(dashboardProvider.future);
      await c.read(currentHomeProvider.future);
      expect(c.read(adBannerNoticeVisibleProvider), isFalse);
    });

    test('miembro con Plus → no visible', () async {
      final c =
          _c(dashboard: _dash(isPremium: true), payerUid: 'otro', hasPlus: true);
      addTearDown(c.dispose);
      await c.read(dashboardProvider.future);
      await c.read(currentHomeProvider.future);
      expect(c.read(adBannerNoticeVisibleProvider), isFalse);
    });

    test('dashboard/home desconocidos → no visible (fail-safe)', () async {
      final c = _c(dashboard: null, payerUid: 'otro', hasPlus: false);
      addTearDown(c.dispose);
      expect(c.read(adBannerNoticeVisibleProvider), isFalse);
    });

    test('descartar oculta la caption en la sesión', () async {
      final c = _c(
          dashboard: _dash(isPremium: true), payerUid: 'otro', hasPlus: false);
      addTearDown(c.dispose);
      await c.read(dashboardProvider.future);
      await c.read(currentHomeProvider.future);
      expect(c.read(adBannerNoticeVisibleProvider), isTrue);

      c.read(adBannerNoticeDismissedProvider.notifier).dismiss();
      expect(c.read(adBannerNoticeVisibleProvider), isFalse);
      expect(c.read(adBannerNoticeDismissedProvider), isTrue);
    });
  });
}
