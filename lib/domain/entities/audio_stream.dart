/// Domain entity representing a standardized resolved audio stream.
class AudioStream {
  final String id;
  final String providerId;
  final String streamUrl;
  final String mimeType;
  final int bitrate;
  final Duration duration;
  final DateTime expiresAt;
  final Map<String, String> headers;
  final String quality;
  final String codec;
  final bool isLive;
  final bool isCached;

  const AudioStream({
    required this.id,
    required this.providerId,
    required this.streamUrl,
    required this.mimeType,
    required this.bitrate,
    required this.duration,
    required this.expiresAt,
    required this.headers,
    required this.quality,
    required this.codec,
    required this.isLive,
    required this.isCached,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  AudioStream copyWith({
    String? id,
    String? providerId,
    String? streamUrl,
    String? mimeType,
    int? bitrate,
    Duration? duration,
    DateTime? expiresAt,
    Map<String, String>? headers,
    String? quality,
    String? codec,
    bool? isLive,
    bool? isCached,
  }) {
    return AudioStream(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      streamUrl: streamUrl ?? this.streamUrl,
      mimeType: mimeType ?? this.mimeType,
      bitrate: bitrate ?? this.bitrate,
      duration: duration ?? this.duration,
      expiresAt: expiresAt ?? this.expiresAt,
      headers: headers ?? this.headers,
      quality: quality ?? this.quality,
      codec: codec ?? this.codec,
      isLive: isLive ?? this.isLive,
      isCached: isCached ?? this.isCached,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioStream &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          providerId == other.providerId &&
          streamUrl == other.streamUrl &&
          mimeType == other.mimeType &&
          bitrate == other.bitrate &&
          duration == other.duration &&
          expiresAt == other.expiresAt &&
          quality == other.quality &&
          codec == other.codec &&
          isLive == other.isLive &&
          isCached == other.isCached;

  @override
  int get hashCode =>
      id.hashCode ^
      providerId.hashCode ^
      streamUrl.hashCode ^
      mimeType.hashCode ^
      bitrate.hashCode ^
      duration.hashCode ^
      expiresAt.hashCode ^
      quality.hashCode ^
      codec.hashCode ^
      isLive.hashCode ^
      isCached.hashCode;

  @override
  String toString() {
    return 'AudioStream{id: $id, providerId: $providerId, url: $streamUrl, mimeType: $mimeType, bitrate: $bitrate, quality: $quality, codec: $codec}';
  }
}
