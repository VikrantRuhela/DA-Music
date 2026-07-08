class PlaybackException implements Exception {
  final String message;
  final dynamic details;

  const PlaybackException(this.message, [this.details]);

  @override
  String toString() => 'PlaybackException: $message${details != null ? ' ($details)' : ''}';
}

class QueueException implements Exception {
  final String message;

  const QueueException(this.message);

  @override
  String toString() => 'QueueException: $message';
}

class SourceException implements Exception {
  final String message;
  final dynamic details;

  const SourceException(this.message, [this.details]);

  @override
  String toString() => 'SourceException: $message${details != null ? ' ($details)' : ''}';
}
