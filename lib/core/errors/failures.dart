import '../services/logger_service.dart';

sealed class Failure implements Exception {
  final String message;
  final Object? exception;
  final StackTrace? stackTrace;

  const Failure({
    required this.message,
    this.exception,
    this.stackTrace,
  });

  Object get originalException {
    var current = exception;
    while (current is Failure && current.exception != null) {
      current = current.exception;
    }
    return current ?? this;
  }

  String get creationLocation {
    if (stackTrace == null) return 'Unknown location';
    final lines = stackTrace.toString().split('\n');
    for (final line in lines) {
      if (line.contains('failures.dart')) continue;
      return line.trim();
    }
    return 'Unknown location';
  }

  @override
  String toString() {
    final orig = originalException;
    final sb = StringBuffer();
    sb.write(message);
    if (orig != this) {
      sb.write('\nOriginal Error: $orig');
    }
    return sb.toString();
  }
}

class NetworkFailure extends Failure {
  NetworkFailure({
    required super.message,
    super.exception,
    super.stackTrace,
  }) {
    _logDetails();
  }

  String? get failingUrl {
    final orig = originalException;
    try {
      if (orig.toString().contains('http') || orig.toString().contains('https')) {
        final match = RegExp(r'https?://[^\s]+').firstMatch(orig.toString());
        if (match != null) return match.group(0);
      }
    } catch (_) {}
    return null;
  }

  int? get httpStatusCode {
    final orig = originalException;
    try {
      final match = RegExp(r'\b(400|401|403|404|429|500|502|503)\b').firstMatch(orig.toString());
      if (match != null) return int.tryParse(match.group(0)!);
    } catch (_) {}
    return null;
  }

  String? get responseBody {
    final orig = originalException;
    try {
      // Check if original exception contains response body details
      if (orig.toString().contains('Response body:') || orig.toString().contains('Body:')) {
        return orig.toString();
      }
    } catch (_) {}
    return null;
  }

  void _logDetails() {
    final orig = originalException;
    DALogger.error(
      'NetworkFailure Created at: $creationLocation\n'
      'Context Message: $message\n'
      'Original Exception: $orig\n'
      'Failing URL: ${failingUrl ?? "N/A"}\n'
      'HTTP Status Code: ${httpStatusCode ?? "N/A"}\n'
      'Response Body: ${responseBody ?? "N/A"}',
      orig,
      stackTrace,
    );
  }
}

class PlaybackFailure extends Failure {
  const PlaybackFailure({
    required super.message,
    super.exception,
    super.stackTrace,
  });
}

class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.exception,
    super.stackTrace,
  });
}

class DatabaseFailure extends Failure {
  const DatabaseFailure({
    required super.message,
    super.exception,
    super.stackTrace,
  });
}

class UnknownFailure extends Failure {
  const UnknownFailure({
    required super.message,
    super.exception,
    super.stackTrace,
  });
}

class StreamFailure extends Failure {
  const StreamFailure({
    required super.message,
    super.exception,
    super.stackTrace,
  });
}
