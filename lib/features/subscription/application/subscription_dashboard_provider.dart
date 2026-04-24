import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../homes/application/current_home_provider.dart';
import '../domain/subscription_dashboard.dart';

part 'subscription_dashboard_provider.g.dart';

/// Stream en vivo del estado de suscripción del hogar actual.
///
/// Combina dos snapshots de Firestore:
///   - `homes/{homeId}` — fuente de verdad de `premiumStatus`, `premiumPlan`,
///     `premiumEndsAt`, `restoreUntil`, `autoRenewEnabled`, `currentPayerUid`.
///     Se actualiza desde `syncEntitlement`, `debugSetPremiumStatus` y los
///     cron de rescate/downgrade.
///   - `homes/{homeId}/views/dashboard` — sólo se usa para extraer
///     `planCounters`.
///
/// Cada cambio en cualquiera de los dos documentos re-emite el
/// [SubscriptionDashboard], de modo que la pantalla Suscripción refleja el
/// cambio sin pull-to-refresh (BUG-12).
@Riverpod(keepAlive: true)
Stream<SubscriptionDashboard> subscriptionDashboard(
  SubscriptionDashboardRef ref, {
  FirebaseFirestore? firestoreOverride,
}) {
  final home = ref.watch(currentHomeProvider).valueOrNull;
  if (home == null) return const Stream.empty();
  final homeId = home.id;

  final firestore = firestoreOverride ?? FirebaseFirestore.instance;
  final homeStream = firestore.doc('homes/$homeId').snapshots();
  final dashStream =
      firestore.doc('homes/$homeId/views/dashboard').snapshots();

  return _combineLatest2(
    homeStream,
    dashStream,
    (homeSnap, dashSnap) => SubscriptionDashboard.fromMaps(
      homeId: homeId,
      home: homeSnap.data() ?? const {},
      dashboard: dashSnap.data(),
    ),
  );
}

Stream<T> _combineLatest2<A, B, T>(
  Stream<A> a,
  Stream<B> b,
  T Function(A, B) combine,
) {
  late StreamController<T> controller;
  StreamSubscription<A>? subA;
  StreamSubscription<B>? subB;
  A? latestA;
  B? latestB;
  var hasA = false;
  var hasB = false;

  void emit() {
    if (hasA && hasB && !controller.isClosed) {
      controller.add(combine(latestA as A, latestB as B));
    }
  }

  controller = StreamController<T>(
    onListen: () {
      subA = a.listen(
        (value) {
          latestA = value;
          hasA = true;
          emit();
        },
        onError: controller.addError,
      );
      subB = b.listen(
        (value) {
          latestB = value;
          hasB = true;
          emit();
        },
        onError: controller.addError,
      );
    },
    onCancel: () async {
      await subA?.cancel();
      await subB?.cancel();
    },
  );

  return controller.stream;
}
