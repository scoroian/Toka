class ServerException implements Exception {
  const ServerException([this.message = 'Server error']);
  final String message;
  @override
  String toString() => 'ServerException: $message';
}

class CacheException implements Exception {
  const CacheException([this.message = 'Cache error']);
  final String message;
  @override
  String toString() => 'CacheException: $message';
}

class AuthException implements Exception {
  const AuthException([this.message = 'Auth error']);
  final String message;
  @override
  String toString() => 'AuthException: $message';
}

class NetworkException implements Exception {
  const NetworkException([this.message = 'No network connection']);
  final String message;
  @override
  String toString() => 'NetworkException: $message';
}
