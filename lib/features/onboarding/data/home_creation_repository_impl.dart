import 'package:cloud_functions/cloud_functions.dart';

import '../domain/home_creation_repository.dart';

class HomeCreationRepositoryImpl implements HomeCreationRepository {
  HomeCreationRepositoryImpl({
    required FirebaseFunctions functions,
  }) : _functions = functions;

  final FirebaseFunctions _functions;

  @override
  Future<String> createHome({required String name, String? emoji}) async {
    try {
      final callable = _functions.httpsCallable('createHome');
      final result = await callable.call<Map<String, dynamic>>({
        'name': name,
        if (emoji != null) 'emoji': emoji,
      });
      final data = result.data;
      return data['homeId'] as String;
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'resource-exhausted') throw const NoHomeSlotsException();
      rethrow;
    }
  }

  @override
  Future<String> joinHome({required String code}) async {
    // PRIVACIDAD (Hallazgo #01): la búsqueda de la invitación se hace
    // SERVER-SIDE en la callable joinHomeByCode (Admin SDK, con rate-limit). El
    // cliente ya NO consulta collectionGroup('invitations') — eso permitía a
    // cualquier autenticado enumerar todos los códigos del sistema y por eso las
    // reglas ahora lo prohíben (allow list: if false).
    try {
      final callable = _functions.httpsCallable('joinHomeByCode');
      final result = await callable.call<Map<String, dynamic>>({'code': code});
      return (result.data['homeId'] as String?) ?? '';
    } on FirebaseFunctionsException catch (e) {
      // Traducimos a las excepciones de dominio que ya maneja onboarding.
      switch (e.code) {
        case 'not-found':
          throw const InvalidInviteCodeException();
        case 'deadline-exceeded':
          throw const ExpiredInviteCodeException();
        default:
          rethrow;
      }
    }
  }
}
