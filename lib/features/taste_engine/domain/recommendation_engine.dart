import 'dart:math';
import '../../../../shared/models/music_models.dart' as model;
import '../../../../core/services/source_manager.dart';
import '../../../../domain/entities/album.dart' as domain;
import '../../../../domain/entities/playlist.dart' as domain;
import '../../../../domain/entities/value_objects.dart' as domain;
import 'music_dna.dart';

class RecommendationEngine {
  static bool _isValidMusicCandidate(
    String title,
    String artist,
    Duration duration, {
    required void Function(String reason) onReject,
  }) {
    final titleLower = title.toLowerCase();
    final artistLower = artist.toLowerCase();

    // 1. Duration check: songs are generally between 45 seconds and 12 minutes
    final durationSecs = duration.inSeconds;
    if (durationSecs < 45) {
      onReject('Duration too short ($durationSecs s)');
      return false;
    }
    if (durationSecs > 720) {
      onReject('Duration too long ($durationSecs s)');
      return false;
    }

    // 2. Negative keyword check for non-music video content
    final negativeKeywords = [
      'vlog', 'tutorial', 'gameplay', 'shorts', 'meme', 'funny', 'reaction',
      'commentary', 'ceiling', 'podcast', 'unboxing', 'lesson', 'how to',
      'review', 'guide', 'walkthrough', 'unboxing', 'course', 'compilation',
      'leak', 'teaser', 'trailer', 'behind the scenes', 'bts', 'making of',
      'interview', 'talk show', 'gaming', 'stream', 'live stream', 'livestream',
      'test', 'commercial', 'haul', 'asmr', 'meditation', 'sleep music',
      'relaxing sounds', 'rain sounds', 'white noise', 'study beats compilation',
      '10 hours', '1 hour', 'loop', 'extended version', 'slowed + reverb compilation'
    ];

    for (final kw in negativeKeywords) {
      if (titleLower.contains(kw) || artistLower.contains(kw)) {
        onReject('Contains negative keyword "$kw"');
        return false;
      }
    }

    // 3. Reject generic non-music video titles
    final suspectPhrases = [
      'vlog #', 'vlog-', 'vlog_', 'my new', 'testing', 'opening', 'reaction to',
      'unboxing', 'reviewing', 'is it good', 'how i', 'why i', 'what is',
      'everything wrong with', 'honest review', 'tutorial', 'playthrough'
    ];

    for (final phrase in suspectPhrases) {
      if (titleLower.contains(phrase)) {
        onReject('Contains suspect non-music phrase "$phrase"');
        return false;
      }
    }

    return true;
  }

  static bool _isValidAlbumCandidate(String title, String artist, {required void Function(String reason) onReject}) {
    final titleLower = title.toLowerCase();
    final artistLower = artist.toLowerCase();

    final negativeKeywords = [
      'vlog', 'tutorial', 'gameplay', 'shorts', 'meme', 'funny', 'reaction',
      'commentary', 'ceiling', 'podcast', 'unboxing', 'lesson', 'how to',
      'review', 'guide', 'walkthrough', 'unboxing', 'course', 'compilation'
    ];

    for (final kw in negativeKeywords) {
      if (titleLower.contains(kw) || artistLower.contains(kw)) {
        onReject('Contains negative keyword "$kw"');
        return false;
      }
    }
    return true;
  }

  static bool _isValidPlaylistCandidate(String title, String description, {required void Function(String reason) onReject}) {
    final titleLower = title.toLowerCase();
    final descLower = description.toLowerCase();

    final negativeKeywords = [
      'vlog', 'tutorial', 'gameplay', 'shorts', 'meme', 'funny', 'reaction',
      'commentary', 'ceiling', 'podcast', 'unboxing', 'lesson', 'how to',
      'review', 'guide', 'walkthrough', 'unboxing', 'course', 'compilation'
    ];

    for (final kw in negativeKeywords) {
      if (titleLower.contains(kw) || descLower.contains(kw)) {
        onReject('Contains negative keyword "$kw"');
        return false;
      }
    }
    return true;
  }

  static Future<List<model.Song>> generateRecommendations({
    required MusicDNA dna,
    required SourceManager sourceManager,
    bool excludeDownloads = false,
    List<model.Song> downloadedSongs = const [],
    List<model.Song> ytmRecommendations = const [],
  }) async {
    final List<model.Song> results = [];
    final Set<String> seenIds = {};
    
    final Map<String, bool> artistSourceMap = {};
    final Map<String, bool> genreSourceMap = {};
    final Map<String, bool> trendingSourceMap = {};

    void addCandidate(model.Song song, {bool isArtist = false, bool isGenre = false, bool isTrending = false}) {
      if (seenIds.contains(song.id)) return;

      String? rejectReason;
      final isValid = _isValidMusicCandidate(
        song.title,
        song.artist,
        song.duration,
        onReject: (reason) => rejectReason = reason,
      );

      if (!isValid) {
        print(' [Recommendation Engine] REJECTED Candidate Song ID: ${song.id} | Title: "${song.title}" | Artist: "${song.artist}" | Reason: $rejectReason');
        return;
      }

      results.add(song);
      seenIds.add(song.id);
      if (isArtist) artistSourceMap[song.id] = true;
      if (isGenre) genreSourceMap[song.id] = true;
      if (isTrending) trendingSourceMap[song.id] = true;
    }

    if (excludeDownloads) {
      seenIds.addAll(downloadedSongs.map((s) => s.id));
    }

    if (ytmRecommendations.isNotEmpty) {
      for (final song in ytmRecommendations) {
        addCandidate(song);
      }
    }

    try {
      final adapter = sourceManager.activeAdapter;
      
      if (dna.topArtists.isNotEmpty) {
        for (final artist in dna.topArtists.take(2)) {
          final searchResult = await adapter.search('$artist songs');
          for (final song in searchResult.songs) {
            final mapped = model.Song(
              id: song.id,
              title: song.title,
              artist: song.artistId,
              album: song.albumId,
              duration: song.duration.value,
              artworkUrl: song.artwork.url,
              source: song.sourceId,
              lyrics: null,
            );
            addCandidate(mapped, isArtist: true);
          }
        }
      }

      final genreQuery = dna.favoriteGenres.isNotEmpty ? dna.favoriteGenres.first : 'Pop';
      final genreResults = await adapter.search('$genreQuery music');
      for (final song in genreResults.songs) {
        final mapped = model.Song(
          id: song.id,
          title: song.title,
          artist: song.artistId,
          album: song.albumId,
          duration: song.duration.value,
          artworkUrl: song.artwork.url,
          source: song.sourceId,
          lyrics: null,
        );
        addCandidate(mapped, isGenre: true);
      }

      final discoveryResults = await adapter.search('new release trending hits');
      for (final song in discoveryResults.songs) {
        final mapped = model.Song(
          id: song.id,
          title: song.title,
          artist: song.artistId,
          album: song.albumId,
          duration: song.duration.value,
          artworkUrl: song.artwork.url,
          source: song.sourceId,
          lyrics: null,
        );
        addCandidate(mapped, isTrending: true);
      }
    } catch (_) {
      // Fallback
    }

    final List<MapEntry<model.Song, double>> scoredSongs = [];
    for (final song in results) {
      double score = 0.0;
      double similarity = 0.0;
      double popularity = 0.0;

      // 1. Artist Affinity
      final artistAff = dna.artistAffinities[song.artist] ?? 0.0;
      if (dna.topArtists.contains(song.artist)) {
        score += 25.0;
        similarity += 1.0;
      }
      score += artistAff * 15.0;
      similarity += artistAff;

      // 2. Genre Affinity (fuzzy keyword match)
      for (final genre in dna.favoriteGenres) {
        final genreLower = genre.toLowerCase();
        final titleLower = song.title.toLowerCase();
        final artistLower = song.artist.toLowerCase();
        
        bool matchesGenre = false;
        if (titleLower.contains(genreLower) || artistLower.contains(genreLower)) {
          matchesGenre = true;
        } else if (genreLower == 'hip-hop' || genreLower == 'hip hop' || genreLower == 'rap') {
          if (titleLower.contains('rap') || titleLower.contains('hiphop') || titleLower.contains('trap') || titleLower.contains('beat')) {
            matchesGenre = true;
          }
        } else if (genreLower == 'pop') {
          if (titleLower.contains('pop') || titleLower.contains('hits') || titleLower.contains('chart')) {
            matchesGenre = true;
          }
        } else if (genreLower == 'rock' || genreLower == 'metal') {
          if (titleLower.contains('rock') || titleLower.contains('metal') || titleLower.contains('guitar') || titleLower.contains('band')) {
            matchesGenre = true;
          }
        } else if (genreLower == 'lo-fi' || genreLower == 'lofi' || genreLower == 'relaxing') {
          if (titleLower.contains('lofi') || titleLower.contains('chill') || titleLower.contains('relax')) {
            matchesGenre = true;
          }
        }
        
        if (matchesGenre) {
          score += 15.0;
          similarity += 0.8;
        }
        
        final genreAff = dna.genreAffinities[genre] ?? 0.0;
        score += genreAff * 8.0;
        similarity += genreAff * 0.5;
      }

      // 3. Curation Bonus
      final isYtmCurated = ytmRecommendations.any((s) => s.id == song.id);
      if (isYtmCurated) {
        score += 10.0;
      }

      // 4. Song Affinity
      if (dna.topSongs.contains(song.title)) {
        score += 30.0;
        similarity += 1.5;
      }
      final songAff = dna.songAffinities[song.title] ?? 0.0;
      score += songAff * 12.0;

      // 5. Source Category Weights (Taste preference over popularity)
      if (artistSourceMap[song.id] == true) {
        score += 10.0;
        similarity += 0.5;
      }
      if (genreSourceMap[song.id] == true) {
        score += 8.0;
        similarity += 0.4;
      }
      if (trendingSourceMap[song.id] == true) {
        score += 2.0;
        popularity += 1.0;
      }

      scoredSongs.add(MapEntry(song, score));
    }

    scoredSongs.sort((a, b) => b.value.compareTo(a.value));

    // Diversity check: max 2 songs per artist
    final Map<String, int> artistCounts = {};
    final List<model.Song> balanced = [];

    for (final entry in scoredSongs) {
      final song = entry.key;
      final score = entry.value;
      final artist = song.artist;
      final count = artistCounts[artist] ?? 0;

      if (count < 2) {
        balanced.add(song);
        artistCounts[artist] = count + 1;
        print(' [Recommendation Engine] SELECTED Song ID: ${song.id} | Type: Song | Title: "${song.title}" | Artist: "${song.artist}" | Score: $score | Reason: Selected based on taste metrics');
      } else {
        print(' [Recommendation Engine] SKIPPED Candidate Song ID: ${song.id} | Title: "${song.title}" | Artist: "${song.artist}" | Reason: Artist diversity limit reached');
      }
    }

    final finalResult = balanced.take(12).toList();
    if (finalResult.isEmpty) {
      return downloadedSongs.take(12).toList();
    }
    return finalResult;
  }

  static Future<List<domain.Album>> generateAlbumRecommendations({
    required MusicDNA dna,
    required SourceManager sourceManager,
    required List<domain.Album> ytmAlbums,
  }) async {
    final List<domain.Album> results = [];
    final Set<String> seenIds = {};

    void addAlbum(domain.Album album) {
      if (seenIds.contains(album.id)) return;
      
      String? rejectReason;
      final isValid = _isValidAlbumCandidate(
        album.title,
        album.artistId,
        onReject: (reason) => rejectReason = reason,
      );
      if (!isValid) {
        print(' [Recommendation Engine] REJECTED Candidate Album ID: ${album.id} | Title: "${album.title}" | Artist: "${album.artistId}" | Reason: $rejectReason');
        return;
      }
      results.add(album);
      seenIds.add(album.id);
    }

    for (final album in ytmAlbums) {
      addAlbum(album);
    }

    try {
      final adapter = sourceManager.activeAdapter;

      if (dna.topArtists.isNotEmpty) {
        for (final artist in dna.topArtists.take(3)) {
          final searchResult = await adapter.search('$artist album');
          for (final song in searchResult.songs) {
            final albumId = song.albumId;
            if (albumId.isNotEmpty && !seenIds.contains(albumId)) {
              final mappedAlbum = domain.Album(
                id: albumId,
                title: 'Album by $artist',
                artistId: artist,
                cover: song.artwork,
                year: 2026,
                trackCount: 10,
                duration: domain.DurationValue(const Duration(minutes: 40)),
              );
              addAlbum(mappedAlbum);
            }
          }
          for (final album in searchResult.albums) {
            addAlbum(album);
          }
        }
      }

      if (dna.favoriteGenres.isNotEmpty) {
        for (final genre in dna.favoriteGenres.take(2)) {
          final searchResult = await adapter.search('$genre hits album');
          for (final song in searchResult.songs) {
            final albumId = song.albumId;
            if (albumId.isNotEmpty && !seenIds.contains(albumId)) {
              final mappedAlbum = domain.Album(
                id: albumId,
                title: '$genre Hits',
                artistId: song.artistId,
                cover: song.artwork,
                year: 2026,
                trackCount: 10,
                duration: domain.DurationValue(const Duration(minutes: 40)),
              );
              addAlbum(mappedAlbum);
            }
          }
          for (final album in searchResult.albums) {
            addAlbum(album);
          }
        }
      }
    } catch (_) {}

    final List<MapEntry<domain.Album, double>> scored = [];
    for (final album in results) {
      double score = 0.0;

      if (dna.topArtists.contains(album.artistId)) {
        score += 15.0;
      }
      final artistAff = dna.artistAffinities[album.artistId] ?? 0.0;
      score += artistAff * 10.0;

      for (final genre in dna.favoriteGenres) {
        if (album.title.toLowerCase().contains(genre.toLowerCase()) ||
            album.artistId.toLowerCase().contains(genre.toLowerCase())) {
          score += 12.0;
        }
        final genreAff = dna.genreAffinities[genre] ?? 0.0;
        score += genreAff * 5.0;
      }

      final isYtmCurated = ytmAlbums.any((a) => a.id == album.id);
      if (isYtmCurated) {
        score += 8.0;
      }

      if (dna.topAlbums.contains(album.title)) {
        score += 20.0;
      }
      final albumAff = dna.albumAffinities[album.title] ?? 0.0;
      score += albumAff * 8.0;

      scored.add(MapEntry(album, score));
    }

    scored.sort((a, b) => b.value.compareTo(a.value));

    final Map<String, int> artistCounts = {};
    final List<domain.Album> balanced = [];
    for (final entry in scored) {
      final album = entry.key;
      final score = entry.value;
      final artist = album.artistId;
      final currentCount = artistCounts[artist] ?? 0;
      if (currentCount < 2) {
        balanced.add(album);
        artistCounts[artist] = currentCount + 1;
        print(' [Recommendation Engine] SELECTED Album ID: ${album.id} | Type: Album | Title: "${album.title}" | Artist: "${album.artistId}" | Score: $score | Reason: Selected based on taste metrics');
      } else {
        print(' [Recommendation Engine] SKIPPED Candidate Album ID: ${album.id} | Title: "${album.title}" | Artist: "${album.artistId}" | Reason: Artist diversity limit reached');
      }
    }

    return balanced.isEmpty ? ytmAlbums : balanced.take(12).toList();
  }

  static Future<List<domain.Playlist>> generatePlaylistRecommendations({
    required MusicDNA dna,
    required SourceManager sourceManager,
    required List<domain.Playlist> ytmPlaylists,
  }) async {
    final List<domain.Playlist> results = [];
    final Set<String> seenIds = {};

    void addPlaylist(domain.Playlist playlist) {
      if (seenIds.contains(playlist.id)) return;

      String? rejectReason;
      final isValid = _isValidPlaylistCandidate(
        playlist.title,
        playlist.description,
        onReject: (reason) => rejectReason = reason,
      );
      if (!isValid) {
        print(' [Recommendation Engine] REJECTED Candidate Playlist ID: ${playlist.id} | Title: "${playlist.title}" | Reason: $rejectReason');
        return;
      }
      results.add(playlist);
      seenIds.add(playlist.id);
    }

    for (final playlist in ytmPlaylists) {
      addPlaylist(playlist);
    }

    try {
      final adapter = sourceManager.activeAdapter;

      if (dna.topArtists.isNotEmpty) {
        for (final artist in dna.topArtists.take(3)) {
          final searchResult = await adapter.search('$artist playlist');
          for (final playlist in searchResult.playlists) {
            addPlaylist(playlist);
          }
        }
      }

      if (dna.favoriteGenres.isNotEmpty) {
        for (final genre in dna.favoriteGenres.take(2)) {
          final searchResult = await adapter.search('$genre mix playlist');
          for (final playlist in searchResult.playlists) {
            addPlaylist(playlist);
          }
        }
      }
    } catch (_) {}

    final List<MapEntry<domain.Playlist, double>> scored = [];
    for (final playlist in results) {
      double score = 0.0;

      for (final artist in dna.topArtists) {
        if (playlist.title.toLowerCase().contains(artist.toLowerCase()) ||
            playlist.description.toLowerCase().contains(artist.toLowerCase())) {
          score += 15.0;
        }
      }

      for (final genre in dna.favoriteGenres) {
        if (playlist.title.toLowerCase().contains(genre.toLowerCase()) ||
            playlist.description.toLowerCase().contains(genre.toLowerCase())) {
          score += 12.0;
        }
        final genreAff = dna.genreAffinities[genre] ?? 0.0;
        score += genreAff * 5.0;
      }

      final isYtmCurated = ytmPlaylists.any((p) => p.id == playlist.id);
      if (isYtmCurated) {
        score += 8.0;
      }

      scored.add(MapEntry(playlist, score));
    }

    scored.sort((a, b) => b.value.compareTo(a.value));

    final List<domain.Playlist> balanced = [];
    for (final entry in scored) {
      final playlist = entry.key;
      final score = entry.value;
      balanced.add(playlist);
      print(' [Recommendation Engine] SELECTED Playlist ID: ${playlist.id} | Type: Playlist | Title: "${playlist.title}" | Score: $score | Reason: Selected based on taste metrics');
    }

    return balanced.isEmpty ? ytmPlaylists : balanced.take(12).toList();
  }
}
