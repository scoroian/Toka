# MVVM Refactor — Plan 03: Members + Profile + History + Settings + Subscription

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create typed ViewModels for all remaining screens — Members (3), Profile (2), Notifications (1), History (1), Settings (1), Subscription (4). Move all business logic out of widgets.

**Architecture:** Same patterns established in Plans 01–02. See `docs/superpowers/specs/2026-04-07-mvvm-skin-design.md`.

**Depends on:** Plans 01 and 02 completed.

---

## File Map

| Action  | File |
|---------|------|
| Create  | `lib/features/members/application/members_view_model.dart` |
| Create  | `lib/features/members/application/member_profile_view_model.dart` |
| Create  | `lib/features/members/application/vacation_view_model.dart` |
| Create  | `lib/features/profile/application/own_profile_view_model.dart` |
| Create  | `lib/features/profile/application/edit_profile_view_model.dart` |
| Create  | `lib/features/notifications/application/notification_settings_view_model.dart` |
| Create  | `lib/features/history/application/history_view_model.dart` |
| Create  | `lib/features/settings/application/settings_view_model.dart` |
| Create  | `lib/features/subscription/application/paywall_view_model.dart` |
| Create  | `lib/features/subscription/application/downgrade_planner_view_model.dart` |
| Create  | `lib/features/subscription/application/subscription_management_view_model.dart` |
| Create  | `lib/features/subscription/application/rescue_view_model.dart` |
| Modify  | `lib/features/members/presentation/members_screen.dart` |
| Modify  | `lib/features/members/presentation/member_profile_screen.dart` |
| Modify  | `lib/features/members/presentation/vacation_screen.dart` |
| Modify  | `lib/features/profile/presentation/own_profile_screen.dart` |
| Modify  | `lib/features/profile/presentation/edit_profile_screen.dart` |
| Modify  | `lib/features/notifications/presentation/notification_settings_screen.dart` |
| Modify  | `lib/features/history/presentation/history_screen.dart` |
| Modify  | `lib/features/settings/presentation/settings_screen.dart` |
| Modify  | `lib/features/subscription/presentation/paywall_screen.dart` |
| Modify  | `lib/features/subscription/presentation/downgrade_planner_screen.dart` |
| Modify  | `lib/features/subscription/presentation/subscription_management_screen.dart` |
| Modify  | `lib/features/subscription/presentation/rescue_screen.dart` |
| Create  | `test/unit/features/members/members_view_model_test.dart` |
| Create  | `test/unit/features/members/member_profile_view_model_test.dart` |
| Create  | `test/unit/features/members/vacation_view_model_test.dart` |
| Create  | `test/unit/features/profile/own_profile_view_model_test.dart` |
| Create  | `test/unit/features/profile/edit_profile_view_model_test.dart` |
| Create  | `test/unit/features/notifications/notification_settings_view_model_test.dart` |
| Create  | `test/unit/features/history/history_view_model_test.dart` |
| Create  | `test/unit/features/settings/settings_view_model_test.dart` |
| Create  | `test/unit/features/subscription/paywall_view_model_test.dart` |
| Create  | `test/unit/features/subscription/downgrade_planner_view_model_test.dart` |

---

## Task 1: MembersViewModel

**Pattern:** Computed provider + impl class.  
**What moves:** Separates members into active/frozen lists, computes `canInvite` and `homeId`. Screen becomes `ConsumerWidget` instead of `ConsumerWidget` (already is one — no structural change needed).

- [ ] **Step 1: Create `members_view_model.dart`**

```dart
// lib/features/members/application/members_view_model.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_provider.dart';
import '../../homes/application/current_home_provider.dart';
import '../../homes/application/homes_provider.dart';
import '../../homes/domain/home_membership.dart';
import '../domain/member.dart';
import 'members_provider.dart';

part 'members_view_model.g.dart';

// ── View data ───────────────────────────────────

class MembersViewData {
  const MembersViewData({
    required this.activeMembers,
    required this.frozenMembers,
    required this.canInvite,
    required this.homeId,
  });
  final List<Member> activeMembers;
  final List<Member> frozenMembers;
  final bool canInvite;
  final String homeId;
}

// ── Contract ────────────────────────────────────

abstract class MembersViewModel {
  AsyncValue<MembersViewData?> get viewData;
}

// ── Impl ────────────────────────────────────────

class _MembersViewModelImpl implements MembersViewModel {
  const _MembersViewModelImpl({required this.viewData});
  @override final AsyncValue<MembersViewData?> viewData;
}

// ── Provider ────────────────────────────────────

@riverpod
MembersViewModel membersViewModel(MembersViewModelRef ref) {
  final homeAsync = ref.watch(currentHomeProvider);
  final auth = ref.watch(authProvider);
  final uid = auth.whenOrNull(authenticated: (u) => u.uid) ?? '';

  final viewData = homeAsync.whenData((home) {
    if (home == null) return null;

    final membershipsAsync =
        uid.isNotEmpty ? ref.watch(userMembershipsProvider(uid)) : null;
    final myMembership = membershipsAsync?.valueOrNull
        ?.where((m) => m.homeId == home.id)
        .cast<HomeMembership?>()
        .firstOrNull;
    final canInvite = myMembership?.role == MemberRole.owner ||
        myMembership?.role == MemberRole.admin;

    final membersAsync = ref.watch(homeMembersProvider(home.id));
    final allMembers = membersAsync.valueOrNull ?? [];

    return MembersViewData(
      activeMembers:
          allMembers.where((m) => m.status == MemberStatus.active).toList(),
      frozenMembers:
          allMembers.where((m) => m.status == MemberStatus.frozen).toList(),
      canInvite: canInvite,
      homeId: home.id,
    );
  });

  return _MembersViewModelImpl(viewData: viewData);
}
```

- [ ] **Step 2: Update `members_screen.dart`**

Replace all direct provider access with `ref.watch(membersViewModelProvider)`. The screen reads `vm.viewData`, uses `data.activeMembers`, `data.frozenMembers`, `data.canInvite`, `data.homeId`. Passes `homeId` to `InviteMemberSheet`.

- [ ] **Step 3: Unit test + commit**

```bash
git add lib/features/members/application/members_view_model.dart \
        lib/features/members/presentation/members_screen.dart \
        test/unit/features/members/members_view_model_test.dart
git commit -m "feat(mvvm): MembersViewModel — computed provider"
```

---

## Task 2: MemberProfileViewModel

**Pattern:** Computed family provider (homeId, memberUid). Moves the `memberDetail` inline provider from `member_profile_screen.dart` into the ViewModel file.

- [ ] **Step 1: Create `member_profile_view_model.dart`**

```dart
// lib/features/members/application/member_profile_view_model.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_provider.dart';
import '../../profile/application/member_radar_provider.dart';
import '../../profile/presentation/widgets/radar_chart_widget.dart';
import '../domain/member.dart';
import 'members_provider.dart';

part 'member_profile_view_model.g.dart';

// ── View data ───────────────────────────────────

class MemberProfileViewData {
  const MemberProfileViewData({
    required this.member,
    required this.isSelf,
    required this.visiblePhone,
    required this.compliancePct,
    required this.radarAsync,
  });
  final Member member;
  final bool isSelf;
  final String? visiblePhone;
  final String compliancePct;
  final AsyncValue<List<RadarEntry>> radarAsync;
}

// ── Contract ────────────────────────────────────

abstract class MemberProfileViewModel {
  AsyncValue<MemberProfileViewData?> get viewData;
}

// ── Impl ────────────────────────────────────────

class _MemberProfileViewModelImpl implements MemberProfileViewModel {
  const _MemberProfileViewModelImpl({required this.viewData});
  @override final AsyncValue<MemberProfileViewData?> viewData;
}

// ── Moved from member_profile_screen.dart ───────

@riverpod
Future<Member> memberDetail(
    MemberDetailRef ref, String homeId, String uid) async {
  return ref.watch(membersRepositoryProvider).fetchMember(homeId, uid);
}

// ── Provider ────────────────────────────────────

@riverpod
MemberProfileViewModel memberProfileViewModel(
  MemberProfileViewModelRef ref, {
  required String homeId,
  required String memberUid,
}) {
  final auth = ref.watch(authProvider);
  final currentUid =
      auth.whenOrNull(authenticated: (u) => u.uid) ?? '';
  final isSelf = currentUid == memberUid;

  final memberAsync = ref.watch(memberDetailProvider(homeId, memberUid));
  final radarAsync =
      ref.watch(memberRadarProvider(homeId: homeId, uid: memberUid));

  final viewData = memberAsync.whenData((member) {
    if (member == null) return null;
    return MemberProfileViewData(
      member: member,
      isSelf: isSelf,
      visiblePhone: member.phoneForViewer(isSelf: isSelf),
      compliancePct: (member.complianceRate * 100).toStringAsFixed(1),
      radarAsync: radarAsync,
    );
  });

  return _MemberProfileViewModelImpl(viewData: viewData);
}
```

- [ ] **Step 2: Update `member_profile_screen.dart`**

Remove the inline `@riverpod Future<Member> memberDetail(...)` declaration and its `part '...g.dart'` file. Replace all direct provider access with `ref.watch(memberProfileViewModelProvider(homeId: homeId, uid: memberUid))`.

- [ ] **Step 3: Unit test + commit**

```bash
git add lib/features/members/application/member_profile_view_model.dart \
        lib/features/members/presentation/member_profile_screen.dart \
        test/unit/features/members/member_profile_view_model_test.dart
git commit -m "feat(mvvm): MemberProfileViewModel — family computed provider, memberDetail moved"
```

---

## Task 3: VacationViewModel

**Pattern:** Notifier implements interface (family, keyed by `homeId` + `uid`).  
**What moves:** `_isActive`, `_startDate`, `_endDate`, `_initialized` from widget state into the Notifier. Screen keeps only `_reasonController` (TextEditingController) and the date picker dialogs.

- [ ] **Step 1: Create `vacation_view_model.dart`**

```dart
// lib/features/members/application/vacation_view_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/vacation.dart';
import 'vacation_provider.dart';

part 'vacation_view_model.freezed.dart';
part 'vacation_view_model.g.dart';

// ── Contract ─────────────────────────────────────

abstract class VacationViewModel {
  bool get isInitialized;
  bool get isActive;
  DateTime? get startDate;
  DateTime? get endDate;
  bool get savedSuccessfully;

  void setActive(bool v);
  void setStartDate(DateTime d);
  void setEndDate(DateTime d);
  Future<void> save({required String? reason});
}

// ── Private state ─────────────────────────────────

@freezed
class _VacationVMState with _$_VacationVMState {
  const factory _VacationVMState({
    @Default(false) bool isInitialized,
    @Default(false) bool isActive,
    DateTime? startDate,
    DateTime? endDate,
    @Default(false) bool savedSuccessfully,
  }) = __VacationVMState;
}

// ── Notifier ──────────────────────────────────────

@riverpod
class VacationViewModelNotifier extends _$VacationViewModelNotifier
    implements VacationViewModel {
  @override
  _VacationVMState build(String homeId, String uid) {
    // Watch and initialize from existing vacation when available
    final vacationAsync =
        ref.watch(memberVacationProvider(homeId: homeId, uid: uid));
    vacationAsync.whenData((v) {
      if (!state.isInitialized && v != null) {
        // Use a post-build callback pattern via ref.listenSelf
        Future.microtask(() {
          state = state.copyWith(
            isInitialized: true,
            isActive: v.isActive,
            startDate: v.startDate,
            endDate: v.endDate,
          );
        });
      } else if (!state.isInitialized && v == null) {
        Future.microtask(() =>
            state = state.copyWith(isInitialized: true));
      }
    });
    return const _VacationVMState();
  }

  @override bool get isInitialized => state.isInitialized;
  @override bool get isActive => state.isActive;
  @override DateTime? get startDate => state.startDate;
  @override DateTime? get endDate => state.endDate;
  @override bool get savedSuccessfully => state.savedSuccessfully;

  @override void setActive(bool v) => state = state.copyWith(isActive: v);
  @override void setStartDate(DateTime d) => state = state.copyWith(startDate: d);
  @override void setEndDate(DateTime d) => state = state.copyWith(endDate: d);

  @override
  Future<void> save({required String? reason}) async {
    final vacation = Vacation(
      uid: uid,
      homeId: homeId,
      isActive: state.isActive,
      startDate: state.startDate,
      endDate: state.endDate,
      reason: reason,
      createdAt: DateTime.now(),
    );
    await ref
        .read(vacationNotifierProvider.notifier)
        .save(homeId, uid, vacation);
    state = state.copyWith(savedSuccessfully: true);
  }
}

// ── Typed provider ──────────────────────────────

@riverpod
VacationViewModel vacationViewModel(
    VacationViewModelRef ref, String homeId, String uid) {
  ref.watch(vacationViewModelNotifierProvider(homeId, uid));
  return ref.read(vacationViewModelNotifierProvider(homeId, uid).notifier);
}
```

- [ ] **Step 2: Update `vacation_screen.dart`**

```dart
// lib/features/members/presentation/vacation_screen.dart
class VacationScreen extends ConsumerStatefulWidget {
  // homeId + uid params remain
}

class _VacationScreenState extends ConsumerState<VacationScreen> {
  final _reasonController = TextEditingController(); // only kept here

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart, VacationViewModel vm) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? vm.startDate : vm.endDate) ?? now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    if (isStart) {
      vm.setStartDate(picked);
    } else {
      vm.setEndDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.watch(vacationViewModelProvider(widget.homeId, widget.uid));
    final fmt = DateFormat.yMd();

    ref.listen<VacationViewModel>(
      vacationViewModelProvider(widget.homeId, widget.uid),
      (_, next) {
        if (next.savedSuccessfully) Navigator.of(context).pop();
      },
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.vacation_title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            key: const Key('vacation_toggle'),
            title: Text(l10n.vacation_toggle_label),
            value: vm.isActive,
            onChanged: vm.setActive,
          ),
          if (vm.isActive)
            Column(
              key: const Key('vacation_date_pickers'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(l10n.vacation_start_date),
                  subtitle: Text(vm.startDate != null ? fmt.format(vm.startDate!) : '—'),
                  onTap: () => _pickDate(true, vm),
                ),
                ListTile(
                  leading: const Icon(Icons.event_available),
                  title: Text(l10n.vacation_end_date),
                  subtitle: Text(vm.endDate != null ? fmt.format(vm.endDate!) : '—'),
                  onTap: () => _pickDate(false, vm),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _reasonController,
                  decoration: InputDecoration(
                    labelText: l10n.vacation_reason,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('btn_save_vacation'),
            onPressed: () => vm.save(reason: _reasonController.text.trim().isEmpty
                ? null
                : _reasonController.text.trim()),
            child: Text(l10n.vacation_save),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Unit test + commit**

```dart
// test/unit/features/members/vacation_view_model_test.dart
void main() {
  group('VacationViewModel', () {
    test('isActive starts false', () { /* ... */ });
    test('setActive updates isActive', () { /* ... */ });
    test('setStartDate updates startDate', () { /* ... */ });
    test('save calls vacationNotifier.save and sets savedSuccessfully', () async { /* ... */ });
  });
}
```

```bash
git add lib/features/members/application/vacation_view_model.dart \
        lib/features/members/presentation/vacation_screen.dart \
        test/unit/features/members/vacation_view_model_test.dart
git commit -m "feat(mvvm): VacationViewModel — family notifier, date state extracted"
```

---

## Task 4: OwnProfileViewModel

**Pattern:** Computed provider.  
**What moves:** `signOut()` action + `hasEmailPassword` computation.

- [ ] **Step 1: Create `own_profile_view_model.dart`**

```dart
// lib/features/profile/application/own_profile_view_model.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_provider.dart';
import '../../homes/application/current_home_provider.dart';
import '../presentation/widgets/radar_chart_widget.dart';
import 'member_radar_provider.dart';
import 'profile_provider.dart';

part 'own_profile_view_model.g.dart';

// ── View data ──────────────────────────────────

class OwnProfileViewData {
  const OwnProfileViewData({
    required this.profile,
    required this.hasEmailPassword,
    required this.radarAsync,
  });
  final UserProfile profile;
  final bool hasEmailPassword;
  final AsyncValue<List<RadarEntry>> radarAsync;
}

// ── Contract ────────────────────────────────────

abstract class OwnProfileViewModel {
  AsyncValue<OwnProfileViewData?> get viewData;
  Future<void> signOut();
}

// ── Impl ────────────────────────────────────────

class _OwnProfileViewModelImpl implements OwnProfileViewModel {
  const _OwnProfileViewModelImpl({
    required this.viewData,
    required this.ref,
  });
  @override final AsyncValue<OwnProfileViewData?> viewData;
  final Ref ref;

  @override
  Future<void> signOut() =>
      ref.read(authProvider.notifier).signOut();
}

// ── Provider ────────────────────────────────────

@riverpod
OwnProfileViewModel ownProfileViewModel(OwnProfileViewModelRef ref) {
  final auth = ref.watch(authProvider);
  final uid = auth.whenOrNull(authenticated: (u) => u.uid) ?? '';
  final hasEmailPassword =
      auth.whenOrNull(authenticated: (u) => u.providers.contains('password')) ??
          false;
  final homeId = ref.watch(currentHomeProvider).valueOrNull?.id ?? '';

  if (uid.isEmpty) {
    return _OwnProfileViewModelImpl(
      viewData: const AsyncValue.data(null),
      ref: ref,
    );
  }

  final profileAsync = ref.watch(userProfileProvider(uid));
  final radarAsync = homeId.isNotEmpty
      ? ref.watch(memberRadarProvider(homeId: homeId, uid: uid))
      : const AsyncData<List<RadarEntry>>([]);

  final viewData = profileAsync.whenData((profile) => OwnProfileViewData(
        profile: profile,
        hasEmailPassword: hasEmailPassword,
        radarAsync: radarAsync,
      ));

  return _OwnProfileViewModelImpl(viewData: viewData, ref: ref);
}
```

- [ ] **Step 2: Update `own_profile_screen.dart`**

Replace direct auth/profile/radar watchers with `ref.watch(ownProfileViewModelProvider)`. The `signOut` call in `AccessManagementSection.onLogout` becomes `() async { await vm.signOut(); if (context.mounted) context.go(AppRoutes.login); }`.

- [ ] **Step 3: Unit test + commit**

```bash
git add lib/features/profile/application/own_profile_view_model.dart \
        lib/features/profile/presentation/own_profile_screen.dart \
        test/unit/features/profile/own_profile_view_model_test.dart
git commit -m "feat(mvvm): OwnProfileViewModel — computed provider, signOut extracted"
```

---

## Task 5: EditProfileViewModel

**Pattern:** Notifier implements interface.  
**What moves:** `_phoneVisible`, `_initialized`, `_save()` to ViewModel. Screen keeps TextEditingControllers, which are synced via `ref.listen` when `initialXxx` values appear.

- [ ] **Step 1: Create `edit_profile_view_model.dart`**

```dart
// lib/features/profile/application/edit_profile_view_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_provider.dart';
import 'profile_provider.dart';

part 'edit_profile_view_model.freezed.dart';
part 'edit_profile_view_model.g.dart';

// ── Contract ─────────────────────────────────────

abstract class EditProfileViewModel {
  bool get isInitialized;
  bool get phoneVisible;
  bool get isLoading;
  bool get savedSuccessfully;

  // For initial controller sync
  String? get initialNickname;
  String? get initialBio;
  String? get initialPhone;

  void setPhoneVisible(bool v);
  Future<void> save({
    required String nickname,
    required String bio,
    required String phone,
  });
}

// ── Private state ─────────────────────────────────

@freezed
class _EditProfileVMState with _$_EditProfileVMState {
  const factory _EditProfileVMState({
    @Default(false) bool isInitialized,
    @Default(false) bool phoneVisible,
    @Default(false) bool isLoading,
    @Default(false) bool savedSuccessfully,
    String? initialNickname,
    String? initialBio,
    String? initialPhone,
  }) = __EditProfileVMState;
}

// ── Notifier ──────────────────────────────────────

@riverpod
class EditProfileViewModelNotifier extends _$EditProfileViewModelNotifier
    implements EditProfileViewModel {
  @override
  _EditProfileVMState build() {
    final uid = ref.watch(authProvider).whenOrNull(authenticated: (u) => u.uid) ?? '';
    if (uid.isNotEmpty) {
      final profileAsync = ref.watch(userProfileProvider(uid));
      profileAsync.whenData((profile) {
        if (!state.isInitialized) {
          Future.microtask(() => state = state.copyWith(
                isInitialized: true,
                phoneVisible: profile.phoneVisibility == 'sameHomeMembers',
                initialNickname: profile.nickname,
                initialBio: profile.bio ?? '',
                initialPhone: profile.phone ?? '',
              ));
        }
      });
    }
    return const _EditProfileVMState();
  }

  @override bool get isInitialized => state.isInitialized;
  @override bool get phoneVisible => state.phoneVisible;
  @override bool get isLoading => state.isLoading;
  @override bool get savedSuccessfully => state.savedSuccessfully;
  @override String? get initialNickname => state.initialNickname;
  @override String? get initialBio => state.initialBio;
  @override String? get initialPhone => state.initialPhone;

  @override
  void setPhoneVisible(bool v) => state = state.copyWith(phoneVisible: v);

  @override
  Future<void> save({
    required String nickname,
    required String bio,
    required String phone,
  }) async {
    final uid = ref.read(authProvider).whenOrNull(authenticated: (u) => u.uid) ?? '';
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(profileEditorProvider.notifier).updateProfile(
            uid,
            nickname: nickname,
            bio: bio,
            phone: phone,
            phoneVisibility: state.phoneVisible ? 'sameHomeMembers' : 'hidden',
          );
      state = state.copyWith(isLoading: false, savedSuccessfully: true);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }
}

// ── Typed provider ───────────────────────────────

@riverpod
EditProfileViewModel editProfileViewModel(EditProfileViewModelRef ref) {
  ref.watch(editProfileViewModelNotifierProvider);
  return ref.read(editProfileViewModelNotifierProvider.notifier);
}
```

- [ ] **Step 2: Update `edit_profile_screen.dart`**

```dart
class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nicknameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.watch(editProfileViewModelProvider);

    // Sync controllers once on init
    ref.listen<EditProfileViewModel>(editProfileViewModelProvider, (prev, next) {
      if (next.initialNickname != null && prev?.isInitialized == false && next.isInitialized) {
        _nicknameController.text = next.initialNickname!;
        _bioController.text = next.initialBio ?? '';
        _phoneController.text = next.initialPhone ?? '';
      }
      if (next.savedSuccessfully) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.profile_saved)),
        );
        Navigator.of(context).pop();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile_edit),
        actions: [
          if (vm.isLoading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(
              key: const Key('save_profile_btn'),
              onPressed: () => vm.save(
                nickname: _nicknameController.text.trim(),
                bio: _bioController.text.trim(),
                phone: _phoneController.text.trim(),
              ),
              child: Text(l10n.save),
            ),
        ],
      ),
      body: !vm.isInitialized
          ? const LoadingWidget()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  key: const Key('nickname_field'),
                  controller: _nicknameController,
                  decoration: InputDecoration(
                    labelText: l10n.profile_nickname_label,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('bio_field'),
                  controller: _bioController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l10n.profile_bio_label,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('phone_field'),
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: l10n.profile_phone_label,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  key: const Key('phone_visibility_switch'),
                  title: Text(l10n.profile_phone_visibility_label),
                  value: vm.phoneVisible,
                  onChanged: vm.setPhoneVisible,
                ),
              ],
            ),
    );
  }
}
```

- [ ] **Step 3: Unit test + commit**

```bash
git add lib/features/profile/application/edit_profile_view_model.dart \
        lib/features/profile/presentation/edit_profile_screen.dart \
        test/unit/features/profile/edit_profile_view_model_test.dart
git commit -m "feat(mvvm): EditProfileViewModel — notifier, phoneVisible + save extracted"
```

---

## Task 6: NotificationSettingsViewModel

**Pattern:** Notifier implements interface (family, keyed by `homeId` + `uid`).  
**What moves:** `_prefs` local state initialization + `_isPremium()` computation + `_save()` method to ViewModel.

- [ ] **Step 1: Create `notification_settings_view_model.dart`**

```dart
// lib/features/notifications/application/notification_settings_view_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../subscription/application/subscription_provider.dart';
import '../../subscription/domain/subscription_state.dart';
import '../domain/notification_preferences.dart';
import 'notification_prefs_provider.dart';

part 'notification_settings_view_model.freezed.dart';
part 'notification_settings_view_model.g.dart';

// ── Contract ─────────────────────────────────────

abstract class NotificationSettingsViewModel {
  bool get isLoaded;
  bool get isPremium;
  NotificationPreferences get prefs;

  Future<void> updatePrefs(NotificationPreferences updated);
}

// ── Private state ─────────────────────────────────

@freezed
class _NotifVMState with _$_NotifVMState {
  const factory _NotifVMState({
    @Default(false) bool isLoaded,
    @Default(false) bool isPremium,
    NotificationPreferences? prefs,
  }) = __NotifVMState;
}

// ── Notifier ──────────────────────────────────────

@riverpod
class NotificationSettingsViewModelNotifier
    extends _$NotificationSettingsViewModelNotifier
    implements NotificationSettingsViewModel {
  @override
  _NotifVMState build(String homeId, String uid) {
    // Watch subscription for isPremium
    final subState = ref.watch(subscriptionStateProvider);
    final premium = subState.map(
      free: (_) => false,
      active: (_) => true,
      cancelledPendingEnd: (_) => true,
      rescue: (_) => true,
      expiredFree: (_) => false,
      restorable: (_) => false,
      purged: (_) => false,
    );

    // Watch prefs from Firestore and initialize once
    final prefsAsync =
        ref.watch(notificationPrefsProvider(homeId: homeId, uid: uid));
    prefsAsync.whenData((p) {
      if (!state.isLoaded) {
        Future.microtask(() => state = state.copyWith(
              isLoaded: true,
              prefs: p,
              isPremium: premium,
            ));
      } else {
        // Keep isPremium updated
        if (state.isPremium != premium) {
          Future.microtask(() =>
              state = state.copyWith(isPremium: premium));
        }
      }
    });

    return _NotifVMState(isPremium: premium);
  }

  @override bool get isLoaded => state.isLoaded;
  @override bool get isPremium => state.isPremium;
  @override
  NotificationPreferences get prefs =>
      state.prefs ??
      NotificationPreferences(homeId: '', uid: ''); // safe default

  @override
  Future<void> updatePrefs(NotificationPreferences updated) async {
    state = state.copyWith(prefs: updated);
    await ref.read(notificationPrefsNotifierProvider.notifier).save(updated);
  }
}

// ── Typed provider ───────────────────────────────

@riverpod
NotificationSettingsViewModel notificationSettingsViewModel(
  NotificationSettingsViewModelRef ref,
  String homeId,
  String uid,
) {
  ref.watch(notificationSettingsViewModelNotifierProvider(homeId, uid));
  return ref.read(notificationSettingsViewModelNotifierProvider(homeId, uid).notifier);
}
```

- [ ] **Step 2: Update `notification_settings_screen.dart`**

The screen becomes a `ConsumerWidget` (no `StatefulWidget` needed). All toggle `onChanged` handlers call `vm.updatePrefs(prefs.copyWith(...))`. Removed `_prefs` local state, `_isPremium()` method, `_save()` method.

- [ ] **Step 3: Unit test + commit**

Key tests: `isPremium` is false for free subscription, `updatePrefs` saves and updates prefs, initial prefs loaded from provider.

```bash
git add lib/features/notifications/application/notification_settings_view_model.dart \
        lib/features/notifications/presentation/notification_settings_screen.dart \
        test/unit/features/notifications/notification_settings_view_model_test.dart
git commit -m "feat(mvvm): NotificationSettingsViewModel — family notifier, prefs state extracted"
```

---

## Task 7: HistoryViewModel

**Pattern:** Separate `HistoryFilterNotifier` (preserves filter across rebuilds) + computed provider + impl class.  
**What moves:** `_filter` state → `HistoryFilterNotifier`. `_loadInitial` → called in provider `build` via `ref.listen`. `_loadMore()` / `_applyFilter()` → ViewModel methods. The `_scrollController` stays in the screen and the screen calls `vm.loadMore()` in the scroll listener callback.

- [ ] **Step 1: Create `history_view_model.dart`**

```dart
// lib/features/history/application/history_view_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../homes/application/current_home_provider.dart';
import '../../homes/application/dashboard_provider.dart';
import '../domain/task_event.dart';
import 'history_provider.dart';

part 'history_view_model.freezed.dart';
part 'history_view_model.g.dart';

// ── Filter state (separate notifier) ─────────────

@riverpod
class HistoryFilterNotifier extends _$HistoryFilterNotifier {
  @override
  HistoryFilter build() => const HistoryFilter();

  void setFilter(HistoryFilter f) => state = f;
}

// ── Contract ──────────────────────────────────────

abstract class HistoryViewModel {
  AsyncValue<List<TaskEvent>> get events;
  HistoryFilter get filter;
  bool get hasMore;
  bool get isPremium;

  void loadMore();
  void applyFilter(HistoryFilter newFilter);
}

// ── Impl ──────────────────────────────────────────

class _HistoryViewModelImpl implements HistoryViewModel {
  const _HistoryViewModelImpl({
    required this.events,
    required this.filter,
    required this.hasMore,
    required this.isPremium,
    required this.homeId,
    required this.ref,
  });

  @override final AsyncValue<List<TaskEvent>> events;
  @override final HistoryFilter filter;
  @override final bool hasMore;
  @override final bool isPremium;
  final String? homeId;
  final Ref ref;

  @override
  void loadMore() {
    if (homeId == null) return;
    ref
        .read(historyNotifierProvider(homeId!).notifier)
        .loadMore(isPremium: isPremium);
  }

  @override
  void applyFilter(HistoryFilter newFilter) {
    if (homeId == null) return;
    ref.read(historyFilterNotifierProvider.notifier).setFilter(newFilter);
    ref.read(historyNotifierProvider(homeId!).notifier).applyFilter(newFilter);
    loadMore();
  }
}

// ── Provider ─────────────────────────────────────

@riverpod
HistoryViewModel historyViewModel(HistoryViewModelRef ref) {
  final homeId = ref.watch(currentHomeProvider).valueOrNull?.id;
  final isPremium =
      ref.watch(dashboardProvider).valueOrNull?.premiumFlags.isPremium ?? false;
  final filter = ref.watch(historyFilterNotifierProvider);

  if (homeId == null) {
    return _HistoryViewModelImpl(
      events: const AsyncValue.loading(),
      filter: filter,
      hasMore: false,
      isPremium: isPremium,
      homeId: null,
      ref: ref,
    );
  }

  final events = ref.watch(historyNotifierProvider(homeId));
  final hasMore =
      ref.read(historyNotifierProvider(homeId).notifier).hasMore;

  // Trigger initial load when homeId first becomes available
  ref.listen<AsyncValue<String?>>(
    currentHomeProvider.select((v) => AsyncValue.data(v.valueOrNull?.id)),
    (prev, next) {
      final id = next.valueOrNull;
      if (id != null && prev?.valueOrNull == null) {
        ref
            .read(historyNotifierProvider(id).notifier)
            .loadMore(isPremium: isPremium);
      }
    },
  );

  return _HistoryViewModelImpl(
    events: events,
    filter: filter,
    hasMore: hasMore,
    isPremium: isPremium,
    homeId: homeId,
    ref: ref,
  );
}
```

- [ ] **Step 2: Update `history_screen.dart`**

```dart
// lib/features/history/presentation/history_screen.dart
class HistoryScreen extends ConsumerStatefulWidget { /* still stateful for scroll controller */ }

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(historyViewModelProvider).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.watch(historyViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.history_title)),
      body: Column(
        children: [
          HistoryFilterBar(
            current: vm.filter,
            onChanged: vm.applyFilter,
          ),
          Expanded(
            child: vm.events.when(
              loading: () => const LoadingWidget(),
              error: (_, __) => Center(child: Text(l10n.error_generic)),
              data: (events) {
                if (events.isEmpty) return const HistoryEmptyState();
                final showBanner = !vm.isPremium;
                final showLoadMore = vm.hasMore;
                final extraItems = (showBanner ? 1 : 0) + (showLoadMore ? 1 : 0);

                return ListView.builder(
                  key: const Key('history_list'),
                  controller: _scrollController,
                  itemCount: events.length + extraItems,
                  itemBuilder: (context, index) {
                    if (index < events.length) {
                      final event = events[index];
                      String? toName;
                      if (event is PassedEvent) toName = event.toUid;
                      return HistoryEventTile(
                        event: event,
                        actorName: event.actorUid,
                        actorPhotoUrl: null,
                        toName: toName,
                      );
                    }
                    final extra = index - events.length;
                    if (showBanner && extra == 0) return _PremiumBanner(l10n: l10n);
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: TextButton(
                          key: const Key('btn_load_more'),
                          onPressed: vm.loadMore,
                          child: Text(l10n.history_load_more),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Unit test + commit**

Key tests: `HistoryFilterNotifier` initial filter, `setFilter` updates it, `loadMore` delegates to `historyNotifierProvider`.

```bash
git add lib/features/history/application/history_view_model.dart \
        lib/features/history/presentation/history_screen.dart \
        test/unit/features/history/history_view_model_test.dart
git commit -m "feat(mvvm): HistoryViewModel — filter notifier + computed provider, isPremium extracted"
```

---

## Task 8: SettingsViewModel

**Pattern:** Computed provider. Adds a helper `appVersionProvider` for `PackageInfo`.  
**What moves:** `_isPremium()` computation + `_packageInfoFuture` initialization + notifications navigation helpers.

- [ ] **Step 1: Create `settings_view_model.dart`**

```dart
// lib/features/settings/application/settings_view_model.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_provider.dart';
import '../../homes/application/current_home_provider.dart';
import '../../subscription/application/subscription_provider.dart';
import '../../subscription/domain/subscription_state.dart';

part 'settings_view_model.g.dart';

// ── App version helper provider ──────────────────

@riverpod
Future<String> appVersion(AppVersionRef ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version} (${info.buildNumber})';
}

// ── View data ─────────────────────────────────────

class SettingsViewData {
  const SettingsViewData({
    required this.isPremium,
    required this.homeId,
    required this.uid,
    required this.appVersionAsync,
  });
  final bool isPremium;
  final String homeId;
  final String uid;
  final AsyncValue<String> appVersionAsync;
}

// ── Contract ─────────────────────────────────────

abstract class SettingsViewModel {
  SettingsViewData get viewData;
}

// ── Impl ─────────────────────────────────────────

class _SettingsViewModelImpl implements SettingsViewModel {
  const _SettingsViewModelImpl({required this.viewData});
  @override final SettingsViewData viewData;
}

bool _computeIsPremium(SubscriptionState state) => state.map(
      free: (_) => false,
      active: (_) => true,
      cancelledPendingEnd: (_) => true,
      rescue: (_) => true,
      expiredFree: (_) => false,
      restorable: (_) => false,
      purged: (_) => false,
    );

// ── Provider ─────────────────────────────────────

@riverpod
SettingsViewModel settingsViewModel(SettingsViewModelRef ref) {
  final subState = ref.watch(subscriptionStateProvider);
  final auth = ref.watch(authProvider);
  final uid = auth.whenOrNull(authenticated: (u) => u.uid) ?? '';
  final homeId = ref.watch(currentHomeProvider).valueOrNull?.id ?? '';
  final appVersionAsync = ref.watch(appVersionProvider);

  return _SettingsViewModelImpl(
    viewData: SettingsViewData(
      isPremium: _computeIsPremium(subState),
      homeId: homeId,
      uid: uid,
      appVersionAsync: appVersionAsync,
    ),
  );
}
```

- [ ] **Step 2: Update `settings_screen.dart`**

Replace `subscriptionStateProvider`, `currentHomeProvider`, `authProvider`, `_packageInfoFuture` with `ref.watch(settingsViewModelProvider)`. The screen becomes a `ConsumerWidget` (no `StatefulWidget` needed). Navigation calls use `vm.viewData.homeId` and `vm.viewData.uid`.

- [ ] **Step 3: Unit test + commit**

```bash
git add lib/features/settings/application/settings_view_model.dart \
        lib/features/settings/presentation/settings_screen.dart \
        test/unit/features/settings/settings_view_model_test.dart
git commit -m "feat(mvvm): SettingsViewModel — computed provider, appVersion + isPremium extracted"
```

---

## Task 9: PaywallViewModel

**Pattern:** Notifier implements interface.  
**What moves:** `ref.listen<paywallProvider>` navigation/error handling → `purchasedSuccessfully` + `purchaseError` flags that the screen reacts to. `homeId` lookup moves into ViewModel.

- [ ] **Step 1: Create `paywall_view_model.dart`**

```dart
// lib/features/subscription/application/paywall_view_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../homes/application/current_home_provider.dart';
import '../domain/purchase_result.dart';
import 'paywall_provider.dart';

part 'paywall_view_model.freezed.dart';
part 'paywall_view_model.g.dart';

// ── Contract ──────────────────────────────────────

abstract class PaywallViewModel {
  bool get isLoading;
  bool get purchasedSuccessfully;
  String? get purchaseError;

  Future<void> startPurchase(String productId);
  Future<void> restorePremium();
  void clearPurchaseResult();
}

// ── Private state ─────────────────────────────────

@freezed
class _PaywallVMState with _$_PaywallVMState {
  const factory _PaywallVMState({
    @Default(false) bool purchasedSuccessfully,
    String? purchaseError,
  }) = __PaywallVMState;
}

// ── Notifier ──────────────────────────────────────

@riverpod
class PaywallViewModelNotifier extends _$PaywallViewModelNotifier
    implements PaywallViewModel {
  @override
  _PaywallVMState build() {
    // React to paywallProvider results
    ref.listen<AsyncValue<PurchaseResult?>>(paywallProvider, (_, next) {
      next.whenOrNull(data: (result) {
        if (result is PurchaseResultSuccess) {
          state = state.copyWith(purchasedSuccessfully: true, purchaseError: null);
        } else if (result is PurchaseResultError) {
          state = state.copyWith(purchaseError: result.message);
        }
      });
    });
    return const _PaywallVMState();
  }

  String get _homeId =>
      ref.read(currentHomeProvider).valueOrNull?.id ?? '';

  @override bool get isLoading => ref.read(paywallProvider).isLoading;
  @override bool get purchasedSuccessfully => state.purchasedSuccessfully;
  @override String? get purchaseError => state.purchaseError;

  @override
  Future<void> startPurchase(String productId) =>
      ref.read(paywallProvider.notifier).startPurchase(
            homeId: _homeId,
            productId: productId,
          );

  @override
  Future<void> restorePremium() =>
      ref.read(paywallProvider.notifier).restorePremium(homeId: _homeId);

  @override
  void clearPurchaseResult() =>
      state = state.copyWith(purchasedSuccessfully: false, purchaseError: null);
}

// ── Typed provider ───────────────────────────────

@riverpod
PaywallViewModel paywallViewModel(PaywallViewModelRef ref) {
  ref.watch(paywallViewModelNotifierProvider);
  ref.watch(paywallProvider); // for isLoading reactivity
  return ref.read(paywallViewModelNotifierProvider.notifier);
}
```

- [ ] **Step 2: Update `paywall_screen.dart`**

Replace `ref.watch(paywallProvider)` + `ref.listen(paywallProvider, ...)` + direct `ref.read(paywallProvider.notifier).xxx()` with `ref.watch(paywallViewModelProvider)`. The `ref.listen` in the screen reacts to `vm.purchasedSuccessfully` and `vm.purchaseError` to show SnackBars and pop.

- [ ] **Step 3: Unit test + commit**

Key tests: `purchasedSuccessfully` is set on `PurchaseResultSuccess`, `purchaseError` is set on `PurchaseResultError`, `clearPurchaseResult` resets both.

```bash
git add lib/features/subscription/application/paywall_view_model.dart \
        lib/features/subscription/presentation/paywall_screen.dart \
        test/unit/features/subscription/paywall_view_model_test.dart
git commit -m "feat(mvvm): PaywallViewModel — notifier, purchase signals extracted"
```

---

## Task 10: DowngradePlannerViewModel

**Pattern:** Notifier implements interface.  
**What moves:** `_selectedMemberIds`, `_selectedTaskIds`, `_initialized` from widget state. `saveDowngradePlan` action.

- [ ] **Step 1: Create `downgrade_planner_view_model.dart`**

```dart
// lib/features/subscription/application/downgrade_planner_view_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../homes/application/current_home_provider.dart';
import '../../homes/application/dashboard_provider.dart';
import '../../members/application/members_provider.dart';
import '../../members/domain/member.dart';
import '../domain/home_dashboard.dart';
import 'paywall_provider.dart';

part 'downgrade_planner_view_model.freezed.dart';
part 'downgrade_planner_view_model.g.dart';

const _kMaxFreeMembers = 3;
const _kMaxFreeTasks = 4;

// ── Contract ──────────────────────────────────────

abstract class DowngradePlannerViewModel {
  AsyncValue<DowngradePlannerViewData?> get viewData;
  Set<String> get selectedMemberIds;
  Set<String> get selectedTaskIds;
  bool get isLoading;
  bool get savedSuccessfully;

  void toggleMember(String uid, bool checked);
  void toggleTask(String id, bool checked);
  Future<void> savePlan();
}

// ── View data ─────────────────────────────────────

class DowngradePlannerViewData {
  const DowngradePlannerViewData({
    required this.activeMembers,
    required this.tasks,
    required this.ownerUid,
  });
  final List<Member> activeMembers;
  final List<(String id, String title)> tasks;
  final String ownerUid;
}

// ── Private state ─────────────────────────────────

@freezed
class _DowngradeVMState with _$_DowngradeVMState {
  const factory _DowngradeVMState({
    @Default({}) Set<String> selectedMemberIds,
    @Default({}) Set<String> selectedTaskIds,
    @Default(false) bool initialized,
    @Default(false) bool isLoading,
    @Default(false) bool savedSuccessfully,
  }) = __DowngradeVMState;
}

// ── Notifier ──────────────────────────────────────

@riverpod
class DowngradePlannerViewModelNotifier
    extends _$DowngradePlannerViewModelNotifier
    implements DowngradePlannerViewModel {
  @override
  _DowngradeVMState build() {
    final homeId = ref.watch(currentHomeProvider).valueOrNull?.id;
    if (homeId != null) {
      final membersAsync = ref.watch(homeMembersProvider(homeId));
      final dashAsync = ref.watch(dashboardProvider);
      membersAsync.whenData((members) {
        dashAsync.whenData((dash) {
          if (dash != null && !state.initialized) {
            Future.microtask(() => state = state.copyWith(
                  initialized: true,
                  selectedMemberIds: members
                      .where((m) => m.status == MemberStatus.active)
                      .map((m) => m.uid)
                      .toSet(),
                  selectedTaskIds: dash.activeTasksPreview
                      .map((t) => t.taskId)
                      .toSet(),
                ));
          }
        });
      });
    }
    return const _DowngradeVMState();
  }

  @override AsyncValue<DowngradePlannerViewData?> get viewData {
    final homeId = ref.read(currentHomeProvider).valueOrNull?.id;
    if (homeId == null) return const AsyncValue.loading();
    final membersAsync = ref.read(homeMembersProvider(homeId));
    final dashAsync = ref.read(dashboardProvider);
    final home = ref.read(currentHomeProvider).valueOrNull;
    return membersAsync.whenData((members) {
      final dash = dashAsync.valueOrNull;
      if (dash == null) return null;
      return DowngradePlannerViewData(
        activeMembers: members.where((m) => m.status == MemberStatus.active).toList(),
        tasks: dash.activeTasksPreview.map((t) => (t.taskId, t.title)).toList(),
        ownerUid: home?.ownerUid ?? '',
      );
    });
  }

  @override Set<String> get selectedMemberIds => state.selectedMemberIds;
  @override Set<String> get selectedTaskIds => state.selectedTaskIds;
  @override bool get isLoading => state.isLoading;
  @override bool get savedSuccessfully => state.savedSuccessfully;

  @override
  void toggleMember(String uid, bool checked) {
    final next = Set<String>.from(state.selectedMemberIds);
    if (checked) {
      if (next.length < _kMaxFreeMembers) next.add(uid);
    } else {
      next.remove(uid);
    }
    state = state.copyWith(selectedMemberIds: next);
  }

  @override
  void toggleTask(String id, bool checked) {
    final next = Set<String>.from(state.selectedTaskIds);
    if (checked) {
      if (next.length < _kMaxFreeTasks) next.add(id);
    } else {
      next.remove(id);
    }
    state = state.copyWith(selectedTaskIds: next);
  }

  @override
  Future<void> savePlan() async {
    final homeId = ref.read(currentHomeProvider).valueOrNull?.id;
    if (homeId == null) return;
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(paywallProvider.notifier).saveDowngradePlan(
            homeId: homeId,
            memberIds: state.selectedMemberIds.toList(),
            taskIds: state.selectedTaskIds.toList(),
          );
      state = state.copyWith(isLoading: false, savedSuccessfully: true);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }
}

// ── Typed provider ───────────────────────────────

@riverpod
DowngradePlannerViewModel downgradePlannerViewModel(
    DowngradePlannerViewModelRef ref) {
  ref.watch(downgradePlannerViewModelNotifierProvider);
  return ref.read(downgradePlannerViewModelNotifierProvider.notifier);
}
```

- [ ] **Step 2: Update `downgrade_planner_screen.dart`**

Replace all widget state (`_selectedMemberIds`, `_selectedTaskIds`, `_initialized`) with `vm.selectedMemberIds`, `vm.selectedTaskIds`. `_MembersList.onToggle` calls `vm.toggleMember`. `_TasksList.onToggle` calls `vm.toggleTask`. The save button calls `vm.savePlan()`. Screen listens to `savedSuccessfully` to show SnackBar and pop.

- [ ] **Step 3: Unit test + commit**

Key tests: `toggleMember` respects `_kMaxFreeMembers` limit, `toggleTask` respects `_kMaxFreeTasks` limit, `savePlan` calls `paywallProvider.saveDowngradePlan`.

```bash
git add lib/features/subscription/application/downgrade_planner_view_model.dart \
        lib/features/subscription/presentation/downgrade_planner_screen.dart \
        test/unit/features/subscription/downgrade_planner_view_model_test.dart
git commit -m "feat(mvvm): DowngradePlannerViewModel — selection state + savePlan extracted"
```

---

## Task 11: SubscriptionManagementViewModel + RescueViewModel

Both are simple computed providers. No mutable state — they just aggregate existing providers.

- [ ] **Step 1: Create `subscription_management_view_model.dart`**

```dart
// lib/features/subscription/application/subscription_management_view_model.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../homes/application/current_home_provider.dart';
import '../domain/subscription_state.dart';
import 'paywall_provider.dart';
import 'subscription_provider.dart';

part 'subscription_management_view_model.g.dart';

abstract class SubscriptionManagementViewModel {
  SubscriptionState get subscriptionState;
  bool get isLoading;
  String get homeId;
  Future<void> restorePremium();
}

class _SubscriptionManagementViewModelImpl
    implements SubscriptionManagementViewModel {
  const _SubscriptionManagementViewModelImpl({
    required this.subscriptionState,
    required this.isLoading,
    required this.homeId,
    required this.ref,
  });
  @override final SubscriptionState subscriptionState;
  @override final bool isLoading;
  @override final String homeId;
  final Ref ref;

  @override
  Future<void> restorePremium() =>
      ref.read(paywallProvider.notifier).restorePremium(homeId: homeId);
}

@riverpod
SubscriptionManagementViewModel subscriptionManagementViewModel(
    SubscriptionManagementViewModelRef ref) {
  final subState = ref.watch(subscriptionStateProvider);
  final homeId = ref.watch(currentHomeProvider).valueOrNull?.id ?? '';
  final isLoading = ref.watch(paywallProvider).isLoading;

  return _SubscriptionManagementViewModelImpl(
    subscriptionState: subState,
    isLoading: isLoading,
    homeId: homeId,
    ref: ref,
  );
}
```

- [ ] **Step 2: Create `rescue_view_model.dart`**

```dart
// lib/features/subscription/application/rescue_view_model.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../homes/application/current_home_provider.dart';
import 'paywall_provider.dart';
import 'subscription_provider.dart';

part 'rescue_view_model.g.dart';

abstract class RescueViewModel {
  int get daysLeft;
  bool get isLoading;
  String get homeId;
  Future<void> startPurchase(String productId);
}

class _RescueViewModelImpl implements RescueViewModel {
  const _RescueViewModelImpl({
    required this.daysLeft,
    required this.isLoading,
    required this.homeId,
    required this.ref,
  });
  @override final int daysLeft;
  @override final bool isLoading;
  @override final String homeId;
  final Ref ref;

  @override
  Future<void> startPurchase(String productId) =>
      ref.read(paywallProvider.notifier).startPurchase(
            homeId: homeId,
            productId: productId,
          );
}

@riverpod
RescueViewModel rescueViewModel(RescueViewModelRef ref) {
  final subState = ref.watch(subscriptionStateProvider);
  final daysLeft = subState.whenOrNull(rescue: (_, __, d) => d) ?? 0;
  final homeId = ref.watch(currentHomeProvider).valueOrNull?.id ?? '';
  final isLoading = ref.watch(paywallProvider).isLoading;

  return _RescueViewModelImpl(
    daysLeft: daysLeft,
    isLoading: isLoading,
    homeId: homeId,
    ref: ref,
  );
}
```

- [ ] **Step 3: Update both screens, commit**

`subscription_management_screen.dart`: replace all direct provider access with `ref.watch(subscriptionManagementViewModelProvider)`.

`rescue_screen.dart`: replace all direct provider access with `ref.watch(rescueViewModelProvider)`.

```bash
git add lib/features/subscription/application/subscription_management_view_model.dart \
        lib/features/subscription/application/rescue_view_model.dart \
        lib/features/subscription/presentation/subscription_management_screen.dart \
        lib/features/subscription/presentation/rescue_screen.dart
git commit -m "feat(mvvm): SubscriptionManagementViewModel + RescueViewModel — computed providers"
```

---

## Final Step: Run all tests

- [ ] **Run all unit tests for Plan 03**

```bash
flutter test test/unit/features/members/ \
             test/unit/features/profile/ \
             test/unit/features/notifications/ \
             test/unit/features/history/ \
             test/unit/features/settings/ \
             test/unit/features/subscription/
```

- [ ] **Regenerate code**

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Run static analysis**

```bash
flutter analyze
```

---

## Pruebas manuales requeridas

1. **Members:** Pantalla de miembros carga activos/congelados. FAB de invitar solo visible para owner/admin. Tap en miembro navega al perfil.
2. **MemberProfile:** Ver perfil de otro miembro → stats, radar y teléfono (si visible). Ver propio perfil desde Members → teléfono siempre visible.
3. **Vacation:** Abrir pantalla vacaciones de un miembro → toggle y fechas se rellenan si había datos existentes. Activar → seleccionar fechas → guardar → cierra. Desactivar → guardar → cierra.
4. **OwnProfile:** Pantalla perfil muestra datos. Botón logout → cierra sesión y navega a login. Botón editar navega a edición.
5. **EditProfile:** Campos pre-rellenados con datos actuales. Cambiar nickname, guardar → SnackBar y vuelve al perfil.
6. **NotificationSettings:** Toggles responden. Opciones premium deshabilitadas para plan free. Cambiar configuración → guarda inmediatamente.
7. **History:** Lista carga con eventos. Filtro cambia resultados. Scroll hasta el final → carga más. Botón "cargar más" también funciona. Banner Premium visible en plan free.
8. **Settings:** Pantalla muestra estado Premium/Free. Versión de la app visible. Links de navegación funcionan.
9. **Paywall:** Botones de compra activos cuando no está cargando. Compra exitosa → SnackBar + cierra. Error de compra → SnackBar. Restaurar → funciona.
10. **DowngradePlanner:** Listas de miembros y tareas con checkboxes. Máximo 3 miembros y 4 tareas. Owner no se puede desmarcar. Guardar → SnackBar + cierra.
11. **SubscriptionManagement:** Estado de suscripción visible. Botones de acción correctos según estado (free/active/rescue/restorable). Restaurar en estado restorable funciona.
12. **RescueScreen:** Días restantes visibles. Botones de renovación funcionan. Botón downgrade navega al planner.
