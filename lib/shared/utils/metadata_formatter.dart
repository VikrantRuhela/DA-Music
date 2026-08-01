import '../../domain/entities/song.dart';
import '../models/music_models.dart' as shared;

class MetadataFormatter {
  static String formatArtist(String artist) {
    if (artist.trim().isEmpty) return 'Unknown Artist';
    if (artist.contains(' • ')) {
      final parts = artist.split(' • ');
      return parts.first.trim();
    }
    return artist.trim();
  }

  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString();
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  static String formatSongSubtitle(dynamic songObj, {bool showAlbum = false, bool showDuration = false}) {
    String rawArtist = 'Unknown Artist';
    String albumName = '';
    Duration duration = Duration.zero;

    if (songObj is Song) {
      rawArtist = songObj.artistId;
      albumName = songObj.albumId;
      duration = songObj.duration.value;
    } else if (songObj is shared.Song) {
      rawArtist = songObj.artist;
      albumName = songObj.album;
      duration = songObj.duration;
    }

    final cleanArtist = formatArtist(rawArtist);

    final List<String> parts = [cleanArtist];

    if (showAlbum && albumName.isNotEmpty && albumName != 'Single' && albumName != 'yt_album_unknown') {
      parts.add(albumName);
    }

    if (showDuration && duration > Duration.zero) {
      parts.add(formatDuration(duration));
    }

    return parts.join(' • ');
  }
}
