import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

/// Unified release-safe logging service for tracking system warnings and errors.
class DALogger {
  DALogger._();

  static LogLevel activeLevel = LogLevel.debug;

  static void log(LogLevel level, String message, [Object? error, StackTrace? stackTrace]) {
    if (kReleaseMode && level == LogLevel.debug) return;
    if (level.index < activeLevel.index) return;

    final prefix = _getPrefix(level);
    final timestamp = DateTime.now().toIso8601String();

    debugPrint('[$prefix][$timestamp] $message');
    if (error != null) {
      debugPrint('  Error: $error');
    }
    if (stackTrace != null && level == LogLevel.error) {
      debugPrint('  StackTrace:\n$stackTrace');
    }
  }

  static void debug(String message) => log(LogLevel.debug, message);
  static void info(String message) => log(LogLevel.info, message);
  static void warning(String message) => log(LogLevel.warning, message);
  static void error(String message, [Object? error, StackTrace? stackTrace]) =>
      log(LogLevel.error, message, error, stackTrace);

  static String _getPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
    }
  }
}
