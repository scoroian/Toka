import 'package:cloud_functions/cloud_functions.dart';

import '../../homes/application/join_home_error.dart';
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
      // Mapeo unificado código→excepción de dominio (Hallazgo #04): la MISMA
      // fuente de verdad que usa el repo del selector multi-hogar, para que
      // ambas entradas produzcan idénticas excepciones tipadas. Un code
      // desconocido se re-lanza tal cual (identidad preservada).
      final mapped = mapJoinHomeException(e);
      if (identical(mapped, e)) rethrow;
      throw mapped;
    }
  }
}
