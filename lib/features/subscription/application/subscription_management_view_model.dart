// lib/features/subscription/application/subscription_management_view_model.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/subscription_dashboard.dart';
import 'paywall_provider.dart';
import 'subscription_dashboard_provider.dart';

part 'subscription_management_view_model.g.dart';

/// ViewModel de la pantalla *Ajustes → Gestionar suscripción*. Expone el
/// `SubscriptionDashboard` actual (derivado del stream) junto con el mapa de
/// acciones en curso para deshabilitar botones mientras se ejecutan callables.
abstract class SubscriptionManagementViewModel {
  AsyncValue<SubscriptionDashboard> get dashboard;
  Map<String, bool> get pending;
  bool get isLoading;
  String get homeId;
  Future<void> restorePremium();
}

class _SubscriptionManagementViewModelImpl
    implements SubscriptionManagementViewModel {
  const _SubscriptionManagementViewModelImpl({
    required this.dashboard,
    required this.pending,
    required this.isLoading,
    required this.homeId,
    required this.ref,
  });
  @override
  final AsyncValue<SubscriptionDashboard> dashboard;
  @override
  final Map<String, bool> pending;
  @override
  final bool isLoading;
  @override
  final String homeId;
  final Ref ref;

  @override
  Future<void> restorePremium() =>
      ref.read(paywallProvider.notifier).restorePremium(homeId: homeId);
}

@riverpod
SubscriptionManagementViewModel subscriptionManagementViewModel(
    SubscriptionManagementViewModelRef ref) {
  final dashAsync = ref.watch(subscriptionDashboardProvider());
  final homeId = dashAsync.valueOrNull?.homeId ?? '';
  final paywallAsync = ref.watch(paywallProvider);
  final isLoading = paywallAsync.isLoading;

  return _SubscriptionManagementViewModelImpl(
    dashboard: dashAsync,
    pending: {'restore': isLoading},
    isLoading: isLoading,
    homeId: homeId,
    ref: ref,
  );
}
