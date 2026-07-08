import '../../domain/entities/lyrics.dart';

/// Abstract contract representing an external source for song lyrics.
abstract class LyricsProvider {
  String get id;
  String get name;

  /// Fetches lyrics from the provider with candidate matching.
  Future<Lyrics?> fetchLyrics({
    required String songId,
    required String title,
    required String artist,
    required String album,
    required Duration duration,
  });
}
