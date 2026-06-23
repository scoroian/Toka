import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/support_repository_impl.dart';
import '../domain/home_diagnostics.dart';
import '../domain/support_repository.dart';

part 'support_providers.g.dart';

@Riverpod(keepAlive: true)
SupportRepository supportRepository(SupportRepositoryRef ref) {
  return SupportRepositoryImpl(functions: FirebaseFunctions.instance);
}

/// True si la cuenta autenticada tiene el custom claim `support`. Gatea la
/// entrada de Ajustes y la propia pantalla (defensa en profundidad; el backend
/// vuelve a exigir el claim + App Check).
@riverpod
Future<bool> isSupportAgent(IsSupportAgentRef ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;
  // forceRefresh: true → el claim `support` recién concedido se refleja sin
  // esperar a la expiración del token (~1h) ni a un re-login. Es una pantalla
  // rara de abrir, así que el coste de un refresh puntual es aceptable.
  try {
    final token = await user.getIdTokenResult(true);
    return token.claims?['support'] == true;
  } catch (_) {
    // Si el refresh del token falla (red/App Check), ocultamos la entrada en
    // vez de romper Ajustes: el backend vuelve a exigir el claim de todas formas.
    return false;
  }
}

/// Diagnóstico de un hogar concreto (se re-ejecuta al cambiar homeId).
@riverpod
Future<HomeDiagnostics> homeDiagnostics(
  HomeDiagnosticsRef ref,
  String homeId,
) {
  return ref.watch(supportRepositoryProvider).diagnoseHome(homeId);
}
