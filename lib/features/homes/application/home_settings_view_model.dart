// lib/features/homes/application/home_settings_view_model.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/toka_dates.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/auth_provider.dart';
import '../domain/home.dart';
import '../domain/home_membership.dart';
import 'current_home_provider.dart';
import 'homes_provider.dart';

part 'home_settings_view_model.g.dart';

class HomeSettingsViewData {
  const HomeSettingsViewData({
    required this.homeId,
    required this.homeName,
    required this.photoUrl,
    required this.planLabel,
    required this.canEdit,
    required this.isPayer,
    required this.isOwner,
    required this.uid,
    // DEBUG PREMIUM — REMOVE BEFORE PRODUCTION
    required this.premiumStatusCode,
    required this.showDebugPremiumToggle,
    // END DEBUG PREMIUM
  });

  final String homeId;
  final String homeName;
  final String? photoUrl;
  final String planLabel;
  final bool canEdit;
  final bool isPayer;
  final bool isOwner;
  final String uid;
  // DEBUG PREMIUM — REMOVE BEFORE PRODUCTION
  final String premiumStatusCode;
  final bool showDebugPremiumToggle;
  // END DEBUG PREMIUM
}

abstract class HomeSettingsViewModel {
  AsyncValue<HomeSettingsViewData?> get viewData;
  String? get error;
  bool get isLoading;
  Future<void> updateHomeName(String name);
  /// Sube `localPath` a Storage como avatar del hogar y refleja la URL
  /// en `homes/{homeId}.photoUrl`. El stream del hogar lo propagará al
  /// resto de pantallas via `currentHomeProvider`.
  Future<void> updateHomePhoto(String localPath);
  /// Elimina el avatar (Storage + Firestore).
  Future<void> removeHomePhoto();
  Future<void> leaveHome();
  Future<void> closeHome();
  void clearError();
  // DEBUG PREMIUM — REMOVE BEFORE PRODUCTION
  Future<void> debugSetPremiumStatus(String status);
  // END DEBUG PREMIUM
}

class _HomeSettingsViewModelImpl implements HomeSettingsViewModel {
  _HomeSettingsViewModelImpl({
    required this.viewData,
    required this.ref,
  });

  @override
  final AsyncValue<HomeSettingsViewData?> viewData;
  final Ref ref;

  @override
  String? get error => null;

  @override
  bool get isLoading => false;

  @override
  Future<void> updateHomeName(String name) async {
    final homeId = viewData.valueOrNull?.homeId;
    if (homeId == null || name.trim().isEmpty) return;
    await ref
        .read(homesRepositoryProvider)
        .updateHomeName(homeId, name.trim());
  }

  @override
  Future<void> updateHomePhoto(String localPath) async {
    final homeId = viewData.valueOrNull?.homeId;
    if (homeId == null) return;
    await ref.read(homesRepositoryProvider).updateHomePhoto(homeId, localPath);
  }

  @override
  Future<void> removeHomePhoto() async {
    final homeId = viewData.valueOrNull?.homeId;
    if (homeId == null) return;
    await ref.read(homesRepositoryProvider).removeHomePhoto(homeId);
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
  void clearError() {}

  // DEBUG PREMIUM — REMOVE BEFORE PRODUCTION
  @override
  Future<void> debugSetPremiumStatus(String status) async {
    final homeId = viewData.valueOrNull?.homeId;
    if (homeId == null) return;
    await ref
        .read(homesRepositoryProvider)
        .debugSetPremiumStatus(homeId, status);
  }
  // END DEBUG PREMIUM
}

String _planLabel(Home home, AppLocalizations l10n) {
  if (home.premiumStatus == HomePremiumStatus.free ||
      home.premiumStatus == HomePremiumStatus.expiredFree) {
    return l10n.homes_plan_free;
  }
  final endsAt = home.premiumEndsAt;
  if (endsAt != null) {
    final formatted =
        TokaDates.dateShort(endsAt, Locale(l10n.localeName));
    return '${l10n.homes_plan_premium} · ${l10n.homes_plan_ends(formatted)}';
  }
  return l10n.homes_plan_premium;
}

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
      photoUrl: home.photoUrl,
      planLabel: _planLabel(home, l10n),
      canEdit: canEdit,
      isPayer: isCurrentPayer,
      isOwner: isOwner,
      uid: uid,
      // DEBUG PREMIUM — REMOVE BEFORE PRODUCTION
      premiumStatusCode: home.premiumStatus.name,
      showDebugPremiumToggle: isOwner,
      // END DEBUG PREMIUM
    );
  });

  return _HomeSettingsViewModelImpl(viewData: viewData, ref: ref);
}
