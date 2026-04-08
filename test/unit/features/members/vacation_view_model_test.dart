// test/unit/features/members/vacation_view_model_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/members/application/vacation_provider.dart';
import 'package:toka/features/members/application/vacation_view_model.dart';
import 'package:toka/features/members/domain/members_repository.dart';
import 'package:toka/features/members/domain/vacation.dart';
import 'package:toka/features/members/application/members_provider.dart';

class _MockMembersRepository extends Mock implements MembersRepository {}

void main() {
  late _MockMembersRepository mockRepo;

  setUp(() {
    mockRepo = _MockMembersRepository();
    registerFallbackValue(Vacation(
      uid: 'u',
      homeId: 'h',
      createdAt: DateTime(2026, 1, 1),
    ));
    // vacation stream returns null (no existing vacation)
    when(() => mockRepo.watchVacation(any(), any()))
        .thenAnswer((_) => Stream.value(null));
    // saveVacation succeeds
    when(() => mockRepo.saveVacation(any(), any(), any()))
        .thenAnswer((_) async {});
  });

  ProviderContainer _makeContainer() {
    return ProviderContainer(overrides: [
      membersRepositoryProvider.overrideWithValue(mockRepo),
    ]);
  }

  group('VacationViewModelNotifier', () {
    test('isActive starts false', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final notifier = container
          .read(vacationViewModelNotifierProvider('home1', 'uid1').notifier);
      expect(notifier.isActive, isFalse);
    });

    test('setActive updates isActive', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final notifier = container
          .read(vacationViewModelNotifierProvider('home1', 'uid1').notifier);
      notifier.setActive(true);
      expect(notifier.isActive, isTrue);
    });

    test('setStartDate updates startDate', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final notifier = container
          .read(vacationViewModelNotifierProvider('home1', 'uid1').notifier);
      final date = DateTime(2026, 6, 1);
      notifier.setStartDate(date);
      expect(notifier.startDate, date);
    });

    test('setEndDate updates endDate', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final notifier = container
          .read(vacationViewModelNotifierProvider('home1', 'uid1').notifier);
      final date = DateTime(2026, 6, 15);
      notifier.setEndDate(date);
      expect(notifier.endDate, date);
    });

    test('savedSuccessfully starts false', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final notifier = container
          .read(vacationViewModelNotifierProvider('home1', 'uid1').notifier);
      expect(notifier.savedSuccessfully, isFalse);
    });

    test('save calls repository and sets savedSuccessfully', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final notifier = container
          .read(vacationViewModelNotifierProvider('home1', 'uid1').notifier);
      notifier.setActive(true);
      await notifier.save(reason: 'vacaciones');

      verify(() => mockRepo.saveVacation('home1', 'uid1', any())).called(1);
      expect(notifier.savedSuccessfully, isTrue);
    });
  });
}
