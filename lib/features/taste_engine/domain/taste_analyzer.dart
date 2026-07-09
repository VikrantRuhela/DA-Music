import 'music_dna.dart';
import '../../../shared/models/music_models.dart';

class TasteAnalyzer {
  static MusicDNA analyze(
    List<Map<String, dynamic>> logs, {
    int? downloadCount,
    int? favoriteCount,
    List<Song> downloadedSongs = const [],
    List<Song> likedSongs = const [],
  }) {
    final int finalDownloadCount = downloadCount ?? downloadedSongs.length;
    final int finalFavoriteCount = favoriteCount ?? likedSongs.length;

    if (logs.isEmpty && downloadedSongs.isEmpty && likedSongs.isEmpty) {
      return MusicDNA(
        downloadCount: finalDownloadCount,
        favoriteCount: finalFavoriteCount,
      );
    }

    final Map<String, double> artistAffinities = {};
    final Map<String, double> albumAffinities = {};
    final Map<String, double> songAffinities = {};
    final Map<String, double> genreAffinities = {};
    final Map<String, int> languageCounts = {};
    final Map<String, int> hourCounts = {};

    int totalPlays = 0;
    int completedCount = 0;
    int skipCount = 0;
    double totalDurationSeconds = 0.0;
    int sessionCount = 0;
    final Set<String> sessions = {};

    final Set<String> knownArtists = {};
    final Set<String> knownGenres = {};
    final Set<String> knownAlbums = {};

    // First, scan logs to gather basic info and build affinities
    for (final log in logs) {
      final String songId = log['songId'] ?? '';
      final String songTitle = log['songTitle'] ?? 'Unknown Song';
      final String artist = log['artist'] ?? 'Unknown Artist';
      final String album = log['album'] ?? 'Unknown Album';
      final String genre = log['genre'] ?? 'Pop';
      final String language = log['language'] ?? 'English';
      final double completionPct = (log['completionPercentage'] ?? 0.0).toDouble();
      final bool completed = log['completed'] == true || completionPct >= 85.0;
      final bool skipped = completionPct < 15.0;
      final int durationMs = log['durationMs'] ?? 0;
      final String sessionId = log['sessionId'] ?? '';
      final String startTimeStr = log['startTime'] ?? '';

      // Skip search query logs from play counting
      if (songId == 'search_query') continue;

      totalPlays++;
      if (artist.isNotEmpty && artist != 'Unknown Artist') knownArtists.add(artist);
      if (album.isNotEmpty && album != 'Unknown Album' && album != 'Single') knownAlbums.add(album);
      if (genre.isNotEmpty && genre != 'Unknown Genre') knownGenres.add(genre);

      // Determine score delta weight
      double weight = 0.0;
      if (completed) {
        weight = 1.0;
        completedCount++;
      } else if (skipped) {
        weight = -0.5;
        skipCount++;
      } else {
        weight = completionPct / 100.0;
      }

      if (songId.isNotEmpty) {
        songAffinities[songTitle] = (songAffinities[songTitle] ?? 0.0) + weight;
      }
      if (artist.isNotEmpty && artist != 'Unknown Artist') {
        artistAffinities[artist] = (artistAffinities[artist] ?? 0.0) + weight;
      }
      if (album.isNotEmpty && album != 'Unknown Album' && album != 'Single') {
        albumAffinities[album] = (albumAffinities[album] ?? 0.0) + weight;
      }
      if (genre.isNotEmpty && genre != 'Unknown Genre') {
        genreAffinities[genre] = (genreAffinities[genre] ?? 0.0) + weight;
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

      totalDurationSeconds += durationMs / 1000.0;
      if (sessionId.isNotEmpty) {
        sessions.add(sessionId);
      }
    }

    // 2. Add Favorite/Like boosts (+3.0)
    for (final song in likedSongs) {
      if (song.artist.isNotEmpty && song.artist != 'Unknown Artist') {
        knownArtists.add(song.artist);
        artistAffinities[song.artist] = (artistAffinities[song.artist] ?? 0.0) + 3.0;
      }
      if (song.album.isNotEmpty && song.album != 'Unknown Album' && song.album != 'Single') {
        knownAlbums.add(song.album);
        albumAffinities[song.album] = (albumAffinities[song.album] ?? 0.0) + 3.0;
      }
      songAffinities[song.title] = (songAffinities[song.title] ?? 0.0) + 3.0;
      genreAffinities['Pop'] = (genreAffinities['Pop'] ?? 0.0) + 1.0;
    }

    // 3. Add Download boosts (+2.0)
    for (final song in downloadedSongs) {
      if (song.artist.isNotEmpty && song.artist != 'Unknown Artist') {
        knownArtists.add(song.artist);
        artistAffinities[song.artist] = (artistAffinities[song.artist] ?? 0.0) + 2.0;
      }
      if (song.album.isNotEmpty && song.album != 'Unknown Album' && song.album != 'Single') {
        knownAlbums.add(song.album);
        albumAffinities[song.album] = (albumAffinities[song.album] ?? 0.0) + 2.0;
      }
      songAffinities[song.title] = (songAffinities[song.title] ?? 0.0) + 2.0;
      genreAffinities['Pop'] = (genreAffinities['Pop'] ?? 0.0) + 0.5;
    }

    // 4. Add Search queries matches boosts (+1.5)
    for (final log in logs) {
      final String songId = log['songId'] ?? '';
      final String songTitle = log['songTitle'] ?? '';
      if (songId == 'search_query' && songTitle.startsWith('Search: ')) {
        final query = songTitle.substring(8).toLowerCase().trim();
        if (query.isNotEmpty) {
          for (final artist in knownArtists) {
            if (artist.toLowerCase().contains(query) || query.contains(artist.toLowerCase())) {
              artistAffinities[artist] = (artistAffinities[artist] ?? 0.0) + 1.5;
            }
          }
          for (final genre in knownGenres) {
            if (genre.toLowerCase().contains(query) || query.contains(genre.toLowerCase())) {
              genreAffinities[genre] = (genreAffinities[genre] ?? 0.0) + 1.5;
            }
          }
        }
      }
    }

    // 5. Clamp all affinity scores to be non-negative
    artistAffinities.updateAll((k, v) => v < 0.0 ? 0.0 : v);
    albumAffinities.updateAll((k, v) => v < 0.0 ? 0.0 : v);
    songAffinities.updateAll((k, v) => v < 0.0 ? 0.0 : v);
    genreAffinities.updateAll((k, v) => v < 0.0 ? 0.0 : v);

    // 6. Generate sorted Top Lists from calculated scores
    final topArtists = _getSortedKeysFromDouble(artistAffinities, limit: 5);
    final topAlbums = _getSortedKeysFromDouble(albumAffinities, limit: 5);
    final topSongs = _getSortedKeysFromDouble(songAffinities, limit: 5);
    final favoriteGenres = _getSortedKeysFromDouble(genreAffinities, limit: 3);
    final favoriteLanguages = _getSortedKeys(languageCounts, limit: 3);

    sessionCount = sessions.length;
    final double avgSessionLenMin = sessionCount > 0 ? (totalDurationSeconds / 60.0) / sessionCount : 0.0;

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
    final double completionRate = totalPlays > 0 ? completedCount / totalPlays : 0.0;
    final double skipRate = totalPlays > 0 ? skipCount / totalPlays : 0.0;

    // Replay Rate calculation
    double replayRate = 0.0;
    if (totalPlays > 0) {
      // Filter out duplicate song plays
      final uniqueSongCount = songAffinities.keys.length;
      replayRate = uniqueSongCount > 0 ? (totalPlays - uniqueSongCount) / totalPlays : 0.0;
      if (replayRate < 0.0) replayRate = 0.0;
    }

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
      downloadCount: finalDownloadCount,
      favoriteCount: finalFavoriteCount,
      artistAffinities: artistAffinities,
      genreAffinities: genreAffinities,
      songAffinities: songAffinities,
      albumAffinities: albumAffinities,
    );
  }

  static List<String> _getSortedKeysFromDouble(Map<String, double> counts, {int limit = 10}) {
    final sorted = counts.entries.where((e) => e.value > 0.0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) => e.key).take(limit).toList();
  }

  static List<String> _getSortedKeys(Map<String, int> counts, {int limit = 10}) {
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) => e.key).take(limit).toList();
  }
}
