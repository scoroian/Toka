// test/ui/features/history/skins/futurista/history_event_detail_screen_futurista_test.dart
//
// Verifica el wrapper `HistoryEventDetailScreen` con la skin futurista activa,
// y la visibilidad de la nota privada (BUG-20/BUG-21) en la variante
// futurista: solo el reviewer y el performer ven el bloque
// `private_note_container`; los terceros ven estrellas pero no la nota.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toka/core/theme/app_skin.dart';
import 'package:toka/core/theme/skin_provider.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/auth/domain/auth_user.dart';
import 'package:toka/features/history/application/history_event_detail_provider.dart';
import 'package:toka/features/history/domain/task_event.dart';
import 'package:toka/features/history/presentation/skins/futurista/history_event_detail_screen_futurista.dart';
import 'package:toka/features/history/presentation/skins/history_event_detail_screen.dart';
import 'package:toka/features/history/presentation/skins/history_event_detail_screen_v2.dart';
import 'package:toka/features/homes/domain/home_membership.dart';
import 'package:toka/features/members/application/members_provider.dart';
import 'package:toka/features/members/domain/member.dart';
import 'package:toka/l10n/app_localizations.dart';

class _FakeAuth extends Auth {
  _FakeAuth(this._state);
  final AuthState _state;
  @override
  AuthState build() => _state;
}

AuthUser _user(String uid) => AuthUser(
      uid: uid,
      email: '$uid@test.com',
      displayName: uid,
      photoUrl: null,
      emailVerified: true,
      providers: const [],
    );

Member _member(String uid, String nickname, MemberRole role) => Member(
      uid: uid,
      homeId: 'h1',
      nickname: nickname,
      photoUrl: null,
      bio: null,
      phone: null,
      phoneVisibility: 'hidden',
      role: role,
      status: MemberStatus.active,
      joinedAt: DateTime(2026),
      tasksCompleted: 0,
      passedCount: 0,
      complianceRate: 1.0,
      currentStreak: 0,
      averageScore: 0,
    );

final _completedEvent = TaskEvent.completed(
  id: 'e1',
  taskId: 't1',
  taskTitleSnapshot: 'Fregar',
  taskVisualSnapshot: const TaskVisual(kind: 'emoji', value: '🧹'),
  actorUid: 'uid_performer',
  performerUid: 'uid_performer',
  completedAt: DateTime(2026, 4, 20),
  createdAt: DateTime(2026, 4, 20),
);

const _privateNote = 'Muy buen trabajo, gracias';

final _review = EventReview(
  reviewerUid: 'uid_reviewer',
  performerUid: 'uid_performer',
  score: 9.0,
  note: _privateNote,
  createdAt: DateTime(2026, 4, 20, 12),
);

List<Override> _overrides({required String viewerUid}) => [
      authProvider.overrideWith(
          () => _FakeAuth(AuthState.authenticated(_user(viewerUid)))),
      homeMembersProvider('h1').overrideWith((ref) => Stream.value([
            _member('uid_reviewer', 'Ana', MemberRole.owner),
            _member('uid_performer', 'Luis', MemberRole.member),
            _member('uid_third', 'Pepe', MemberRole.admin),
          ])),
      historyEventDetailProvider(homeId: 'h1', eventId: 'e1')
          .overrideWith((ref) => Stream.value(HistoryEventDetail(
                event: _completedEvent,
                reviews: [_review],
              ))),
    ];

Widget _harness(ProviderContainer c) => UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(
        locale: Locale('es'),
        supportedLocales: [Locale('es'), Locale('en'), Locale('ro')],
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: HistoryEventDetailScreen(homeId: 'h1', eventId: 'e1'),
      ),
    );

Future<void> _pumpAndSwitch(WidgetTester tester) async {
  // Pumps discretos: evitamos pumpAndSettle porque el AnimatedSwitcher del
  // SkinSwitch encadena transiciones y algún frame puede no estacionarse.
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
      'wrapper renders v2 detail by default and reviewer ve la nota privada',
      (tester) async {
    final c = ProviderContainer(overrides: _overrides(viewerUid: 'uid_reviewer'));
    addTearDown(c.dispose);

    await tester.pumpWidget(_harness(c));
    await _pumpAndSwitch(tester);

    expect(find.byType(HistoryEventDetailScreenV2), findsOneWidget);
    expect(find.byType(HistoryEventDetailScreenFuturista), findsNothing);
    expect(find.byKey(const Key('private_note_container')), findsOneWidget);
    expect(find.text(_privateNote), findsOneWidget);
  });

  testWidgets(
      'wrapper renders futurista cuando skin = futurista; tercero NO ve nota '
      'pero sí estrellas', (tester) async {
    SharedPreferences.setMockInitialValues(
        {SkinMode.persistKey: AppSkin.futurista.persistKey});
    final c = ProviderContainer(overrides: _overrides(viewerUid: 'uid_third'));
    addTearDown(c.dispose);

    await tester.pumpWidget(_harness(c));
    await _pumpAndSwitch(tester);

    expect(find.byType(HistoryEventDetailScreenFuturista), findsOneWidget);
    expect(find.byType(HistoryEventDetailScreenV2), findsNothing);
    expect(find.byKey(const Key('private_note_container')), findsNothing);
    expect(find.text(_privateNote), findsNothing);
    expect(find.byKey(const Key('review_stars')), findsOneWidget);
  });
}
