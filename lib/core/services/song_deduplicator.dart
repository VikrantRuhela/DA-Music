import '../../domain/entities/song.dart';

class SongDeduplicator {
  static const Set<String> _legitimateVariants = {
    'remix',
    'extended',
    'club',
    'live',
    'acoustic',
    'unplugged',
    'instrumental',
    'cover',
    'mashup',
    'rerecorded',
    're-recorded',
    'rerecord',
    're-record',
    'symphonic',
    'orchestral',
    'slowed',
    'reverb',
    'sped',
    'speed',
    'demo',
    'karaoke',
    'acapella',
    'a cappella',
    'rework',
    'dub',
    'edit',
  };

  static const List<String> _noiseTags = [
    'official music video',
    'official video',
    'official audio',
    'lyric video',
    'official lyric video',
    'lyrics video',
    'official visualizer',
    'visualizer',
    'full song',
    'full video',
    'video song',
    'audio song',
    'lyrics',
    'lyric',
    'official',
    'audio',
    'video',
    'hd',
    '4k',
    '8k',
    'topic',
    'explicit',
    'prod',
    'produced by',
  ];

  static String normalizeTitle(String rawTitle) {
    String title = rawTitle.toLowerCase();

    final RegExp bracketRegex = RegExp(r'[\(\[\{](.*?)[\)\]\}]');
    title = title.replaceAllMapped(bracketRegex, (match) {
      final inside = match.group(1) ?? '';
      final words = inside.split(RegExp(r'\s+'));
      for (final word in words) {
        if (_legitimateVariants.contains(word)) {
          return ' $inside ';
        }
      }
      return ' ';
    });

    for (final tag in _noiseTags) {
      title = title.replaceAll(tag, ' ');
    }

    title = title.replaceAll(RegExp(r'[^\w\s]'), ' ');
    title = title.replaceAll(RegExp(r'\s+'), ' ').trim();
    return title;
  }

  static String normalizeArtist(String rawArtist) {
    String artist = rawArtist.toLowerCase();
    artist = artist.replaceAll('- topic', ' ');
    artist = artist.replaceAll('topic', ' ');
    artist = artist.replaceAll('vevo', ' ');
    artist = artist.replaceAll('official', ' ');
    artist = artist.replaceAll(RegExp(r'[^\w\s]'), ' ');
    artist = artist.replaceAll(RegExp(r'\s+'), ' ').trim();
    return artist;
  }

  static String getNormalizedKey(String title, String artist) {
    final normTitle = normalizeTitle(title);
    final normArtist = normalizeArtist(artist);
    return '$normTitle|$normArtist';
  }

  static int calculateRankScore(Song song) {
    int score = 0;
    final lowerTitle = song.title.toLowerCase();
    final lowerArtist = song.artistId.toLowerCase();

    if (lowerTitle.contains('official audio')) {
      score += 100;
    } else if (lowerArtist.contains('topic') || lowerTitle.contains('topic')) {
      score += 90;
    } else if (lowerArtist.contains('vevo') || lowerArtist.contains('official')) {
      score += 80;
    } else if (lowerTitle.contains('official video') || lowerTitle.contains('official music video')) {
      score += 70;
    } else if (lowerTitle.contains('audio')) {
      score += 60;
    }

    final secs = song.duration.value.inSeconds;
    if (secs >= 90 && secs <= 420) {
      score += 20;
    }

    if (song.artwork.url.isNotEmpty) {
      score += 10;
    }

    if (song.albumId.isNotEmpty && song.albumId != 'yt_album_unknown') {
      score += 5;
    }

    score += (100 - song.title.length).clamp(0, 30);
    return score;
  }

  static List<Song> deduplicate(List<Song> songs) {
    if (songs.length <= 1) return songs;

    final Map<String, List<Song>> groups = {};
    final List<String> order = [];

    for (final song in songs) {
      final key = getNormalizedKey(song.title, song.artistId);
      if (!groups.containsKey(key)) {
        groups[key] = [];
        order.add(key);
      }
      groups[key]!.add(song);
    }

    final List<Song> deduplicated = [];
    for (final key in order) {
      final group = groups[key]!;
      if (group.length == 1) {
        deduplicated.add(group.first);
      } else {
        group.sort((a, b) => calculateRankScore(b).compareTo(calculateRankScore(a)));
        deduplicated.add(group.first);
      }
    }
    return deduplicated;
  }
}
