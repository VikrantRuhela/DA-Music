import '../entities/lyrics.dart';

abstract class LyricsRepository {
  Future<Lyrics> getLyricsBySongId(String songId);
  Future<void> saveLyrics(Lyrics lyrics);
}
