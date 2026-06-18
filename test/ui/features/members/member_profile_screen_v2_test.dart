import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/core/errors/exceptions.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/homes/domain/home_membership.dart';
import 'package:toka/features/members/application/member_profile_view_model.dart';
import 'package:toka/features/members/domain/member.dart';
import 'package:toka/features/members/presentation/skins/member_profile_screen_v2.dart';
import 'package:toka/l10n/app_localizations.dart';

class _MockMemberProfileViewModel extends Mock implements MemberProfileViewModel {}

class _TestAuth extends Auth {
  _TestAuth(this._state);
  final AuthState _state;
  @override
  AuthState build() => _state;
}

Member _member({MemberRole role = MemberRole.member}) => Member(
      uid: 'u1',
      homeId: 'h1',
      nickname: 'Ana',
      photoUrl: null,
      bio: null,
      phone: null,
      phoneVisibility: 'hidden',
      role: role,
      status: MemberStatus.active,
      joinedAt: DateTime(2026, 1, 1),
      tasksCompleted: 5,
      passedCount: 1,
      complianceRate: 0.8,
      currentStreak: 2,
      averageScore: 7.0,
    );

MemberProfileViewData _data(
        {MemberRole role = MemberRole.member, String? visiblePhone}) =>
    MemberProfileViewData(
      member: _member(role: role),
      isSelf: false,
      visiblePhone: visiblePhone,
      compliancePct: '80.0',
      radarEntries: const [],
      canManageRoles: true,
      canPromoteToAdmin: true,
      adminsLockedToOwner: false,
      canRemoveMember: true,
      completedCount: 5,
      streakCount: 2,
      averageScore: 7.0,
      showRadar: false,
      overflowEntries: const [],
    );

Widget _wrap(Widget child, MemberProfileViewModel vm) => ProviderScope(
  overrides: [
    memberProfileViewModelProvider(homeId: 'h1', memberUid: 'u1')
        .overrideWith((_) => vm),
  ],
  child: MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate, GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('es')],
    home: child,
  ),
);

/// Envuelve la pantalla en un [Navigator] ANIDADO bajo el navigator raíz del
/// [MaterialApp], reproduciendo el `ShellRoute` de go_router donde vive el
/// perfil de miembro: el diálogo de `showDialog` se empuja en el navigator raíz
/// (useRootNavigator: true por defecto), mientras que el context de la pantalla
/// pertenece al navigator del shell. Si los botones del diálogo hicieran
/// `Navigator.pop(context)` con el context de pantalla, cerrarían la ruta del
/// perfil en lugar del diálogo (bug original).
Widget _wrapNested(MemberProfileViewModel vm) => ProviderScope(
      overrides: [
        memberProfileViewModelProvider(homeId: 'h1', memberUid: 'u1')
            .overrideWith((_) => vm),
        // _LastReviewsSection corta en seco si no hay usuario autenticado.
        authProvider.overrideWith(() => _TestAuth(const AuthState.unauthenticated())),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es')],
        home: Navigator(
          onGenerateInitialRoutes: (navigator, initialRoute) => [
            MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: SizedBox.shrink())),
            MaterialPageRoute<void>(
                builder: (_) =>
                    const MemberProfileScreenV2(homeId: 'h1', memberUid: 'u1')),
          ],
          onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: SizedBox.shrink())),
        ),
      ),
    );

void main() {
  late _MockMemberProfileViewModel vm;
  setUp(() { vm = _MockMemberProfileViewModel(); });

  testWidgets('muestra loading spinner', (tester) async {
    when(() => vm.viewData).thenReturn(const AsyncValue.loading());
    await tester.pumpWidget(_wrap(
        const MemberProfileScreenV2(homeId: 'h1', memberUid: 'u1'), vm));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('usa tipo abstracto MemberProfileViewModel', (tester) async {
    expect(vm, isA<MemberProfileViewModel>());
  });

  // ── Regresión: diálogos de acción de miembro responden a los toques ────────
  // El perfil vive dentro de un ShellRoute. Los botones del diálogo deben
  // cerrar el diálogo (navigator raíz), NO la ruta del perfil (navigator shell).
  group('diálogos de gestión de roles/expulsión (navigator anidado)', () {
    testWidgets('confirmar "Hacer admin" dispara promoteToAdmin y cierra el diálogo',
        (tester) async {
      when(() => vm.viewData)
          .thenReturn(AsyncValue.data(_data(role: MemberRole.member)));
      when(() => vm.promoteToAdmin(any(), any())).thenAnswer((_) async {});

      await tester.pumpWidget(_wrapNested(vm));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('toggle_admin_button')));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.descendant(
          of: find.byType(AlertDialog), matching: find.byType(FilledButton)));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing,
          reason: 'El botón confirmar debe cerrar el diálogo del navigator raíz');
      verify(() => vm.promoteToAdmin('h1', 'u1')).called(1);
      // La ruta del perfil NO debe haberse cerrado.
      expect(find.byKey(const Key('toggle_admin_button')), findsOneWidget);
    });

    testWidgets('cancelar cierra el diálogo, no llama a la acción y conserva el perfil',
        (tester) async {
      when(() => vm.viewData)
          .thenReturn(AsyncValue.data(_data(role: MemberRole.member)));
      when(() => vm.promoteToAdmin(any(), any())).thenAnswer((_) async {});

      await tester.pumpWidget(_wrapNested(vm));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('toggle_admin_button')));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.descendant(
          of: find.byType(AlertDialog), matching: find.byType(TextButton)));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      verifyNever(() => vm.promoteToAdmin(any(), any()));
      // El perfil sigue en pantalla (no se cerró la ruta del shell por error).
      expect(find.byKey(const Key('toggle_admin_button')), findsOneWidget);
    });

    testWidgets('confirmar "Quitar admin" dispara demoteFromAdmin',
        (tester) async {
      when(() => vm.viewData)
          .thenReturn(AsyncValue.data(_data(role: MemberRole.admin)));
      when(() => vm.demoteFromAdmin(any(), any())).thenAnswer((_) async {});

      await tester.pumpWidget(_wrapNested(vm));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('toggle_admin_button')));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.descendant(
          of: find.byType(AlertDialog), matching: find.byType(FilledButton)));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      verify(() => vm.demoteFromAdmin('h1', 'u1')).called(1);
    });

    testWidgets('confirmar "Expulsar" dispara removeMember y cierra el diálogo',
        (tester) async {
      when(() => vm.viewData)
          .thenReturn(AsyncValue.data(_data(role: MemberRole.member)));
      when(() => vm.removeMember(any(), any())).thenAnswer((_) async {});

      await tester.pumpWidget(_wrapNested(vm));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('remove_member_button')));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.descendant(
          of: find.byType(AlertDialog), matching: find.byType(FilledButton)));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      verify(() => vm.removeMember('h1', 'u1')).called(1);
    });

    // Regresión bug #12 (QA 2026-06-16): expulsar al pagador del Premium activo
    // debe mostrar el aviso específico de payer-lock, no fallar en silencio.
    testWidgets('expulsar al pagador muestra SnackBar de payer-lock',
        (tester) async {
      when(() => vm.viewData)
          .thenReturn(AsyncValue.data(_data(role: MemberRole.member)));
      when(() => vm.removeMember(any(), any()))
          .thenThrow(const PayerLockedException());

      await tester.pumpWidget(_wrapNested(vm));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('remove_member_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(
          of: find.byType(AlertDialog), matching: find.byType(FilledButton)));
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(const Locale('es'));
      expect(find.text(l10n.members_error_payer_locked), findsOneWidget);
    });
  });

  // ── Regresión bug #4 (QA 2026-06-16): teléfono visible en el perfil ────────
  // El miembro que comparte su teléfono (phoneVisibility=sameHomeMembers) debe
  // mostrarlo en su perfil para los demás miembros. visiblePhone ya resolvía el
  // permiso, pero la pantalla nunca lo pintaba.
  group('chip de teléfono', () {
    testWidgets('muestra el teléfono cuando el miembro lo comparte',
        (tester) async {
      when(() => vm.viewData)
          .thenReturn(AsyncValue.data(_data(visiblePhone: '+34655443322')));

      await tester.pumpWidget(_wrapNested(vm));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('member_phone_chip')), findsOneWidget);
      expect(find.text('+34655443322'), findsOneWidget);
    });

    testWidgets('no muestra teléfono cuando visiblePhone es null',
        (tester) async {
      when(() => vm.viewData)
          .thenReturn(AsyncValue.data(_data(visiblePhone: null)));

      await tester.pumpWidget(_wrapNested(vm));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('member_phone_chip')), findsNothing);
    });
  });
}
