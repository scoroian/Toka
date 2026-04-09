# MVVM Refactor — Plan 02: Onboarding + Homes + Tasks

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create typed ViewModels for the 7 screens in Onboarding, Homes, and Tasks feature groups. Move all business logic (Firestore reads, validation, state orchestration) out of widgets and into ViewModel implementations.

**Architecture:** Same patterns established in Plan 01.
- *Simple*: Notifier implements abstract class + typed provider returns abstract type.
- *Computed*: `@riverpod` function provider holds an `_XxxViewModelImpl` with a `ref` capture.
- *Family*: ViewModel provider takes a parameter (used for `CreateEditTaskViewModel` and `TaskDetailViewModel`).

**Spec:** `docs/superpowers/specs/2026-04-07-mvvm-skin-design.md`
**Depends on:** Plan 01 completed (SkinConfig exists, Auth ViewModels exist).

---

## File Map

| Action  | File |
|---------|------|
| Create  | `lib/features/onboarding/application/onboarding_view_model.dart` |
| Create  | `lib/features/homes/application/my_homes_view_model.dart` |
| Create  | `lib/features/homes/application/home_settings_view_model.dart` |
| Create  | `lib/features/tasks/application/today_view_model.dart` |
| Create  | `lib/features/tasks/application/all_tasks_view_model.dart` |
| Create  | `lib/features/tasks/application/create_edit_task_view_model.dart` |
| Create  | `lib/features/tasks/application/task_detail_view_model.dart` |
| Create  | `test/unit/features/onboarding/onboarding_view_model_test.dart` |
| Create  | `test/unit/features/homes/my_homes_view_model_test.dart` |
| Create  | `test/unit/features/homes/home_settings_view_model_test.dart` |
| Create  | `test/unit/features/tasks/today_view_model_test.dart` |
| Create  | `test/unit/features/tasks/all_tasks_view_model_test.dart` |
| Create  | `test/unit/features/tasks/create_edit_task_view_model_test.dart` |
| Create  | `test/unit/features/tasks/task_detail_view_model_test.dart` |
| Modify  | `lib/features/onboarding/presentation/onboarding_flow_screen.dart` |
| Modify  | `lib/features/homes/presentation/my_homes_screen.dart` |
| Modify  | `lib/features/homes/presentation/home_settings_screen.dart` |
| Modify  | `lib/features/tasks/presentation/today_screen.dart` |
| Modify  | `lib/features/tasks/presentation/all_tasks_screen.dart` |
| Modify  | `lib/features/tasks/presentation/create_edit_task_screen.dart` |
| Modify  | `lib/features/tasks/presentation/task_detail_screen.dart` |
| Create  | `test/ui/features/onboarding/onboarding_flow_screen_test.dart` |
| Create  | `test/ui/features/homes/my_homes_screen_test.dart` |
| Create  | `test/ui/features/homes/home_settings_screen_test.dart` |
| Create  | `test/ui/features/tasks/today_screen_test.dart` |
| Create  | `test/ui/features/tasks/all_tasks_screen_test.dart` |
| Create  | `test/ui/features/tasks/create_edit_task_screen_test.dart` |
| Create  | `test/ui/features/tasks/task_detail_screen_test.dart` |

---

## Task 1: OnboardingViewModel

**Pattern:** Notifier-implements-interface + typed provider.  
**Why complex:** The screen currently calls `OnboardingNotifier.isCompleted()` in `initState` (async, causes navigation), and also calls `loadSavedProgress()`. The ViewModel absorbs both calls into `build()`, exposes `isInitialized` and `shouldNavigateHome` flags so the screen reacts purely to state.

**Files:**
- Create: `lib/features/onboarding/application/onboarding_view_model.dart`
- Create: `test/unit/features/onboarding/onboarding_view_model_test.dart`
- Modify: `lib/features/onboarding/presentation/onboarding_flow_screen.dart`

- [ ] **Step 1: Create `onboarding_view_model.dart`**

```dart
// lib/features/onboarding/application/onboarding_view_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/onboarding_repository.dart';
import '../../i18n/application/locale_provider.dart';
import 'onboarding_provider.dart';
import 'onboarding_state.dart';

part 'onboarding_view_model.freezed.dart';
part 'onboarding_view_model.g.dart';

// ─────────────────────────────────────────────
// Contract
// ─────────────────────────────────────────────

abstract class OnboardingViewModel {
  // Initialization flags
  bool get isInitialized;
  bool get shouldNavigateHome;

  // Underlying onboarding state
  int get currentStep;
  int get totalSteps;
  String? get selectedLocale;
  String? get nickname;
  String? get phoneNumber;
  bool get phoneVisible;
  String? get photoLocalPath;
  bool get isLoading;
  String? get error;

  // Actions
  void nextStep();
  void prevStep();
  void setLocale(String code);
  void setNickname(String name);
  void setPhoneNumber(String? phone);
  void setPhoneVisible(bool visible);
  void setPhotoLocalPath(String? path);
  Future<void> saveProfileAndContinue();
  Future<void> createHome(String name, String? emoji);
  Future<void> joinHome(String code);
}

// ─────────────────────────────────────────────
// Private VM state (flags not in OnboardingState)
// ─────────────────────────────────────────────

@freezed
class _OnboardingVMState with _$_OnboardingVMState {
  const factory _OnboardingVMState({
    @Default(false) bool isInitialized,
    @Default(false) bool shouldNavigateHome,
  }) = __OnboardingVMState;
}

// ─────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────

@Riverpod(keepAlive: true)
class OnboardingViewModelNotifier extends _$OnboardingViewModelNotifier
    implements OnboardingViewModel {
  OnboardingNotifier get _inner =>
      ref.read(onboardingNotifierProvider.notifier);

  @override
  _OnboardingVMState build() {
    _initialize();
    return const _OnboardingVMState();
  }

  Future<void> _initialize() async {
    final done = await OnboardingNotifier.isCompleted();
    if (done) {
      state = state.copyWith(shouldNavigateHome: true);
      return;
    }
    await _inner.loadSavedProgress();
    state = state.copyWith(isInitialized: true);
  }

  // ── Getters delegated to underlying notifier ──

  OnboardingState get _s => ref.read(onboardingNotifierProvider);

  @override bool get isInitialized => state.isInitialized;
  @override bool get shouldNavigateHome => state.shouldNavigateHome;
  @override int get currentStep => _s.currentStep;
  @override int get totalSteps => _s.totalSteps;
  @override String? get selectedLocale => _s.selectedLocale;
  @override String? get nickname => _s.nickname;
  @override String? get phoneNumber => _s.phoneNumber;
  @override bool get phoneVisible => _s.phoneVisible;
  @override String? get photoLocalPath => _s.photoLocalPath;
  @override bool get isLoading => _s.isLoading;
  @override String? get error => _s.error;

  // ── Actions ──

  @override void nextStep() => _inner.nextStep();
  @override void prevStep() => _inner.prevStep();
  @override void setLocale(String code) {
    _inner.setLocale(code);
    ref.read(localeNotifierProvider.notifier).setLocale(code, null);
  }
  @override void setNickname(String name) => _inner.setNickname(name);
  @override void setPhoneNumber(String? phone) => _inner.setPhoneNumber(phone);
  @override void setPhoneVisible(bool visible) => _inner.setPhoneVisible(visible);
  @override void setPhotoLocalPath(String? path) => _inner.setPhotoLocalPath(path);

  @override
  Future<void> saveProfileAndContinue() =>
      _inner.saveProfileAndContinue();

  @override
  Future<void> createHome(String name, String? emoji) async {
    final homeId = await _inner.createHome(name, emoji);
    if (homeId != null) state = state.copyWith(shouldNavigateHome: true);
  }

  @override
  Future<void> joinHome(String code) async {
    final homeId = await _inner.joinHome(code);
    if (homeId != null) state = state.copyWith(shouldNavigateHome: true);
  }
}

// ─────────────────────────────────────────────
// Typed provider — returns abstract interface
// ─────────────────────────────────────────────

@Riverpod(keepAlive: true)
OnboardingViewModel onboardingViewModel(OnboardingViewModelRef ref) {
  ref.watch(onboardingViewModelNotifierProvider); // own state changes
  ref.watch(onboardingNotifierProvider);           // underlying state changes
  return ref.read(onboardingViewModelNotifierProvider.notifier);
}
```

- [ ] **Step 2: Update `onboarding_flow_screen.dart`**

The screen becomes a `ConsumerStatefulWidget` only for the `PageController`. All business logic is gone.

```dart
// lib/features/onboarding/presentation/onboarding_flow_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../application/onboarding_view_model.dart';
import 'steps/home_choice_step.dart';
import 'steps/language_step.dart';
import 'steps/profile_step.dart';
import 'steps/welcome_step.dart';
import 'widgets/onboarding_progress_bar.dart';

class OnboardingFlowScreen extends ConsumerStatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  ConsumerState<OnboardingFlowScreen> createState() =>
      _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen> {
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(onboardingViewModelProvider);

    // React to navigation signals
    ref.listen<OnboardingViewModel>(onboardingViewModelProvider, (_, next) {
      if (next.shouldNavigateHome) context.go(AppRoutes.home);
    });

    // Sync page controller when step changes
    ref.listen<OnboardingViewModel>(onboardingViewModelProvider, (prev, next) {
      if (prev?.currentStep != next.currentStep) {
        _goToPage(next.currentStep);
      }
    });

    if (!vm.isInitialized && !vm.shouldNavigateHome) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          OnboardingProgressBar(
            currentStep: vm.currentStep,
            totalSteps: vm.totalSteps,
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                WelcomeStep(onStart: vm.nextStep),
                LanguageStep(
                  selectedLocale: vm.selectedLocale,
                  onLocaleSelected: vm.setLocale,
                  onNext: vm.nextStep,
                  onPrev: vm.prevStep,
                ),
                ProfileStep(
                  nickname: vm.nickname,
                  phoneNumber: vm.phoneNumber,
                  phoneVisible: vm.phoneVisible,
                  photoLocalPath: vm.photoLocalPath,
                  isLoading: vm.isLoading,
                  error: vm.error,
                  onNicknameChanged: vm.setNickname,
                  onPhoneChanged: vm.setPhoneNumber,
                  onPhoneVisibleChanged: vm.setPhoneVisible,
                  onPhotoChanged: vm.setPhotoLocalPath,
                  onNext: vm.saveProfileAndContinue,
                  onPrev: vm.prevStep,
                ),
                HomeChoiceStep(
                  isLoading: vm.isLoading,
                  error: vm.error,
                  onCreateHome: (name, emoji) => vm.createHome(name, emoji),
                  onJoinHome: vm.joinHome,
                  onPrev: vm.prevStep,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Create `test/unit/features/onboarding/onboarding_view_model_test.dart`**

```dart
// test/unit/features/onboarding/onboarding_view_model_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/onboarding/application/onboarding_view_model.dart';
import 'package:toka/features/onboarding/application/onboarding_provider.dart';
import 'package:toka/features/onboarding/application/onboarding_state.dart';

class _FakeOnboarding extends OnboardingNotifier {
  @override OnboardingState build() => const OnboardingState();
  void push(OnboardingState s) => state = s;
  @override Future<void> loadSavedProgress() async {}
  @override Future<void> saveProfileAndContinue() async {}
  @override Future<String?> createHome(String name, String? emoji) async => 'home123';
  @override Future<String?> joinHome(String code) async => 'home456';
}

// Note: override isCompleted static via a test-only subclass wrapper in integration tests.
// Unit tests focus on state transitions triggered by _FakeOnboarding.

void main() {
  group('OnboardingViewModel', () {
    late _FakeOnboarding fakeOnboarding;
    late ProviderContainer container;

    setUp(() {
      fakeOnboarding = _FakeOnboarding();
      container = ProviderContainer(overrides: [
        onboardingNotifierProvider.overrideWith(() => fakeOnboarding),
      ]);
    });

    tearDown(() => container.dispose());

    test('isInitialized starts false', () {
      final vm = container.read(onboardingViewModelProvider);
      expect(vm.isInitialized, isFalse);
    });

    test('shouldNavigateHome is false initially', () {
      final vm = container.read(onboardingViewModelProvider);
      expect(vm.shouldNavigateHome, isFalse);
    });

    test('createHome sets shouldNavigateHome true on success', () async {
      final notifier =
          container.read(onboardingViewModelNotifierProvider.notifier);
      await notifier.createHome('Mi Casa', '🏠');
      expect(notifier.shouldNavigateHome, isTrue);
    });

    test('joinHome sets shouldNavigateHome true on success', () async {
      final notifier =
          container.read(onboardingViewModelNotifierProvider.notifier);
      await notifier.joinHome('ABC123');
      expect(notifier.shouldNavigateHome, isTrue);
    });

    test('delegates setNickname to underlying notifier', () {
      final notifier =
          container.read(onboardingViewModelNotifierProvider.notifier);
      notifier.setNickname('Ana');
      expect(container.read(onboardingNotifierProvider).nickname, 'Ana');
    });
  });
}
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/onboarding/application/onboarding_view_model.dart \
        lib/features/onboarding/presentation/onboarding_flow_screen.dart \
        test/unit/features/onboarding/onboarding_view_model_test.dart
git commit -m "feat(mvvm): OnboardingViewModel — move init logic out of widget"
```

---

## Task 2: MyHomesViewModel

**Pattern:** Computed provider returns a private impl class.  
**Why:** No mutable local state needed — all data comes from `userMembershipsProvider` and `currentHomeProvider`. No Notifier needed.

**Files:**
- Create: `lib/features/homes/application/my_homes_view_model.dart`
- Create: `test/unit/features/homes/my_homes_view_model_test.dart`
- Modify: `lib/features/homes/presentation/my_homes_screen.dart`

- [ ] **Step 1: Create `my_homes_view_model.dart`**

```dart
// lib/features/homes/application/my_homes_view_model.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_provider.dart';
import '../domain/home_membership.dart';
import 'current_home_provider.dart';
import 'homes_provider.dart';

part 'my_homes_view_model.g.dart';

// ─────────────────────────────────────────────
// Contract
// ─────────────────────────────────────────────

abstract class MyHomesViewModel {
  AsyncValue<List<HomeMembership>> get memberships;
  String get currentHomeId;
  void switchHome(String homeId);
}

// ─────────────────────────────────────────────
// Impl
// ─────────────────────────────────────────────

class _MyHomesViewModelImpl implements MyHomesViewModel {
  const _MyHomesViewModelImpl({
    required this.memberships,
    required this.currentHomeId,
    required this.ref,
  });

  @override final AsyncValue<List<HomeMembership>> memberships;
  @override final String currentHomeId;
  final Ref ref;

  @override
  void switchHome(String homeId) =>
      ref.read(currentHomeProvider.notifier).switchHome(homeId);
}

// ─────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────

@riverpod
MyHomesViewModel myHomesViewModel(MyHomesViewModelRef ref) {
  final uid = ref.watch(authProvider).whenOrNull(authenticated: (u) => u.uid);
  final membershipsAsync = uid != null
      ? ref.watch(userMembershipsProvider(uid))
      : const AsyncValue<List<HomeMembership>>.data([]);
  final currentHomeId = ref.watch(currentHomeProvider).valueOrNull?.id ?? '';

  return _MyHomesViewModelImpl(
    memberships: membershipsAsync,
    currentHomeId: currentHomeId,
    ref: ref,
  );
}
```

- [ ] **Step 2: Update `my_homes_screen.dart`**

```dart
// lib/features/homes/presentation/my_homes_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../application/my_homes_view_model.dart';
import '../domain/home_membership.dart';

class MyHomesScreen extends ConsumerWidget {
  const MyHomesScreen({super.key});

  String _roleLabel(MemberRole role, AppLocalizations l10n) {
    switch (role) {
      case MemberRole.owner:  return l10n.homes_role_owner;
      case MemberRole.admin:  return l10n.homes_role_admin;
      case MemberRole.member:
      case MemberRole.frozen: return l10n.homes_role_member;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.watch(myHomesViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.homes_my_homes)),
      body: vm.memberships.when(
        loading: () => const LoadingWidget(),
        error: (_, __) => Center(child: Text(l10n.error_generic)),
        data: (memberships) => ListView.builder(
          key: const Key('my_homes_list'),
          itemCount: memberships.length,
          itemBuilder: (context, index) {
            final m = memberships[index];
            final isActive = m.homeId == vm.currentHomeId;
            return ListTile(
              key: Key('home_list_tile_${m.homeId}'),
              title: Text(m.homeNameSnapshot),
              subtitle: Text(_roleLabel(m.role, l10n)),
              trailing: isActive
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                vm.switchHome(m.homeId);
                Navigator.of(context).pop();
              },
            );
          },
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Create unit test**

```dart
// test/unit/features/homes/my_homes_view_model_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/homes/application/my_homes_view_model.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/application/homes_provider.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
// ... fakes for auth, memberships

void main() {
  group('MyHomesViewModel', () {
    test('memberships is data([]) when uid is null', () {
      final container = ProviderContainer(overrides: [
        authProvider.overrideWith((_) => const AuthState.unauthenticated()),
      ]);
      addTearDown(container.dispose);
      final vm = container.read(myHomesViewModelProvider);
      expect(vm.memberships, const AsyncValue.data([]));
    });

    test('currentHomeId is empty string when no home', () {
      final container = ProviderContainer(overrides: [
        authProvider.overrideWith((_) => const AuthState.unauthenticated()),
        currentHomeProvider.overrideWith(() => _FakeCurrentHome()),
      ]);
      addTearDown(container.dispose);
      final vm = container.read(myHomesViewModelProvider);
      expect(vm.currentHomeId, '');
    });
  });
}

class _FakeCurrentHome extends CurrentHome {
  @override build() async => null;
  @override void switchHome(String id) {}
}
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/homes/application/my_homes_view_model.dart \
        lib/features/homes/presentation/my_homes_screen.dart \
        test/unit/features/homes/my_homes_view_model_test.dart
git commit -m "feat(mvvm): MyHomesViewModel — computed provider, no local state"
```

---

## Task 3: HomeSettingsViewModel

**Pattern:** Computed provider + impl class.  
**Why:** Combines `currentHomeProvider` + `userMembershipsProvider` + `authProvider` into a single `HomeSettingsViewData`. Actions (`leaveHome`, `closeHome`, `updateHomeName`) go to the impl, dialogs stay in the screen.

**Files:**
- Create: `lib/features/homes/application/home_settings_view_model.dart`
- Create: `test/unit/features/homes/home_settings_view_model_test.dart`
- Modify: `lib/features/homes/presentation/home_settings_screen.dart`

- [ ] **Step 1: Create `home_settings_view_model.dart`**

```dart
// lib/features/homes/application/home_settings_view_model.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../l10n/app_localizations.dart';
import '../../auth/application/auth_provider.dart';
import '../domain/home.dart';
import '../domain/home_membership.dart';
import 'current_home_provider.dart';
import 'homes_provider.dart';

part 'home_settings_view_model.g.dart';

// ─────────────────────────────────────────────
// View data
// ─────────────────────────────────────────────

class HomeSettingsViewData {
  const HomeSettingsViewData({
    required this.homeId,
    required this.homeName,
    required this.planLabel,
    required this.canEdit,
    required this.canManageSubscription,
    required this.isOwner,
    required this.uid,
  });
  final String homeId;
  final String homeName;
  final String planLabel;
  final bool canEdit;
  final bool canManageSubscription;
  final bool isOwner;
  final String uid;
}

// ─────────────────────────────────────────────
// Contract
// ─────────────────────────────────────────────

abstract class HomeSettingsViewModel {
  AsyncValue<HomeSettingsViewData?> get viewData;
  String? get error;
  bool get isLoading;

  Future<void> updateHomeName(String name);
  Future<void> leaveHome();
  Future<void> closeHome();
  void clearError();
}

// ─────────────────────────────────────────────
// Impl
// ─────────────────────────────────────────────

class _HomeSettingsViewModelImpl implements HomeSettingsViewModel {
  _HomeSettingsViewModelImpl({
    required this.viewData,
    required this.ref,
  });

  @override final AsyncValue<HomeSettingsViewData?> viewData;
  final Ref ref;

  @override String? get error => null;  // managed via SnackBar in screen
  @override bool get isLoading => false;

  @override
  Future<void> updateHomeName(String name) async {
    final homeId = viewData.valueOrNull?.homeId;
    if (homeId == null || name.trim().isEmpty) return;
    await ref.read(homesRepositoryProvider).updateHomeName(homeId, name.trim());
  }

  @override
  Future<void> leaveHome() async {
    final data = viewData.valueOrNull;
    if (data == null) return;
    await ref
        .read(homesRepositoryProvider)
        .leaveHome(data.homeId, uid: data.uid);
  }

  @override
  Future<void> closeHome() async {
    final homeId = viewData.valueOrNull?.homeId;
    if (homeId == null) return;
    await ref.read(homesRepositoryProvider).closeHome(homeId);
  }

  @override
  void clearError() {} // no-op for computed impl; screen handles errors directly
}

String _planLabel(Home home, AppLocalizations l10n) {
  if (home.premiumStatus == HomePremiumStatus.free ||
      home.premiumStatus == HomePremiumStatus.expiredFree) {
    return l10n.homes_plan_free;
  }
  final endsAt = home.premiumEndsAt;
  if (endsAt != null) {
    final formatted = DateFormat.yMd().format(endsAt);
    return '${l10n.homes_plan_premium} · ${l10n.homes_plan_ends(formatted)}';
  }
  return l10n.homes_plan_premium;
}

// ─────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────

@riverpod
HomeSettingsViewModel homeSettingsViewModel(
  HomeSettingsViewModelRef ref,
  AppLocalizations l10n,
) {
  final currentHomeAsync = ref.watch(currentHomeProvider);
  final authState = ref.watch(authProvider);
  final uid = authState.whenOrNull(authenticated: (u) => u.uid) ?? '';

  final viewData = currentHomeAsync.whenData((home) {
    if (home == null || uid.isEmpty) return null;

    final membershipsAsync = ref.watch(userMembershipsProvider(uid));
    final memberships = membershipsAsync.valueOrNull ?? [];
    final myMembership = memberships
        .where((m) => m.homeId == home.id)
        .cast<HomeMembership?>()
        .firstOrNull;

    final myRole = myMembership?.role;
    final isOwner = myRole == MemberRole.owner;
    final canEdit = isOwner || myRole == MemberRole.admin;
    final isCurrentPayer =
        myMembership?.billingState == BillingState.currentPayer;

    return HomeSettingsViewData(
      homeId: home.id,
      homeName: home.name,
      planLabel: _planLabel(home, l10n),
      canEdit: canEdit,
      canManageSubscription: isOwner || isCurrentPayer,
      isOwner: isOwner,
      uid: uid,
    );
  });

  return _HomeSettingsViewModelImpl(viewData: viewData, ref: ref);
}
```

> **Note on `l10n` in provider:** `_planLabel` needs `AppLocalizations` to format strings. The provider takes `l10n` as a family parameter so the screen passes it in. Alternative: move formatting to the screen. Pick whichever is cleaner for the project. If `l10n` as a family parameter feels awkward, move `planLabel` computation to the screen widget.

- [ ] **Step 2: Update `home_settings_screen.dart`**

```dart
// lib/features/homes/presentation/home_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../application/home_settings_view_model.dart';
import '../domain/homes_repository.dart';

class HomeSettingsScreen extends ConsumerStatefulWidget {
  const HomeSettingsScreen({super.key});

  @override
  ConsumerState<HomeSettingsScreen> createState() => _HomeSettingsScreenState();
}

class _HomeSettingsScreenState extends ConsumerState<HomeSettingsScreen> {
  late TextEditingController _nameController;
  bool _nameInitialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _confirmLeave(
    BuildContext context,
    AppLocalizations l10n,
    HomeSettingsViewModel vm,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.homes_leave_confirm_title),
        content: Text(l10n.homes_leave_confirm_body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await vm.leaveHome();
      if (context.mounted) Navigator.of(context).pop();
    } on CannotLeaveAsOwnerException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.homes_error_cannot_leave_as_owner)),
        );
      }
    }
  }

  Future<void> _confirmClose(
    BuildContext context,
    AppLocalizations l10n,
    HomeSettingsViewModel vm,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.homes_close_confirm_title),
        content: Text(l10n.homes_close_confirm_body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await vm.closeHome();
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.watch(homeSettingsViewModelProvider(l10n));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.homes_settings_title)),
      body: vm.viewData.when(
        loading: () => const LoadingWidget(),
        error: (_, __) => Center(child: Text(l10n.error_generic)),
        data: (data) {
          if (data == null) return Center(child: Text(l10n.error_generic));

          if (!_nameInitialized) {
            _nameController.text = data.homeName;
            _nameInitialized = true;
          }

          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: data.canEdit
                    ? TextField(
                        key: const Key('home_name_field'),
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: l10n.homes_name_label,
                          border: const OutlineInputBorder(),
                        ),
                        onSubmitted: (v) => vm.updateHomeName(v),
                      )
                    : ListTile(
                        title: Text(l10n.homes_name_label),
                        subtitle: Text(data.homeName),
                      ),
              ),
              const Divider(),
              ListTile(
                key: const Key('home_plan_tile'),
                title: Text(data.planLabel),
              ),
              if (data.canManageSubscription)
                ListTile(
                  key: const Key('manage_subscription_tile'),
                  title: Text(l10n.homes_manage_subscription),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {/* TODO: navigate to subscription */},
                ),
              const Divider(),
              ListTile(
                key: const Key('members_tile'),
                title: Text(l10n.homes_members),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.members),
              ),
              ListTile(
                key: const Key('invite_code_tile'),
                title: Text(l10n.homes_invite_code),
                trailing: TextButton(
                  key: const Key('generate_code_button'),
                  onPressed: () {/* TODO: generate code */},
                  child: Text(l10n.homes_generate_code),
                ),
              ),
              const Divider(),
              ListTile(
                key: const Key('leave_home_tile'),
                title: Text(
                  l10n.homes_leave_home,
                  style: const TextStyle(color: Colors.orange),
                ),
                onTap: () => _confirmLeave(context, l10n, vm),
              ),
              if (data.isOwner)
                ListTile(
                  key: const Key('close_home_tile'),
                  title: Text(
                    l10n.homes_close_home,
                    style: const TextStyle(color: Colors.red),
                  ),
                  onTap: () => _confirmClose(context, l10n, vm),
                ),
            ],
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 3: Create unit test**

```dart
// test/unit/features/homes/home_settings_view_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/homes/application/home_settings_view_model.dart';
import 'package:toka/features/homes/application/homes_provider.dart';
import 'package:toka/features/homes/domain/homes_repository.dart';
// ... fakes for auth, currentHome, memberships, repository

class _MockHomesRepo extends Mock implements HomesRepository {}

void main() {
  group('HomeSettingsViewModel', () {
    test('viewData is loading when home is loading', () {
      // Set up currentHomeProvider in loading state
      final container = ProviderContainer(overrides: [
        // currentHomeProvider loading stub
      ]);
      addTearDown(container.dispose);
      // vm.viewData should be AsyncLoading
    });

    test('leaveHome calls repository.leaveHome with correct homeId and uid', () async {
      final repo = _MockHomesRepo();
      when(() => repo.leaveHome(any(), uid: any(named: 'uid')))
          .thenAnswer((_) async {});
      // Set up container with fake home + membership + mock repo
      // call vm.leaveHome()
      // verify(repo.leaveHome(homeId, uid: uid)).called(1)
    });

    test('closeHome calls repository.closeHome', () async {
      final repo = _MockHomesRepo();
      when(() => repo.closeHome(any())).thenAnswer((_) async {});
      // Set up and verify
    });
  });
}
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/homes/application/home_settings_view_model.dart \
        lib/features/homes/presentation/home_settings_screen.dart \
        test/unit/features/homes/home_settings_view_model_test.dart
git commit -m "feat(mvvm): HomeSettingsViewModel — computed provider, actions extracted"
```

---

## Task 4: TodayViewModel

**Pattern:** Computed provider + impl class.  
**Why:** Combines `dashboardProvider` + `authProvider` + `currentHomeProvider` into `TodayViewData`. Moves `groupByRecurrence()` into the ViewModel file. Moves the direct Firestore compliance read into `fetchPassStats()`.

**Files:**
- Create: `lib/features/tasks/application/today_view_model.dart`
- Create: `test/unit/features/tasks/today_view_model_test.dart`
- Modify: `lib/features/tasks/presentation/today_screen.dart`

- [ ] **Step 1: Create `today_view_model.dart`**

```dart
// lib/features/tasks/application/today_view_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_provider.dart';
import '../../homes/application/current_home_provider.dart';
import '../../homes/application/dashboard_provider.dart';
import '../domain/home_dashboard.dart';
import '../domain/recurrence_order.dart';
import 'task_completion_provider.dart';
import 'task_pass_provider.dart';
import 'widgets/pass_turn_dialog.dart'; // for calcEstimatedCompliance

part 'today_view_model.g.dart';

// ─────────────────────────────────────────────
// Type alias (kept public for screen)
// ─────────────────────────────────────────────

typedef RecurrenceGroup = ({
  List<TaskPreview> todos,
  List<DoneTaskPreview> dones,
});

// ─────────────────────────────────────────────
// Business logic: groupByRecurrence
// ─────────────────────────────────────────────

@visibleForTesting
Map<String, RecurrenceGroup> groupByRecurrence(
  List<TaskPreview> activeTasks,
  List<DoneTaskPreview> doneTasks,
) {
  final result = <String, RecurrenceGroup>{};

  for (final task in activeTasks) {
    final key = task.recurrenceType;
    final existing = result[key];
    result[key] = (
      todos: [...(existing?.todos ?? []), task],
      dones: existing?.dones ?? [],
    );
  }

  for (final done in doneTasks) {
    final key = done.recurrenceType;
    final existing = result[key];
    result[key] = (
      todos: existing?.todos ?? [],
      dones: [...(existing?.dones ?? []), done],
    );
  }

  for (final key in result.keys) {
    final group = result[key]!;
    final sorted = List<TaskPreview>.from(group.todos)
      ..sort((a, b) {
        if (a.isOverdue && !b.isOverdue) return -1;
        if (!a.isOverdue && b.isOverdue) return 1;
        final dateCmp = a.nextDueAt.compareTo(b.nextDueAt);
        if (dateCmp != 0) return dateCmp;
        return a.title.compareTo(b.title);
      });
    result[key] = (todos: sorted, dones: group.dones);
  }

  return result;
}

// ─────────────────────────────────────────────
// View data
// ─────────────────────────────────────────────

class TodayViewData {
  const TodayViewData({
    required this.grouped,
    required this.counters,
    required this.showAdBanner,
    required this.adBannerUnit,
    required this.currentUid,
    required this.homeId,
    required this.recurrenceOrder,
  });
  final Map<String, RecurrenceGroup> grouped;
  final DashboardCounters counters;
  final bool showAdBanner;
  final String adBannerUnit;
  final String? currentUid;
  final String homeId;
  final List<String> recurrenceOrder;
}

// ─────────────────────────────────────────────
// Contract
// ─────────────────────────────────────────────

abstract class TodayViewModel {
  AsyncValue<TodayViewData?> get viewData;

  Future<void> completeTask(String taskId);
  Future<({double complianceBefore, double estimatedAfter})> fetchPassStats(
      String currentUid);
  Future<void> passTurn(String taskId, {String? reason});
  void retry();
}

// ─────────────────────────────────────────────
// Impl
// ─────────────────────────────────────────────

class _TodayViewModelImpl implements TodayViewModel {
  const _TodayViewModelImpl({
    required this.viewData,
    required this.ref,
  });

  @override final AsyncValue<TodayViewData?> viewData;
  final Ref ref;

  String? get _homeId => viewData.valueOrNull?.homeId;

  @override
  Future<void> completeTask(String taskId) async {
    final homeId = _homeId;
    if (homeId == null) return;
    await ref
        .read(taskCompletionProvider.notifier)
        .completeTask(homeId, taskId);
  }

  @override
  Future<({double complianceBefore, double estimatedAfter})> fetchPassStats(
      String currentUid) async {
    final homeId = _homeId;
    if (homeId == null) {
      return (complianceBefore: 1.0, estimatedAfter: 1.0);
    }
    try {
      final snap = await FirebaseFirestore.instance
          .collection('homes')
          .doc(homeId)
          .collection('members')
          .doc(currentUid)
          .get();
      final data = snap.data() ?? {};
      final completed = (data['completedCount'] as int?) ?? 0;
      final passed = (data['passedCount'] as int?) ?? 0;
      final before = (data['complianceRate'] as double?) ??
          completed / (completed + passed).clamp(1, double.maxFinite);
      final after = PassTurnDialog.calcEstimatedCompliance(
        completedCount: completed,
        passedCount: passed,
      );
      return (complianceBefore: before, estimatedAfter: after);
    } catch (_) {
      return (complianceBefore: 1.0, estimatedAfter: 1.0);
    }
  }

  @override
  Future<void> passTurn(String taskId, {String? reason}) async {
    final homeId = _homeId;
    if (homeId == null) return;
    await ref.read(taskPassProvider.notifier).passTurn(
          homeId,
          taskId,
          reason: reason,
        );
  }

  @override
  void retry() => ref.invalidate(dashboardProvider);
}

// ─────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────

@riverpod
TodayViewModel todayViewModel(TodayViewModelRef ref) {
  final dashboardAsync = ref.watch(dashboardProvider);
  final currentUid =
      ref.watch(authProvider).whenOrNull(authenticated: (u) => u.uid);
  final homeId = ref.watch(currentHomeProvider).valueOrNull?.id ?? '';

  final viewData = dashboardAsync.whenData((data) {
    if (data == null) return null;
    return TodayViewData(
      grouped: groupByRecurrence(
          data.activeTasksPreview, data.doneTasksPreview),
      counters: data.counters,
      showAdBanner: data.adFlags.showBanner,
      adBannerUnit: data.adFlags.bannerUnit,
      currentUid: currentUid,
      homeId: homeId,
      recurrenceOrder: RecurrenceOrder.all,
    );
  });

  return _TodayViewModelImpl(viewData: viewData, ref: ref);
}
```

- [ ] **Step 2: Update `today_screen.dart`**

```dart
// lib/features/tasks/presentation/today_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../application/today_view_model.dart';
import '../domain/home_dashboard.dart';
import 'widgets/complete_task_dialog.dart';
import 'widgets/pass_turn_dialog.dart';
import 'widgets/today_empty_state.dart';
import 'widgets/today_header_counters.dart';
import 'widgets/today_skeleton_loader.dart';
import 'widgets/today_task_section.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  Future<void> _onDone(
    BuildContext context,
    TodayViewModel vm,
    TaskPreview task,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => CompleteTaskDialog(task: task, onConfirm: () {}),
    );
    if (confirmed == true && context.mounted) {
      await vm.completeTask(task.taskId);
    }
  }

  Future<void> _onPass(
    BuildContext context,
    TodayViewModel vm,
    TaskPreview task,
    String? currentUid,
  ) async {
    if (currentUid == null) return;

    final stats = await vm.fetchPassStats(currentUid);
    if (!context.mounted) return;

    String? capturedReason;
    bool confirmed = false;

    await showDialog<void>(
      context: context,
      builder: (_) => PassTurnDialog(
        task: task,
        currentComplianceRate: stats.complianceBefore,
        estimatedComplianceAfter: stats.estimatedAfter,
        nextAssigneeName: null,
        onConfirm: (reason) {
          confirmed = true;
          capturedReason = reason;
        },
      ),
    );

    if (confirmed && context.mounted) {
      await vm.passTurn(task.taskId, reason: capturedReason);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.watch(todayViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.today_screen_title)),
      body: vm.viewData.when(
        loading: () => const TodaySkeletonLoader(),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l10n.error_generic),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: vm.retry,
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        data: (data) {
          if (data == null) return const TodayEmptyState();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: TodayHeaderCounters(counters: data.counters),
              ),
              for (final recurrenceType in data.recurrenceOrder)
                if (data.grouped[recurrenceType] != null)
                  TodayTaskSection(
                    recurrenceType: recurrenceType,
                    todos: data.grouped[recurrenceType]!.todos,
                    dones: data.grouped[recurrenceType]!.dones,
                    currentUid: data.currentUid,
                    onDone: (task) => _onDone(context, vm, task),
                    onPass: (task) =>
                        _onPass(context, vm, task, data.currentUid),
                  ),
              if (data.showAdBanner)
                const SliverToBoxAdapter(
                  child: _AdBannerPlaceholder(key: Key('ad_banner')),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }
}

class _AdBannerPlaceholder extends StatelessWidget {
  const _AdBannerPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(child: Text('Ad')),
    );
  }
}
```

- [ ] **Step 3: Create unit test**

```dart
// test/unit/features/tasks/today_view_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/tasks/application/today_view_model.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';

void main() {
  group('groupByRecurrence', () {
    test('empty lists produce empty map', () {
      expect(groupByRecurrence([], []), isEmpty);
    });

    test('active tasks grouped by recurrenceType', () {
      final task = TaskPreview(
        taskId: 't1',
        title: 'Limpiar',
        visualKind: 'emoji',
        visualValue: '🧹',
        recurrenceType: 'weekly',
        currentAssigneeUid: null,
        currentAssigneeName: null,
        currentAssigneePhoto: null,
        nextDueAt: DateTime(2026, 4, 10),
        isOverdue: false,
        status: 'active',
      );
      final result = groupByRecurrence([task], []);
      expect(result['weekly']!.todos, hasLength(1));
      expect(result['weekly']!.dones, isEmpty);
    });

    test('overdue tasks sorted first within group', () {
      final overdue = TaskPreview(
        taskId: 't_overdue',
        title: 'Barrer',
        visualKind: 'emoji',
        visualValue: '🧹',
        recurrenceType: 'daily',
        currentAssigneeUid: null,
        currentAssigneeName: null,
        currentAssigneePhoto: null,
        nextDueAt: DateTime(2026, 4, 5),
        isOverdue: true,
        status: 'active',
      );
      final onTime = TaskPreview(
        taskId: 't_ok',
        title: 'Fregar',
        visualKind: 'emoji',
        visualValue: '🍽️',
        recurrenceType: 'daily',
        currentAssigneeUid: null,
        currentAssigneeName: null,
        currentAssigneePhoto: null,
        nextDueAt: DateTime(2026, 4, 7),
        isOverdue: false,
        status: 'active',
      );
      final result = groupByRecurrence([onTime, overdue], []);
      expect(result['daily']!.todos.first.taskId, 't_overdue');
    });
  });
}
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/tasks/application/today_view_model.dart \
        lib/features/tasks/presentation/today_screen.dart \
        test/unit/features/tasks/today_view_model_test.dart
git commit -m "feat(mvvm): TodayViewModel — move groupByRecurrence + fetchPassStats to VM"
```

---

## Task 5: AllTasksViewModel

**Pattern:** Separate `AllTasksFilterNotifier` (holds only filter state) + computed provider returns impl.  
**Why filter notifier is separate:** The filter is user-driven and must survive reactive rebuilds of the main provider. If filter state were inside the computed provider, every task stream update would reset the filter.

**Files:**
- Create: `lib/features/tasks/application/all_tasks_view_model.dart`
- Create: `test/unit/features/tasks/all_tasks_view_model_test.dart`
- Modify: `lib/features/tasks/presentation/all_tasks_screen.dart`

- [ ] **Step 1: Create `all_tasks_view_model.dart`**

```dart
// lib/features/tasks/application/all_tasks_view_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_provider.dart';
import '../../homes/application/current_home_provider.dart';
import '../../homes/application/homes_provider.dart';
import '../../homes/domain/home_membership.dart';
import '../domain/task.dart';
import '../domain/task_status.dart';
import 'tasks_provider.dart';

part 'all_tasks_view_model.freezed.dart';
part 'all_tasks_view_model.g.dart';

// ─────────────────────────────────────────────
// Filter state (separate notifier — survives rebuilds)
// ─────────────────────────────────────────────

@freezed
class AllTasksFilter with _$AllTasksFilter {
  const factory AllTasksFilter({
    @Default(TaskStatus.active) TaskStatus status,
    String? assigneeUid,
  }) = _AllTasksFilter;
}

@riverpod
class AllTasksFilterNotifier extends _$AllTasksFilterNotifier {
  @override
  AllTasksFilter build() => const AllTasksFilter();

  void setStatus(TaskStatus s) => state = state.copyWith(status: s);
  void setAssignee(String? uid) => state = state.copyWith(assigneeUid: uid);
}

// ─────────────────────────────────────────────
// View data
// ─────────────────────────────────────────────

class AllTasksViewData {
  const AllTasksViewData({
    required this.tasks,
    required this.filter,
    required this.canCreate,
    required this.uid,
    required this.homeId,
  });
  final List<Task> tasks;
  final AllTasksFilter filter;
  final bool canCreate;
  final String uid;
  final String homeId;
}

// ─────────────────────────────────────────────
// Contract
// ─────────────────────────────────────────────

abstract class AllTasksViewModel {
  AsyncValue<AllTasksViewData?> get viewData;

  void setStatusFilter(TaskStatus s);
  void setAssigneeFilter(String? uid);
  Future<void> toggleFreeze(Task task);
  Future<void> deleteTask(Task task);
}

// ─────────────────────────────────────────────
// Impl
// ─────────────────────────────────────────────

class _AllTasksViewModelImpl implements AllTasksViewModel {
  const _AllTasksViewModelImpl({
    required this.viewData,
    required this.ref,
  });

  @override final AsyncValue<AllTasksViewData?> viewData;
  final Ref ref;

  @override
  void setStatusFilter(TaskStatus s) =>
      ref.read(allTasksFilterNotifierProvider.notifier).setStatus(s);

  @override
  void setAssigneeFilter(String? uid) =>
      ref.read(allTasksFilterNotifierProvider.notifier).setAssignee(uid);

  @override
  Future<void> toggleFreeze(Task task) async {
    final homeId = viewData.valueOrNull?.homeId;
    if (homeId == null) return;
    final repo = ref.read(tasksRepositoryProvider);
    if (task.status == TaskStatus.active) {
      await repo.freezeTask(homeId, task.id);
    } else {
      await repo.unfreezeTask(homeId, task.id);
    }
  }

  @override
  Future<void> deleteTask(Task task) async {
    final data = viewData.valueOrNull;
    if (data == null) return;
    await ref
        .read(tasksRepositoryProvider)
        .deleteTask(data.homeId, task.id, data.uid);
  }
}

// ─────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────

@riverpod
AllTasksViewModel allTasksViewModel(AllTasksViewModelRef ref) {
  final filter = ref.watch(allTasksFilterNotifierProvider);
  final homeAsync = ref.watch(currentHomeProvider);
  final authState = ref.watch(authProvider);
  final uid = authState.whenOrNull(authenticated: (u) => u.uid) ?? '';

  final viewData = homeAsync.whenData((home) {
    if (home == null) return null;

    final membershipsAsync =
        uid.isNotEmpty ? ref.watch(userMembershipsProvider(uid)) : null;
    final memberships = membershipsAsync?.valueOrNull ?? [];
    final myMembership = memberships
        .where((m) => m.homeId == home.id)
        .cast<HomeMembership?>()
        .firstOrNull;
    final myRole = myMembership?.role;
    final canCreate =
        myRole == MemberRole.owner || myRole == MemberRole.admin;

    final tasksAsync = ref.watch(homeTasksProvider(home.id));
    final allTasks = tasksAsync.valueOrNull ?? [];

    var filtered = allTasks.where((t) => t.status == filter.status).toList();
    if (filter.assigneeUid != null) {
      filtered = filtered
          .where((t) => t.currentAssigneeUid == filter.assigneeUid)
          .toList();
    }
    filtered.sort((a, b) => a.nextDueAt.compareTo(b.nextDueAt));

    return AllTasksViewData(
      tasks: filtered,
      filter: filter,
      canCreate: canCreate,
      uid: uid,
      homeId: home.id,
    );
  });

  return _AllTasksViewModelImpl(viewData: viewData, ref: ref);
}
```

- [ ] **Step 2: Update `all_tasks_screen.dart`**

```dart
// lib/features/tasks/presentation/all_tasks_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../application/all_tasks_view_model.dart';
import '../domain/task.dart';
import '../domain/task_status.dart';
import 'widgets/task_card.dart';

class AllTasksScreen extends ConsumerWidget {
  const AllTasksScreen({super.key});

  Future<bool> _confirmDelete(
      BuildContext context, AppLocalizations l10n) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.tasks_delete_confirm_title),
        content: Text(l10n.tasks_delete_confirm_body),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.cancel)),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.delete)),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.watch(allTasksViewModelProvider);

    return vm.viewData.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.tasks_title)),
        body: const LoadingWidget(),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(title: Text(l10n.tasks_title)),
        body: Center(child: Text(l10n.error_generic)),
      ),
      data: (data) {
        if (data == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.tasks_title)),
            body: Center(child: Text(l10n.error_generic)),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.tasks_title),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: _FilterBar(
                current: data.filter.status,
                onChanged: vm.setStatusFilter,
              ),
            ),
          ),
          body: data.tasks.isEmpty
              ? Center(
                  key: const Key('tasks_empty_state'),
                  child: Text(l10n.tasks_empty_title))
              : ListView.builder(
                  key: const Key('tasks_list'),
                  itemCount: data.tasks.length,
                  itemBuilder: (_, i) {
                    final task = data.tasks[i];
                    return Dismissible(
                      key: Key('dismissible_${task.id}'),
                      background: _FreezeBackground(l10n: l10n),
                      secondaryBackground: _DeleteBackground(l10n: l10n),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          await vm.toggleFreeze(task);
                          return false;
                        } else {
                          return _confirmDelete(context, l10n);
                        }
                      },
                      onDismissed: (direction) async {
                        if (direction == DismissDirection.endToStart) {
                          await vm.deleteTask(task);
                        }
                      },
                      child: TaskCard(
                        task: task,
                        onTap: () => context.go('/task/${task.id}'),
                      ),
                    );
                  },
                ),
          floatingActionButton: data.canCreate
              ? FloatingActionButton(
                  key: const Key('create_task_fab'),
                  tooltip: l10n.tasks_create_title,
                  onPressed: () => context.go(AppRoutes.createTask),
                  child: const Icon(Icons.add),
                )
              : null,
        );
      },
    );
  }
}

// ── Local widgets (no logic) ──────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.current, required this.onChanged});
  final TaskStatus current;
  final void Function(TaskStatus) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ChoiceChip(
          key: const Key('filter_active'),
          label: Text(l10n.tasks_section_active),
          selected: current == TaskStatus.active,
          onSelected: (_) => onChanged(TaskStatus.active),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          key: const Key('filter_frozen'),
          label: Text(l10n.tasks_section_frozen),
          selected: current == TaskStatus.frozen,
          onSelected: (_) => onChanged(TaskStatus.frozen),
        ),
      ],
    );
  }
}

class _FreezeBackground extends StatelessWidget {
  const _FreezeBackground({required this.l10n});
  final AppLocalizations l10n;
  @override
  Widget build(BuildContext context) => Container(
        color: Colors.blue.shade100,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        child: Row(children: [
          const Icon(Icons.pause_circle_outline),
          const SizedBox(width: 8),
          Text(l10n.tasks_action_freeze),
        ]),
      );
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground({required this.l10n});
  final AppLocalizations l10n;
  @override
  Widget build(BuildContext context) => Container(
        color: Colors.red.shade100,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Row(children: [
          const Spacer(),
          const Icon(Icons.delete_outline),
          const SizedBox(width: 8),
          Text(l10n.delete),
        ]),
      );
}
```

- [ ] **Step 3: Create unit test**

```dart
// test/unit/features/tasks/all_tasks_view_model_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/tasks/application/all_tasks_view_model.dart';
import 'package:toka/features/tasks/domain/task_status.dart';
// ... fakes

void main() {
  group('AllTasksFilterNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });
    tearDown(() => container.dispose());

    test('initial status is active', () {
      expect(
        container.read(allTasksFilterNotifierProvider).status,
        TaskStatus.active,
      );
    });

    test('setStatus updates status', () {
      container
          .read(allTasksFilterNotifierProvider.notifier)
          .setStatus(TaskStatus.frozen);
      expect(
        container.read(allTasksFilterNotifierProvider).status,
        TaskStatus.frozen,
      );
    });

    test('setAssignee updates assigneeUid', () {
      container
          .read(allTasksFilterNotifierProvider.notifier)
          .setAssignee('uid123');
      expect(
        container.read(allTasksFilterNotifierProvider).assigneeUid,
        'uid123',
      );
    });
  });

  group('AllTasksViewModel — toggleFreeze', () {
    test('calls freezeTask when task is active', () async {
      // Set up container with mocked tasksRepositoryProvider
      // create task with status=active
      // call vm.toggleFreeze(task)
      // verify repo.freezeTask called
    });

    test('calls unfreezeTask when task is frozen', () async {
      // Similar: status=frozen → unfreezeTask
    });
  });
}
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/tasks/application/all_tasks_view_model.dart \
        lib/features/tasks/presentation/all_tasks_screen.dart \
        test/unit/features/tasks/all_tasks_view_model_test.dart
git commit -m "feat(mvvm): AllTasksViewModel — filter notifier + computed provider"
```

---

## Task 6: CreateEditTaskViewModel

**Pattern:** Family notifier-implements-interface + typed family provider.  
**Why family:** The ViewModel is parametrized by `editTaskId` (nullable). When `editTaskId != null`, `build()` fetches the task and populates the form. The screen remains `ConsumerStatefulWidget` only for `TextEditingController`s.

**Files:**
- Create: `lib/features/tasks/application/create_edit_task_view_model.dart`
- Create: `test/unit/features/tasks/create_edit_task_view_model_test.dart`
- Modify: `lib/features/tasks/presentation/create_edit_task_screen.dart`

- [ ] **Step 1: Create `create_edit_task_view_model.dart`**

```dart
// lib/features/tasks/application/create_edit_task_view_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_provider.dart';
import '../../homes/application/current_home_provider.dart';
import '../domain/recurrence_rule.dart';
import '../domain/task_status.dart';
import 'task_form_provider.dart';
import 'tasks_provider.dart';

part 'create_edit_task_view_model.freezed.dart';
part 'create_edit_task_view_model.g.dart';

// ─────────────────────────────────────────────
// Private VM state
// ─────────────────────────────────────────────

@freezed
class _CreateEditVMState with _$_CreateEditVMState {
  const factory _CreateEditVMState({
    @Default(false) bool savedSuccessfully,
    // Signals the screen to sync text controllers after edit load
    String? loadedTitle,
    String? loadedDescription,
  }) = __CreateEditVMState;
}

// ─────────────────────────────────────────────
// Contract
// ─────────────────────────────────────────────

abstract class CreateEditTaskViewModel {
  bool get isEditing;
  TaskFormState get formState;
  bool get savedSuccessfully;
  String? get loadedTitle;
  String? get loadedDescription;

  void setTitle(String v);
  void setDescription(String v);
  void setVisual(String kind, String value);
  void setRecurrenceRule(RecurrenceRule rule);
  void setAssignmentMode(String mode);
  void setAssignmentOrder(List<String> order);
  void setDifficultyWeight(double v);
  Future<void> save();
}

// ─────────────────────────────────────────────
// Notifier (family — parametrized by editTaskId)
// ─────────────────────────────────────────────

@riverpod
class CreateEditTaskViewModelNotifier
    extends _$CreateEditTaskViewModelNotifier
    implements CreateEditTaskViewModel {

  TaskFormNotifier get _form => ref.read(taskFormNotifierProvider.notifier);

  @override
  _CreateEditVMState build(String? editTaskId) {
    if (editTaskId != null) {
      _loadForEdit(editTaskId);
    } else {
      _form.initCreate();
    }
    return const _CreateEditVMState();
  }

  Future<void> _loadForEdit(String taskId) async {
    final homeId = ref.read(currentHomeProvider).valueOrNull?.id;
    if (homeId == null) return;
    final task =
        await ref.read(tasksRepositoryProvider).fetchTask(homeId, taskId);
    _form.initEdit(task);
    state = state.copyWith(
      loadedTitle: task.title,
      loadedDescription: task.description ?? '',
    );
  }

  @override bool get isEditing => ref.read(taskFormNotifierProvider).mode == TaskFormMode.edit;
  @override TaskFormState get formState => ref.read(taskFormNotifierProvider);
  @override bool get savedSuccessfully => state.savedSuccessfully;
  @override String? get loadedTitle => state.loadedTitle;
  @override String? get loadedDescription => state.loadedDescription;

  @override void setTitle(String v) => _form.setTitle(v);
  @override void setDescription(String v) => _form.setDescription(v);
  @override void setVisual(String kind, String value) => _form.setVisual(kind, value);
  @override void setRecurrenceRule(RecurrenceRule rule) => _form.setRecurrenceRule(rule);
  @override void setAssignmentMode(String mode) => _form.setAssignmentMode(mode);
  @override void setAssignmentOrder(List<String> order) => _form.setAssignmentOrder(order);
  @override void setDifficultyWeight(double v) => _form.setDifficultyWeight(v);

  @override
  Future<void> save() async {
    final homeId = ref.read(currentHomeProvider).valueOrNull?.id;
    final uid =
        ref.read(authProvider).whenOrNull(authenticated: (u) => u.uid) ?? '';
    if (homeId == null) return;
    final taskId = await _form.save(homeId, uid);
    if (taskId != null) {
      state = state.copyWith(savedSuccessfully: true);
    }
  }
}

// ─────────────────────────────────────────────
// Typed family provider
// ─────────────────────────────────────────────

@riverpod
CreateEditTaskViewModel createEditTaskViewModel(
  CreateEditTaskViewModelRef ref,
  String? editTaskId,
) {
  ref.watch(createEditTaskViewModelNotifierProvider(editTaskId));
  ref.watch(taskFormNotifierProvider); // re-expose form changes
  return ref.read(createEditTaskViewModelNotifierProvider(editTaskId).notifier);
}
```

- [ ] **Step 2: Update `create_edit_task_screen.dart`**

```dart
// lib/features/tasks/presentation/create_edit_task_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../application/create_edit_task_view_model.dart';
import 'widgets/assignment_form.dart';
import 'widgets/recurrence_form.dart';
import 'widgets/task_visual_picker.dart';

class CreateEditTaskScreen extends ConsumerStatefulWidget {
  const CreateEditTaskScreen({super.key, this.editTaskId});
  final String? editTaskId;

  @override
  ConsumerState<CreateEditTaskScreen> createState() =>
      _CreateEditTaskScreenState();
}

class _CreateEditTaskScreenState extends ConsumerState<CreateEditTaskScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.watch(createEditTaskViewModelProvider(widget.editTaskId));

    // Sync controllers when task is loaded for edit
    ref.listen<CreateEditTaskViewModel>(
      createEditTaskViewModelProvider(widget.editTaskId),
      (prev, next) {
        if (next.loadedTitle != null &&
            next.loadedTitle != prev?.loadedTitle) {
          _titleController.text = next.loadedTitle!;
        }
        if (next.loadedDescription != null &&
            next.loadedDescription != prev?.loadedDescription) {
          _descController.text = next.loadedDescription!;
        }
        if (next.savedSuccessfully) {
          Navigator.of(context).pop();
        }
      },
    );

    final formState = vm.formState;
    final titleError = formState.fieldErrors['title'];
    final assigneesError = formState.fieldErrors['assignees'];

    return Scaffold(
      appBar: AppBar(
        title: Text(vm.isEditing
            ? l10n.tasks_edit_title
            : l10n.tasks_create_title),
        actions: [
          if (formState.isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              key: const Key('save_task_button'),
              onPressed: vm.save,
              child: Text(l10n.save),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TaskVisualPicker(
            selectedKind: formState.visualKind,
            selectedValue: formState.visualValue,
            onChanged: vm.setVisual,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('task_title_field'),
            controller: _titleController,
            decoration: InputDecoration(
              labelText: l10n.tasks_field_title_hint,
              border: const OutlineInputBorder(),
              errorText: titleError != null
                  ? _titleErrorText(titleError, l10n)
                  : null,
            ),
            onChanged: vm.setTitle,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('task_desc_field'),
            controller: _descController,
            decoration: InputDecoration(
              labelText: l10n.tasks_field_description_hint,
              border: const OutlineInputBorder(),
            ),
            maxLines: 2,
            onChanged: vm.setDescription,
          ),
          const SizedBox(height: 16),
          const RecurrenceForm(key: Key('recurrence_form')),
          const SizedBox(height: 16),
          AssignmentForm(
            availableMembers: const [], // TODO: wire home members
            selectedOrder: formState.assignmentOrder,
            onChanged: vm.setAssignmentOrder,
          ),
          if (assigneesError != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.tasks_validation_no_assignees,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error, fontSize: 12),
              ),
            ),
          const SizedBox(height: 16),
          Text(l10n.tasks_field_difficulty,
              style: Theme.of(context).textTheme.titleSmall),
          Slider(
            key: const Key('difficulty_slider'),
            value: formState.difficultyWeight,
            min: 0.5,
            max: 3.0,
            divisions: 5,
            label: formState.difficultyWeight.toStringAsFixed(1),
            onChanged: vm.setDifficultyWeight,
          ),
          if (formState.globalError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.error_generic,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                key: const Key('task_form_error'),
              ),
            ),
        ],
      ),
    );
  }

  String? _titleErrorText(String code, AppLocalizations l10n) {
    if (code == 'tasks_validation_title_empty') {
      return l10n.tasks_validation_title_empty;
    }
    if (code == 'tasks_validation_title_too_long') {
      return l10n.tasks_validation_title_too_long;
    }
    return null;
  }
}
```

- [ ] **Step 3: Create unit test**

```dart
// test/unit/features/tasks/create_edit_task_view_model_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/tasks/application/create_edit_task_view_model.dart';
import 'package:toka/features/tasks/application/task_form_provider.dart';
import 'package:toka/features/tasks/application/tasks_provider.dart';
import 'package:toka/features/tasks/domain/tasks_repository.dart';
// ... fakes

class _MockTasksRepo extends Mock implements TasksRepository {}

void main() {
  group('CreateEditTaskViewModel — create mode', () {
    test('isEditing is false in create mode', () {
      final container = ProviderContainer(overrides: [
        // minimal overrides
      ]);
      addTearDown(container.dispose);
      final vm = container.read(createEditTaskViewModelProvider(null));
      expect(vm.isEditing, isFalse);
    });

    test('savedSuccessfully starts false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final vm = container.read(createEditTaskViewModelProvider(null));
      expect(vm.savedSuccessfully, isFalse);
    });

    test('setTitle propagates to TaskFormNotifier', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(createEditTaskViewModelProvider(null))
          .setTitle('Limpiar baño');
      expect(container.read(taskFormNotifierProvider).title, 'Limpiar baño');
    });
  });

  group('CreateEditTaskViewModel — edit mode', () {
    test('loadedTitle is set after _loadForEdit completes', () async {
      final mockRepo = _MockTasksRepo();
      // Stub fetchTask to return a task
      // verify loadedTitle == task.title after build completes
    });
  });
}
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/tasks/application/create_edit_task_view_model.dart \
        lib/features/tasks/presentation/create_edit_task_screen.dart \
        test/unit/features/tasks/create_edit_task_view_model_test.dart
git commit -m "feat(mvvm): CreateEditTaskViewModel — family notifier, edit init extracted"
```

---

## Task 7: TaskDetailViewModel

**Pattern:** Computed family provider + impl class.  
**Why family:** Parametrized by `taskId`. Combines `homeTasksProvider` + `userMembershipsProvider` + `upcomingOccurrencesProvider` into a single `TaskDetailViewData`.

**Files:**
- Create: `lib/features/tasks/application/task_detail_view_model.dart`
- Create: `test/unit/features/tasks/task_detail_view_model_test.dart`
- Modify: `lib/features/tasks/presentation/task_detail_screen.dart`

- [ ] **Step 1: Create `task_detail_view_model.dart`**

```dart
// lib/features/tasks/application/task_detail_view_model.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_provider.dart';
import '../../homes/application/current_home_provider.dart';
import '../../homes/application/homes_provider.dart';
import '../../homes/domain/home_membership.dart';
import '../domain/task.dart';
import 'recurrence_provider.dart';
import 'tasks_provider.dart';

part 'task_detail_view_model.g.dart';

// ─────────────────────────────────────────────
// View data
// ─────────────────────────────────────────────

class TaskDetailViewData {
  const TaskDetailViewData({
    required this.task,
    required this.canEdit,
    required this.upcomingOccurrences,
  });
  final Task task;
  final bool canEdit;
  final List<DateTime> upcomingOccurrences;
}

// ─────────────────────────────────────────────
// Contract
// ─────────────────────────────────────────────

abstract class TaskDetailViewModel {
  AsyncValue<TaskDetailViewData?> get viewData;
}

// ─────────────────────────────────────────────
// Impl
// ─────────────────────────────────────────────

class _TaskDetailViewModelImpl implements TaskDetailViewModel {
  const _TaskDetailViewModelImpl({required this.viewData});
  @override final AsyncValue<TaskDetailViewData?> viewData;
}

// ─────────────────────────────────────────────
// Provider (family)
// ─────────────────────────────────────────────

@riverpod
TaskDetailViewModel taskDetailViewModel(
    TaskDetailViewModelRef ref, String taskId) {
  final homeAsync = ref.watch(currentHomeProvider);
  final authState = ref.watch(authProvider);
  final uid = authState.whenOrNull(authenticated: (u) => u.uid) ?? '';

  final viewData = homeAsync.whenData((home) {
    if (home == null) return null;

    final tasksAsync = ref.watch(homeTasksProvider(home.id));
    final tasks = tasksAsync.valueOrNull ?? [];
    final task = tasks.where((t) => t.id == taskId).cast<Task?>().firstOrNull;
    if (task == null) return null;

    final membershipsAsync =
        uid.isNotEmpty ? ref.watch(userMembershipsProvider(uid)) : null;
    final memberships = membershipsAsync?.valueOrNull ?? [];
    final myMembership = memberships
        .where((m) => m.homeId == home.id)
        .cast<HomeMembership?>()
        .firstOrNull;
    final myRole = myMembership?.role;
    final canEdit =
        myRole == MemberRole.owner || myRole == MemberRole.admin;

    final upcoming =
        ref.watch(upcomingOccurrencesProvider(task.recurrenceRule));

    return TaskDetailViewData(
      task: task,
      canEdit: canEdit,
      upcomingOccurrences: upcoming.take(3).toList(),
    );
  });

  return _TaskDetailViewModelImpl(viewData: viewData);
}
```

- [ ] **Step 2: Update `task_detail_screen.dart`**

```dart
// lib/features/tasks/presentation/task_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../application/task_detail_view_model.dart';
import '../domain/task_status.dart';

class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({super.key, required this.taskId});
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.watch(taskDetailViewModelProvider(taskId));

    return vm.viewData.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const LoadingWidget(),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.error_generic)),
      ),
      data: (data) {
        if (data == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(l10n.error_generic)),
          );
        }

        final task = data.task;

        return Scaffold(
          appBar: AppBar(
            title: Text(task.title),
            actions: [
              if (data.canEdit)
                IconButton(
                  key: const Key('edit_task_button'),
                  icon: const Icon(Icons.edit),
                  onPressed: () => context.go('/task/$taskId/edit'),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  if (task.visualKind == 'emoji')
                    Text(task.visualValue,
                        style: const TextStyle(fontSize: 48))
                  else
                    const Icon(Icons.task_alt, size: 48),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(task.title,
                            style:
                                Theme.of(context).textTheme.headlineSmall),
                        if (task.description != null)
                          Text(task.description!),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              if (task.status == TaskStatus.frozen)
                const Chip(
                  key: Key('frozen_chip'),
                  label: Text('Congelada'),
                  avatar: Icon(Icons.pause_circle_outline),
                ),
              ListTile(
                key: const Key('current_assignee_tile'),
                leading: const Icon(Icons.person),
                title: Text(l10n.tasks_detail_assignment_order),
                subtitle: Text(task.currentAssigneeUid ?? '—'),
              ),
              ListTile(
                key: const Key('next_due_tile'),
                leading: const Icon(Icons.schedule),
                title: Text(l10n.tasks_detail_next_occurrences),
                subtitle: Text(
                  DateFormat.yMMMd()
                      .add_Hm()
                      .format(task.nextDueAt.toLocal()),
                ),
              ),
              ListTile(
                key: const Key('difficulty_tile'),
                leading: const Icon(Icons.fitness_center),
                title: Text(l10n.tasks_field_difficulty),
                subtitle:
                    Text(task.difficultyWeight.toStringAsFixed(1)),
              ),
              const Divider(height: 32),
              Text(l10n.tasks_detail_next_occurrences,
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              ...data.upcomingOccurrences.map(
                (d) => ListTile(
                  dense: true,
                  title: Text(
                    DateFormat.yMMMd().add_Hm().format(d.toLocal()),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 3: Create unit test**

```dart
// test/unit/features/tasks/task_detail_view_model_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/tasks/application/task_detail_view_model.dart';
// ... fakes

void main() {
  group('TaskDetailViewModel', () {
    test('viewData is data(null) when task not found in list', () {
      // Set up homeTasksProvider returning empty list
      // taskDetailViewModelProvider('nonexistent')
      // expect viewData to be AsyncData(null)
    });

    test('canEdit is true for owner', () {
      // Set up home, task, membership with owner role
      // expect data.canEdit == true
    });

    test('canEdit is false for regular member', () {
      // Set up home, task, membership with member role
      // expect data.canEdit == false
    });
  });
}
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/tasks/application/task_detail_view_model.dart \
        lib/features/tasks/presentation/task_detail_screen.dart \
        test/unit/features/tasks/task_detail_view_model_test.dart
git commit -m "feat(mvvm): TaskDetailViewModel — family computed provider"
```

---

## Final Step: Run all tests

- [ ] **Run unit tests for this plan**

```bash
flutter test test/unit/features/onboarding/onboarding_view_model_test.dart \
             test/unit/features/homes/my_homes_view_model_test.dart \
             test/unit/features/homes/home_settings_view_model_test.dart \
             test/unit/features/tasks/today_view_model_test.dart \
             test/unit/features/tasks/all_tasks_view_model_test.dart \
             test/unit/features/tasks/create_edit_task_view_model_test.dart \
             test/unit/features/tasks/task_detail_view_model_test.dart
```

- [ ] **Run code generation**

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Run static analysis**

```bash
flutter analyze
```

---

## Pruebas manuales requeridas

Una vez implementado, verificar manualmente:

1. **Onboarding:** Instalar fresh → flujo completo desde welcome hasta crear/unirse a hogar → navega a home. Reinstalar → progreso guardado (SharedPreferences). Usuario con onboarding ya completo → salta directo a home.
2. **MyHomes:** Abrir pantalla de hogares → lista carga. Tocar un hogar → se selecciona (check verde) y cierra la pantalla.
3. **HomeSettings:** Ver pantalla ajustes del hogar → nombre, plan y sección de peligro visibles. Confirmar "salir del hogar" → diálogo, cancelar no cierra, confirmar sale.
4. **Today:** Pantalla de hoy carga tareas agrupadas por recurrencia. Overdue aparece primero. Completar tarea → diálogo → confirma → desaparece. Pasar turno → diálogo con compliance stats → confirma.
5. **AllTasks:** Filtro Activas/Congeladas funciona sin reiniciar el provider. Swipe izquierda → confirmar borrar → se elimina. Swipe derecha → congela/descongela.
6. **CreateEditTask:** Crear tarea → guardar → vuelve a la lista. Editar tarea → título y descripción se rellenan automáticamente → guardar → vuelve.
7. **TaskDetail:** Detalle muestra emoji, asignado, próxima fecha, dificultad y próximas ocurrencias. Botón editar visible solo para owner/admin.
