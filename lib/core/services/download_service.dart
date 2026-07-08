import '../../domain/entities/song.dart';

abstract class DownloadService {
  Future<void> downloadSong(Song song);
  Future<void> pauseDownload(String songId);
  Future<void> resumeDownload(String songId);
  Future<void> cancelDownload(String songId);
}
