// ignore_for_file: avoid_print
import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class AppLogger {
  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.debug, message, error, stackTrace);
  }

  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.info, message, error, stackTrace);
  }

  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.warning, message, error, stackTrace);
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error, stackTrace);
  }

  static void _log(
    LogLevel level,
    String message,
    Object? error,
    StackTrace? stackTrace,
  ) {
    if (!kDebugMode) return;
    final prefix = switch (level) {
      LogLevel.debug   => '[DEBUG]',
      LogLevel.info    => '[INFO]',
      LogLevel.warning => '[WARN]',
      LogLevel.error   => '[ERROR]',
    };
    print('$prefix $message');
    if (error != null) print('  error: $error');
    if (stackTrace != null) print('  stack: $stackTrace');
  }
}
