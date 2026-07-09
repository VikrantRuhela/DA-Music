import 'music_dna.dart';

class TasteAnalyzer {
  static MusicDNA analyze(List<Map<String, dynamic>> logs, {int downloadCount = 0, int favoriteCount = 0}) {
    if (logs.isEmpty) {
      return MusicDNA(
        downloadCount: downloadCount,
        favoriteCount: favoriteCount,
      );
    }

    final Map<String, int> artistCounts = {};
    final Map<String, int> albumCounts = {};
    final Map<String, int> songCounts = {};
    final Map<String, int> genreCounts = {};
    final Map<String, int> languageCounts = {};
    final Map<String, int> hourCounts = {};

    int totalPlays = logs.length;
    int completedCount = 0;
    int skipCount = 0;
    double totalDurationSeconds = 0.0;
    int sessionCount = 0;
    final Set<String> sessions = {};

    for (final log in logs) {
      final String songId = log['songId'] ?? '';
      final String songTitle = log['songTitle'] ?? 'Unknown Song';
      final String artist = log['artist'] ?? 'Unknown Artist';
      final String album = log['album'] ?? 'Unknown Album';
      final String genre = log['genre'] ?? 'Unknown Genre';
      final String language = log['language'] ?? 'English';
      final double completionPct = (log['completionPercentage'] ?? 0.0).toDouble();
      final bool completed = log['completed'] == true || completionPct >= 85.0;
      final bool skipped = completionPct < 15.0;
      final int durationMs = log['durationMs'] ?? 0;
      final String sessionId = log['sessionId'] ?? '';
      final String startTimeStr = log['startTime'] ?? '';

      if (songId.isNotEmpty) {
        songCounts[songTitle] = (songCounts[songTitle] ?? 0) + 1;
      }
      if (artist.isNotEmpty && artist != 'Unknown Artist') {
        artistCounts[artist] = (artistCounts[artist] ?? 0) + 1;
      }
      if (album.isNotEmpty && album != 'Unknown Album' && album != 'Single') {
        albumCounts[album] = (albumCounts[album] ?? 0) + 1;
      }
      if (genre.isNotEmpty && genre != 'Unknown Genre') {
        genreCounts[genre] = (genreCounts[genre] ?? 0) + 1;
      }
      if (language.isNotEmpty) {
        languageCounts[language] = (languageCounts[language] ?? 0) + 1;
      }

      if (startTimeStr.isNotEmpty) {
        try {
          final dt = DateTime.parse(startTimeStr);
          hourCounts[dt.hour.toString()] = (hourCounts[dt.hour.toString()] ?? 0) + 1;
        } catch (_) {}
      }

      if (completed) completedCount++;
      if (skipped) skipCount++;
      totalDurationSeconds += durationMs / 1000.0;

      if (sessionId.isNotEmpty) {
        sessions.add(sessionId);
      }
    }

    sessionCount = sessions.length;
    final double avgSessionLenMin = sessionCount > 0 ? (totalDurationSeconds / 60.0) / sessionCount : 0.0;

    // Top Lists
    final topArtists = _getSortedKeys(artistCounts, limit: 5);
    final topAlbums = _getSortedKeys(albumCounts, limit: 5);
    final topSongs = _getSortedKeys(songCounts, limit: 5);
    final favoriteGenres = _getSortedKeys(genreCounts, limit: 3);
    final favoriteLanguages = _getSortedKeys(languageCounts, limit: 3);

    // Peak Listening Time
    String peakListeningTime = 'N/A';
    if (hourCounts.isNotEmpty) {
      final sortedHours = _getSortedKeys(hourCounts);
      if (sortedHours.isNotEmpty) {
        final int peakHour = int.parse(sortedHours.first);
        if (peakHour >= 6 && peakHour < 12) {
          peakListeningTime = 'Morning (6 AM - 12 PM)';
        } else if (peakHour >= 12 && peakHour < 18) {
          peakListeningTime = 'Afternoon (12 PM - 6 PM)';
        } else if (peakHour >= 18 && peakHour < 22) {
          peakListeningTime = 'Evening (6 PM - 10 PM)';
        } else {
          peakListeningTime = 'Night (10 PM - 6 AM)';
        }
      }
    }

    // Rates
    final double completionRate = completedCount / totalPlays;
    final double skipRate = skipCount / totalPlays;

    // Replay Rate calculation: ratio of duplicate song plays to total plays
    double replayRate = 0.0;
    if (totalPlays > 0) {
      final uniqueSongs = songCounts.length;
      replayRate = (totalPlays - uniqueSongs) / totalPlays;
    }

    // Decades Calculation (mocked based on song count or simple decade heuristics)
    final List<String> favoriteDecades = ['2020s', '2010s'];

    // Listening Mood Classifier
    String listeningMood = 'Immersive Listener';
    if (skipRate > 0.4) {
      listeningMood = 'Selective Explorer';
    } else if (peakListeningTime.contains('Night')) {
      listeningMood = 'Chill & Relaxed';
    } else if (peakListeningTime.contains('Morning')) {
      listeningMood = 'Energetic / Focus';
    }

    return MusicDNA(
      topArtists: topArtists,
      topAlbums: topAlbums,
      topSongs: topSongs,
      favoriteGenres: favoriteGenres.isEmpty ? ['Pop', 'Lo-fi'] : favoriteGenres,
      favoriteLanguages: favoriteLanguages.isEmpty ? ['English'] : favoriteLanguages,
      favoriteDecades: favoriteDecades,
      listeningMood: listeningMood,
      peakListeningTime: peakListeningTime,
      averageSessionLengthMinutes: avgSessionLenMin,
      replayRate: replayRate,
      skipRate: skipRate,
      completionRate: completionRate,
      downloadCount: downloadCount,
      favoriteCount: favoriteCount,
    );
  }

  static List<String> _getSortedKeys(Map<String, int> counts, {int limit = 10}) {
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) => e.key).take(limit).toList();
  }
}
