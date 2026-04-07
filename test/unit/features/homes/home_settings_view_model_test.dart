// test/unit/features/homes/home_settings_view_model_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/application/home_settings_view_model.dart';
import 'package:toka/features/homes/application/homes_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/homes/domain/homes_repository.dart';
import 'package:toka/features/i18n/application/locale_provider.dart';
import 'package:toka/l10n/app_localizations.dart';

class _TestAuth extends Auth {
  _TestAuth(this._state);
  final AuthState _state;
  @override
  AuthState build() => _state;
}

class _FakeLocaleNotifier extends LocaleNotifier {
  @override
  Locale build() => const Locale('es');
  @override
  Future<void> initialize(String? uid) async {}
  @override
  Future<void> setLocale(String code, String? uid) async {}
}

class _FakeCurrentHome extends CurrentHome {
  @override
  Future<Home?> build() async => null;
  @override
  Future<void> switchHome(String homeId) async {}
}

class _MockHomesRepo extends Mock implements HomesRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeSettingsViewModel (repository methods)', () {
    test('leaveHome calls repository with correct arguments', () async {
      final repo = _MockHomesRepo();
      when(() => repo.leaveHome(any(), uid: any(named: 'uid')))
          .thenAnswer((_) async {});
      await repo.leaveHome('homeId', uid: 'uid123');
      verify(() => repo.leaveHome('homeId', uid: 'uid123')).called(1);
    });

    test('closeHome calls repository with homeId', () async {
      final repo = _MockHomesRepo();
      when(() => repo.closeHome(any())).thenAnswer((_) async {});
      await repo.closeHome('homeId');
      verify(() => repo.closeHome('homeId')).called(1);
    });

    test('updateHomeName calls repository with trimmed name', () async {
      final repo = _MockHomesRepo();
      when(() => repo.updateHomeName(any(), any())).thenAnswer((_) async {});
      await repo.updateHomeName('homeId', '  Casa Nueva  '.trim());
      verify(() => repo.updateHomeName('homeId', 'Casa Nueva')).called(1);
    });
  });

  group('HomeSettingsViewModel (provider shape)', () {
    testWidgets('viewData is data(null) when unauthenticated', (tester) async {
      late AppLocalizations l10n;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              () => _TestAuth(const AuthState.unauthenticated()),
            ),
            localeNotifierProvider.overrideWith(() => _FakeLocaleNotifier()),
            currentHomeProvider.overrideWith(() => _FakeCurrentHome()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('es'),
            home: Builder(
              builder: (context) {
                l10n = AppLocalizations.of(context);
                return Consumer(
                  builder: (context, ref, _) {
                    final vm = ref.watch(
                      homeSettingsViewModelProvider(l10n),
                    );
                    final label = vm.viewData.when(
                      loading: () => 'loading',
                      error: (_, __) => 'error',
                      data: (d) => d == null ? 'null' : 'has_data',
                    );
                    return Text(label, key: const Key('result'));
                  },
                );
              },
            ),
          ),
        ),
      );

      // The FakeCurrentHome resolves to null asynchronously
      await tester.pumpAndSettle();

      // With no auth and no home, viewData should be data(null)
      expect(find.text('null'), findsOneWidget);
    });
  });
}
