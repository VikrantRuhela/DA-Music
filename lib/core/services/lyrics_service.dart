import '../../domain/entities/lyrics.dart';

abstract class LyricsService {
  Future<Lyrics> getLyrics(String songId);
}
