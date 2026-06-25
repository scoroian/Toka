import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/auth/domain/auth_user.dart';
import 'package:toka/features/subscription/application/plus_provider.dart';
import 'package:toka/features/subscription/application/toka_plus_enabled_provider.dart';
import 'package:toka/features/subscription/domain/plus_entitlement.dart';
import 'package:toka/features/subscription/domain/plus_repository.dart';

const _userA = AuthUser(
  uid: 'uid-a',
  email: 'a@toka.app',
  displayName: 'A',
  photoUrl: null,
  emailVerified: true,
  providers: ['password'],
);

class _FakeAuth extends Auth {
  _FakeAuth(this._state);
  final AuthState _state;
  @override
  AuthState build() => _state;
}

/// Repo en memoria: devuelve un stream configurado por uid y registra qué uid
/// se le pidió (para verificar el aislamiento per-usuario).
class _FakePlusRepo implements PlusRepository {
  _FakePlusRepo(this._byUid);
  final Map<String, Stream<PlusEntitlement?>> _byUid;
  final List<String> requestedUids = [];

  @override
  Stream<PlusEntitlement?> watch(String uid) {
    requestedUids.add(uid);
    return _byUid[uid] ?? const Stream<PlusEntitlement?>.empty();
  }
}

PlusEntitlement _active({DateTime? endsAt}) =>
    PlusEntitlement(status: 'active', active: true, cycle: 'annual', endsAt: endsAt);

void main() {
  group('plusEntitlementProvider', () {
    test('sin sesión emite null', () async {
      final repo = _FakePlusRepo({});
      final container = ProviderContainer(overrides: [
        authProvider.overrideWith(() => _FakeAuth(const AuthState.unauthenticated())),
        plusRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      final value = await container.read(plusEntitlementProvider.future);
      expect(value, isNull);
      expect(repo.requestedUids, isEmpty);
    });

    test('autenticado emite el entitlement del uid actual (per-usuario)', () async {
      final repo = _FakePlusRepo({
        'uid-a': Stream.value(_active()),
        'uid-b': Stream.value(null),
      });
      final container = ProviderContainer(overrides: [
        authProvider.overrideWith(() => _FakeAuth(const AuthState.authenticated(_userA))),
        plusRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      final value = await container.read(plusEntitlementProvider.future);
      expect(value?.active, isTrue);
      expect(repo.requestedUids, ['uid-a']);
    });
  });

  group('plusActiveProvider', () {
    Future<bool> readActive({
      required bool flag,
      Stream<PlusEntitlement?>? entStream,
      bool awaitFirst = true,
    }) async {
      final container = ProviderContainer(overrides: [
        tokaPlusEnabledProvider.overrideWithValue(flag),
        if (entStream != null)
          plusEntitlementProvider.overrideWith((ref) => entStream),
      ]);
      addTearDown(container.dispose);
      if (entStream != null && awaitFirst) {
        await container
            .read(plusEntitlementProvider.future)
            .then((_) {}, onError: (_) {});
      }
      return container.read(plusActiveProvider);
    }

    test('flag OFF => false aunque el doc esté activo', () async {
      final result = await readActive(
        flag: false,
        entStream: Stream.value(_active()),
      );
      expect(result, isFalse);
    });

    test('flag ON + sin doc => false', () async {
      final result = await readActive(flag: true, entStream: Stream.value(null));
      expect(result, isFalse);
    });

    test('flag ON + active=false => false', () async {
      final result = await readActive(
        flag: true,
        entStream: Stream.value(
          const PlusEntitlement(status: 'refunded', active: false),
        ),
      );
      expect(result, isFalse);
    });

    test('flag ON + active + sin endsAt => true', () async {
      final result = await readActive(flag: true, entStream: Stream.value(_active()));
      expect(result, isTrue);
    });

    test('flag ON + active + endsAt futuro => true', () async {
      final result = await readActive(
        flag: true,
        entStream: Stream.value(
          _active(endsAt: DateTime.now().add(const Duration(days: 5))),
        ),
      );
      expect(result, isTrue);
    });

    test('flag ON + active + endsAt vencido => false (expirado)', () async {
      final result = await readActive(
        flag: true,
        entStream: Stream.value(
          _active(endsAt: DateTime.now().subtract(const Duration(days: 1))),
        ),
      );
      expect(result, isFalse);
    });

    test('cargando => false (fail-safe)', () async {
      final controller = StreamController<PlusEntitlement?>();
      addTearDown(controller.close);
      final result = await readActive(
        flag: true,
        entStream: controller.stream,
        awaitFirst: false, // nunca emite => AsyncLoading
      );
      expect(result, isFalse);
    });

    test('error => false (fail-safe)', () async {
      final result = await readActive(
        flag: true,
        entStream: Stream<PlusEntitlement?>.error(Exception('boom')),
      );
      expect(result, isFalse);
    });
  });
}
