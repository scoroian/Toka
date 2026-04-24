// test/ui/features/history/history_event_detail_screen_test.dart
//
// Cubre BUG-20/BUG-21: la nota de una review es visible sólo para el autor
// (reviewerUid) y el evaluado (performerUid del evento). Terceros ven
// estrellas/score pero NO la nota.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/auth/domain/auth_user.dart';
import 'package:toka/features/history/application/history_event_detail_provider.dart';
import 'package:toka/features/history/domain/task_event.dart';
import 'package:toka/features/history/presentation/history_event_detail_screen.dart';
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
      homeId: 'home1',
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

Widget _wrap(Widget child, List<Override> overrides) => ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: child,
      ),
    );

List<Override> _overrides({required String viewerUid}) => [
      authProvider.overrideWith(
          () => _FakeAuth(AuthState.authenticated(_user(viewerUid)))),
      homeMembersProvider('home1').overrideWith((ref) => Stream.value([
            _member('uid_reviewer', 'Ana', MemberRole.owner),
            _member('uid_performer', 'Luis', MemberRole.member),
            _member('uid_third', 'Pepe', MemberRole.admin),
          ])),
      historyEventDetailProvider(homeId: 'home1', eventId: 'e1')
          .overrideWith((ref) => Stream.value(HistoryEventDetail(
                event: _completedEvent,
                reviews: [_review],
              ))),
    ];

void main() {
  group('HistoryEventDetailScreen — visibilidad de nota', () {
    testWidgets('reviewer ve la nota', (tester) async {
      await tester.pumpWidget(_wrap(
        const HistoryEventDetailScreen(homeId: 'home1', eventId: 'e1'),
        _overrides(viewerUid: 'uid_reviewer'),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('private_note_container')), findsOneWidget);
      expect(find.text(_privateNote), findsOneWidget);
      expect(find.byKey(const Key('review_stars')), findsOneWidget);
    });

    testWidgets('performer ve la nota', (tester) async {
      await tester.pumpWidget(_wrap(
        const HistoryEventDetailScreen(homeId: 'home1', eventId: 'e1'),
        _overrides(viewerUid: 'uid_performer'),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('private_note_container')), findsOneWidget);
      expect(find.text(_privateNote), findsOneWidget);
    });

    testWidgets('tercero NO ve la nota pero sí estrellas + score',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const HistoryEventDetailScreen(homeId: 'home1', eventId: 'e1'),
        _overrides(viewerUid: 'uid_third'),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('private_note_container')), findsNothing);
      expect(find.text(_privateNote), findsNothing);
      expect(find.byKey(const Key('review_stars')), findsOneWidget);
    });

    testWidgets('evento sin reviews muestra mensaje vacío', (tester) async {
      await tester.pumpWidget(_wrap(
        const HistoryEventDetailScreen(homeId: 'home1', eventId: 'e1'),
        [
          authProvider.overrideWith(
              () => _FakeAuth(AuthState.authenticated(_user('uid_third')))),
          homeMembersProvider('home1')
              .overrideWith((ref) => Stream.value(const <Member>[])),
          historyEventDetailProvider(homeId: 'home1', eventId: 'e1')
              .overrideWith((ref) => Stream.value(HistoryEventDetail(
                    event: _completedEvent,
                    reviews: const [],
                  ))),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('no_reviews_message')), findsOneWidget);
    });
  });
}
