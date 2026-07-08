/// Immutable domain entity representing song lyrics.
class Lyrics {
  final String songId;
  final String plainLyrics;
  final Map<Duration, String>? syncedLyrics;
  final String language;
  final String provider;

  Lyrics({
    required this.songId,
    required this.plainLyrics,
    this.syncedLyrics,
    required this.language,
    required this.provider,
  }) {
    if (songId.isEmpty) throw ArgumentError('Lyrics songID reference cannot be empty.');
    if (plainLyrics.isEmpty) throw ArgumentError('Lyrics plain text lyrics cannot be empty.');
  }

  Lyrics copyWith({
    String? songId,
    String? plainLyrics,
    Map<Duration, String>? syncedLyrics,
    String? language,
    String? provider,
  }) {
    return Lyrics(
      songId: songId ?? this.songId,
      plainLyrics: plainLyrics ?? this.plainLyrics,
      syncedLyrics: syncedLyrics ?? this.syncedLyrics,
      language: language ?? this.language,
      provider: provider ?? this.provider,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Lyrics &&
          runtimeType == other.runtimeType &&
          songId == other.songId &&
          plainLyrics == other.plainLyrics &&
          language == other.language &&
          provider == other.provider &&
          _mapEquals(syncedLyrics, other.syncedLyrics);

  @override
  int get hashCode =>
      songId.hashCode ^
      plainLyrics.hashCode ^
      language.hashCode ^
      provider.hashCode ^
      (syncedLyrics == null
          ? 0
          : syncedLyrics!.keys.fold<int>(0, (prev, element) => prev ^ element.hashCode));

  bool _mapEquals(Map<Duration, String>? a, Map<Duration, String>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'Lyrics{songId: $songId, language: $language, provider: $provider, synced: ${syncedLyrics != null}}';
  }
}
