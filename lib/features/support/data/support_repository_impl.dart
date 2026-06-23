import 'package:cloud_functions/cloud_functions.dart';

import '../domain/home_diagnostics.dart';
import '../domain/support_repository.dart';

class SupportRepositoryImpl implements SupportRepository {
  SupportRepositoryImpl({required FirebaseFunctions functions})
      : _functions = functions;

  final FirebaseFunctions _functions;

  @override
  Future<HomeDiagnostics> diagnoseHome(String homeId) async {
    try {
      final callable = _functions.httpsCallable('supportDiagnoseHome');
      final result = await callable.call<Object?>({'homeId': homeId});
      return HomeDiagnostics.fromMap(_coerceMap(result.data));
    } on FirebaseFunctionsException catch (e) {
      // El code viaja tal cual (unauthenticated, permission-denied,
      // invalid-argument, not-found, unauthorized si App Check falla...).
      throw SupportException(e.code);
    }
  }
}

/// El plugin cloud_functions entrega los objetos anidados como
/// `Map<Object?, Object?>` / `List<Object?>`. Los convertimos en profundidad a
/// estructuras `Map<String, dynamic>` antes de parsear con fromMap.
Map<String, dynamic> _coerceMap(Object? raw) {
  if (raw is Map) {
    return raw.map((k, v) => MapEntry(k.toString(), _coerce(v)));
  }
  return <String, dynamic>{};
}

dynamic _coerce(Object? v) {
  if (v is Map) {
    return v.map((k, value) => MapEntry(k.toString(), _coerce(value)));
  }
  if (v is List) {
    return v.map(_coerce).toList();
  }
  return v;
}
