import 'dart:math';
import '../../../../shared/models/music_models.dart' as model;
import '../../../../core/services/source_manager.dart';
import '../../../../domain/entities/album.dart' as domain;
import '../../../../domain/entities/playlist.dart' as domain;
import '../../../../domain/entities/value_objects.dart' as domain;
import 'music_dna.dart';
import '../../../../core/services/youtube_music_adapter.dart';

class RecommendationEngine {
  static bool isValidMusicCandidate(
    String title,
    String artist,
    Duration duration, {
    void Function(String reason)? onReject,
  }) {
    final titleLower = title.toLowerCase();
    final artistLower = artist.toLowerCase();

    // 1. Duration check: songs are generally between 45 seconds and 12 minutes
    final durationSecs = duration.inSeconds;
    if (durationSecs < 45) {
      if (onReject != null) onReject('Duration too short ($durationSecs s)');
      return false;
    }
    if (durationSecs > 720) {
      if (onReject != null) onReject('Duration too long ($durationSecs s)');
      return false;
    }

    // 2. Negative keyword check for non-music video content and multi-song compilations
    final negativeKeywords = [
      'vlog', 'tutorial', 'gameplay', 'shorts', 'meme', 'funny', 'reaction',
      'commentary', 'ceiling', 'podcast', 'unboxing', 'lesson', 'how to',
      'review', 'guide', 'walkthrough', 'unboxing', 'course', 'compilation',
      'leak', 'teaser', 'trailer', 'behind the scenes', 'bts', 'making of',
      'interview', 'talk show', 'gaming', 'stream', 'live stream', 'livestream',
      'test', 'commercial', 'haul', 'asmr', 'meditation', 'sleep music',
      'relaxing sounds', 'rain sounds', 'white noise', 'study beats compilation',
      '10 hours', '1 hour', 'loop', 'extended version', 'slowed + reverb compilation',
      'mashup', 'mixtape', 'jukebox', 'nonstop', 'audio jukebox', 'album zip',
      'full audio', 'songs collection', 'all songs', 'greatest hits', 'full album', 'best of'
    ];

    for (final kw in negativeKeywords) {
      if (titleLower.contains(kw) || artistLower.contains(kw)) {
        if (onReject != null) onReject('Contains negative keyword "$kw"');
        return false;
      }
    }

    if (titleLower.contains('music mix')) {
      if (onReject != null) onReject('Contains compilation phrase "music mix"');
      return false;
    }
    if (titleLower.contains('hot 50')) {
      if (onReject != null) onReject('Contains compilation phrase "hot 50"');
      return false;
    }

    final numericPattern = RegExp(r'\b(hot|top)\s*(\d+)\b', caseSensitive: false);
    for (final match in numericPattern.allMatches(titleLower)) {
      final numberStr = match.group(2);
      if (numberStr != null) {
        final val = int.tryParse(numberStr);
        if (val != null && val >= 1 && val <= 100) {
          if (onReject != null) onReject('Contains compilation pattern "${match.group(0)}"');
          return false;
        }
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
        if (onReject != null) onReject('Contains suspect non-music phrase "$phrase"');
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
      final isValid = isValidMusicCandidate(
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

  static Future<List<model.Song>> generateTrendingRecommendations({
    required MusicDNA dna,
    required SourceManager sourceManager,
    List<model.Song> genericSongs = const [],
  }) async {
    final List<model.Song> results = [];
    final Set<String> seenIds = {};

    final Map<String, bool> fromTrendingSearch = {};
    final Map<String, bool> fromGlobalTrending = {};
    final Map<String, String> candidateSources = {};

    void addCandidate(model.Song song, {required String source, bool isSearch = false, bool isGlobal = false}) {
      if (seenIds.contains(song.id)) return;

      String? rejectReason;
      final isValid = isValidMusicCandidate(
        song.title,
        song.artist,
        song.duration,
        onReject: (reason) => rejectReason = reason,
      );

      if (!isValid) {
        print(' [Recommendation Engine] REJECTED Trending Candidate Song ID: ${song.id} | Source: $source | Title: "${song.title}" | Artist: "${song.artist}" | Reason: $rejectReason');
        return;
      }

      results.add(song);
      seenIds.add(song.id);
      candidateSources[song.id] = source;
      if (isSearch) fromTrendingSearch[song.id] = true;
      if (isGlobal) fromGlobalTrending[song.id] = true;
    }

    // 1. Gather candidates from global trending/recommended
    for (final song in genericSongs) {
      addCandidate(song, source: 'Global Home Recommended', isGlobal: true);
    }

    // 2. Gather candidates from searches based on user's favorite genres
    try {
      final adapter = sourceManager.activeAdapter;
      for (final genre in dna.favoriteGenres.take(3)) {
        final searchRes = await adapter.search('trending $genre music');
        for (final song in searchRes.songs) {
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
          addCandidate(mapped, source: 'Trending Genre Search ($genre)', isSearch: true);
        }
      }

      // 3. Gather candidates from searches based on user's top artists
      for (final artist in dna.topArtists.take(2)) {
        final searchRes = await adapter.search('trending $artist');
        for (final song in searchRes.songs) {
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
          addCandidate(mapped, source: 'Trending Artist Search ($artist)', isSearch: true);
        }
      }
    } catch (_) {}

    final List<MapEntry<model.Song, double>> scoredSongs = [];

    for (final song in results) {
      double personalizationScore = 0.0;
      double genreScore = 0.0;
      double similarityScore = 0.0;
      double trendingBonus = 0.0;

      // A. Artist Match
      final artistAff = dna.artistAffinities[song.artist] ?? 0.0;
      if (dna.topArtists.contains(song.artist)) {
        personalizationScore += 25.0;
        similarityScore += 10.0;
      }
      personalizationScore += artistAff * 15.0;
      similarityScore += artistAff * 5.0;

      // B. Genre Match
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
        }

        if (matchesGenre) {
          genreScore += 15.0;
          similarityScore += 5.0;
        }

        final genreAff = dna.genreAffinities[genre] ?? 0.0;
        genreScore += genreAff * 8.0;
      }

      // C. Song Match
      if (dna.topSongs.contains(song.title)) {
        personalizationScore += 30.0;
      }
      final songAff = dna.songAffinities[song.title] ?? 0.0;
      personalizationScore += songAff * 12.0;

      // D. Trending Source Weight
      if (fromGlobalTrending[song.id] == true) {
        trendingBonus += 5.0;
      }
      if (fromTrendingSearch[song.id] == true) {
        trendingBonus += 8.0;
      }

      final finalScore = personalizationScore + genreScore + similarityScore + trendingBonus;

      print(' [Recommendation Engine] CANDIDATE Song ID: ${song.id} | Source: ${candidateSources[song.id]} | Title: "${song.title}" | Artist: "${song.artist}" | Personalization Score: $personalizationScore | Genre Score: $genreScore | Similarity Score: $similarityScore | Trending Bonus: $trendingBonus | Final Score: $finalScore');

      scoredSongs.add(MapEntry(song, finalScore));
    }

    scoredSongs.sort((a, b) => b.value.compareTo(a.value));

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
        print(' [Recommendation Engine] SELECTED Trending Song ID: ${song.id} | Title: "${song.title}" | Artist: "${song.artist}" | Final Score: $score | Reason: High taste match score');
      } else {
        print(' [Recommendation Engine] SKIPPED Candidate Trending Song ID: ${song.id} | Title: "${song.title}" | Artist: "${song.artist}" | Reason: Artist diversity limit reached');
      }
    }

    final finalResult = balanced.take(10).toList();
    if (finalResult.isEmpty) {
      return genericSongs.take(10).toList();
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

  static const Map<String, List<String>> similarArtistsMap = {
    'karan aujla': ['ap dhillon', 'shubh', 'sidhu moose wala', 'diljit dosanjh', 'amrit maan'],
    'ap dhillon': ['karan aujla', 'shubh', 'sidhu moose wala', 'diljit dosanjh', 'gurinder gill'],
    'shubh': ['karan aujla', 'ap dhillon', 'sidhu moose wala', 'diljit dosanjh', 'prophec'],
    'sidhu moose wala': ['karan aujla', 'ap dhillon', 'shubh', 'diljit dosanjh', 'amrit maan'],
    'diljit dosanjh': ['karan aujla', 'ap dhillon', 'shubh', 'sidhu moose wala', 'amrinder gill'],
    'eminem': ['drake', 'tupac', 'kanye west', 'lil wayne', 'snoop dogg', 'dr. dre', '50 cent'],
    'drake': ['eminem', 'kanye west', 'lil wayne', 'travis scott', 'future', 'the weeknd'],
    'beatles': ['queen', 'pink floyd', 'led zeppelin', 'the rolling stones', 'david bowie'],
    'queen': ['beatles', 'pink floyd', 'led zeppelin', 'elton john', 'david bowie'],
  };

  static const Map<String, List<String>> verifiedArtistChannelIds = {
    'shubh': [
      'UCtGbExCzlwmsyWKpxLnyEww', // Official Artist Channel (OAC)
      'UCFzC-gq9Z_xG4Vz_d9J5QSw', // Topic channel
    ],
    'karan aujla': [
      'UC7G2-92nQn-C_3C0_02j1-w',
      'UCxH0M1t0-NqYFz_y2n6B27w', // Topic
    ],
  };

  static const Map<String, List<String>> nonMusicChannelIds = {
    'shubh': [
      'UCs38d2LpL2hY3_qM9g3vBdw',
      'UC8hS21S3N_R7T3X6J8kQxrw',
    ],
  };

  static bool isOfficialMusicChannel(String? channelId, String channelTitle, String artist) {
    final titleLower = channelTitle.toLowerCase();
    if (titleLower.endsWith(' - topic') || titleLower.contains('vevo') || titleLower.contains('official')) {
      return true;
    }
    if (channelId != null) {
      final artistLower = artist.toLowerCase().trim();
      final verifiedIds = verifiedArtistChannelIds[artistLower];
      if (verifiedIds != null && verifiedIds.contains(channelId)) {
        return true;
      }
      final blacklistIds = nonMusicChannelIds[artistLower];
      if (blacklistIds != null && blacklistIds.contains(channelId)) {
        return false;
      }
    }
    final ignoreWords = ['gaming', 'vlogs', 'vlog', 'plays', 'streamer', 'clips', 'shorts', 'reaction', 'comedy', 'funny'];
    for (final word in ignoreWords) {
      if (titleLower.contains(word)) return false;
    }
    return true;
  }

  static String detectGenre(String artist, String songTitle) {
    final artistLower = artist.toLowerCase();
    final titleLower = songTitle.toLowerCase();
    
    // 1. Hindi / Bollywood
    if (artistLower.contains('arijit') ||
        artistLower.contains('shreya') ||
        artistLower.contains('neha kakkar') ||
        artistLower.contains('jubin') ||
        artistLower.contains('badshah') ||
        artistLower.contains('pritam') ||
        artistLower.contains('rahman') ||
        titleLower.contains('bollywood') ||
        titleLower.contains('hindi')) {
      return 'Hindi';
    }

    // 2. Punjabi
    if (artistLower.contains('aujla') ||
        artistLower.contains('dosanjh') ||
        artistLower.contains('sidhu') ||
        artistLower.contains('maan') ||
        artistLower.contains('singh') ||
        artistLower.contains('amrit') ||
        artistLower.contains('dhillon') ||
        artistLower.contains('shubh') ||
        artistLower.contains('arjan')) {
      return 'Punjabi';
    }

    // 3. K-Pop
    if (artistLower.contains('bts') ||
        artistLower.contains('blackpink') ||
        artistLower.contains('twice') ||
        artistLower.contains('exo') ||
        artistLower.contains('stray kids') ||
        titleLower.contains('k-pop') ||
        titleLower.contains('kpop')) {
      return 'K-Pop';
    }

    // 4. Hip-Hop / Rap
    if (artistLower.contains('eminem') ||
        artistLower.contains('drake') ||
        artistLower.contains('tupac') ||
        artistLower.contains('kanye') ||
        artistLower.contains('wayne') ||
        artistLower.contains('snoop') ||
        titleLower.contains('hiphop') ||
        titleLower.contains('hip-hop') ||
        titleLower.contains('rap')) {
      return 'Hip-Hop';
    }

    // 5. Rock
    if (artistLower.contains('beatles') ||
        artistLower.contains('queen') ||
        artistLower.contains('pink floyd') ||
        artistLower.contains('led zeppelin') ||
        titleLower.contains('rock') ||
        titleLower.contains('metal')) {
      return 'Rock';
    }

    // 6. Lo-fi / Chill
    if (artistLower.contains('lo-fi') ||
        titleLower.contains('lofi') ||
        titleLower.contains('relax') ||
        titleLower.contains('study') ||
        titleLower.contains('chill') ||
        titleLower.contains('ambient')) {
      return 'Lo-fi';
    }
    
    return 'Pop'; // default fallback
  }

  static String detectLanguage(String artist, String songTitle) {
    final genre = detectGenre(artist, songTitle);
    if (genre == 'Punjabi') return 'Punjabi';
    if (genre == 'Hindi') return 'Hindi';
    if (genre == 'K-Pop') return 'Korean';
    return 'English';
  }

  static bool isAlternativeVersion(String titleA, String titleB) {
    final cleanA = _normalizeTitle(titleA);
    final cleanB = _normalizeTitle(titleB);
    if (cleanA == cleanB) return true;

    final versionKeywords = ['remix', 'live', 'slowed', 'reverb', 'cover', 'instrumental', 'acoustic', 'version', 'edit', 'mix'];
    if (cleanA.contains(cleanB) || cleanB.contains(cleanA)) {
      for (final kw in versionKeywords) {
        if (cleanA.contains(kw) || cleanB.contains(kw)) {
          return true;
        }
      }
    }
    return false;
  }

  static String _normalizeTitle(String title) {
    String clean = title.toLowerCase();
    
    // Remove content inside parentheses and brackets
    clean = clean.replaceAll(RegExp(r'\s*\([^)]*\)'), '');
    clean = clean.replaceAll(RegExp(r'\s*\[[^\]]*\]'), '');
    clean = clean.replaceAll(RegExp(r'\s*\|.*$'), ''); // Remove everything after |
    
    // Remove typical alternative version keywords
    final versionKeywords = [
      'remix', 'live', 'slowed', 'reverb', 'cover', 'instrumental', 
      'acoustic', 'version', 'edit', 'mix', 'sped up', 'spedup', 
      'visualizer', 'clean', 'official video', 'lyric video', 
      'music video', 'karaoke', 'tribute', 'parody', 'mashup'
    ];
    
    for (final kw in versionKeywords) {
      clean = clean.replaceAll(kw, '');
    }
    
    return clean
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _buildReason(
    double artistScore,
    double genreScore,
    double similarArtistScore,
    double historyScore,
    String seedArtist,
    String genre,
  ) {
    if (artistScore > 0) return 'Same Artist ($seedArtist)';
    if (similarArtistScore > 0) return 'Similar Artist related to $seedArtist';
    if (historyScore > 4.0) return 'Liked/Downloaded song in your History';
    if (genreScore > 0) return 'Matches current genre ($genre)';
    return 'Popular trending in $genre';
  }

  static Future<List<model.Song>> generateSmartQueue({
    required model.Song seedSong,
    required MusicDNA dna,
    required SourceManager sourceManager,
    List<model.Song> downloadedSongs = const [],
    List<model.Song> likedSongs = const [],
    List<model.Song> recentlyPlayedSongs = const [],
  }) async {
    final List<model.Song> candidates = [];
    final Set<String> seenIds = {seedSong.id};

    final adapter = sourceManager.activeAdapter;
    final detectedGenre = detectGenre(seedSong.artist, seedSong.title);

    // Build dynamic listening session profile from seed song and recent log history
    final List<model.Song> sessionHistory = [seedSong, ...recentlyPlayedSongs.take(9)];

    final Map<String, double> sessionArtists = {};
    for (int i = 0; i < sessionHistory.length; i++) {
      final artist = sessionHistory[i].artist.trim();
      if (artist.isEmpty || artist == 'Unknown Artist') continue;
      final weight = 1.0 / (i + 1);
      sessionArtists[artist] = (sessionArtists[artist] ?? 0.0) + weight;
    }

    final Map<String, double> sessionGenres = {};
    for (int i = 0; i < sessionHistory.length; i++) {
      final song = sessionHistory[i];
      final g = detectGenre(song.artist, song.title);
      final weight = 1.0 / (i + 1);
      sessionGenres[g] = (sessionGenres[g] ?? 0.0) + weight;
    }

    final Map<String, double> sessionLanguages = {};
    for (int i = 0; i < sessionHistory.length; i++) {
      final song = sessionHistory[i];
      final l = detectLanguage(song.artist, song.title);
      final weight = 1.0 / (i + 1);
      sessionLanguages[l] = (sessionLanguages[l] ?? 0.0) + weight;
    }

    final String primarySessionLanguage = sessionLanguages.isNotEmpty
        ? (sessionLanguages.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key
        : detectLanguage(seedSong.artist, seedSong.title);

    final String primarySessionGenre = sessionGenres.isNotEmpty
        ? (sessionGenres.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key
        : detectedGenre;

    final searchFutures = <Future<void>>[];

    // 1. Same Artist
    if (seedSong.artist.isNotEmpty && seedSong.artist != 'Unknown Artist') {
      searchFutures.add(() async {
        try {
          final res = await adapter.search(seedSong.artist);
          for (final s in res.songs) {
            candidates.add(model.Song(
              id: s.id,
              title: s.title,
              artist: s.artistId,
              album: s.albumId,
              duration: s.duration.value,
              artworkUrl: s.artwork.url,
              source: s.sourceId,
              lyrics: null,
            ));
          }
        } catch (_) {}
      }());
    }

    // 2. Similar Artists
    final artistLower = seedSong.artist.toLowerCase().trim();
    List<String> similarArtists = [];
    for (final entry in similarArtistsMap.entries) {
      if (artistLower.contains(entry.key) || entry.key.contains(artistLower)) {
        similarArtists = entry.value;
        break;
      }
    }
    if (similarArtists.isEmpty) {
      similarArtists = dna.topArtists.where((a) => a.toLowerCase() != artistLower).toList();
    }
    
    for (final simArtist in similarArtists.take(2)) {
      searchFutures.add(() async {
        try {
          final res = await adapter.search(simArtist);
          for (final s in res.songs) {
            candidates.add(model.Song(
              id: s.id,
              title: s.title,
              artist: s.artistId,
              album: s.albumId,
              duration: s.duration.value,
              artworkUrl: s.artwork.url,
              source: s.sourceId,
              lyrics: null,
            ));
          }
        } catch (_) {}
      }());
    }

    // 3. Same Genre / Trending Genre
    searchFutures.add(() async {
      try {
        final res = await adapter.search('$detectedGenre hits');
        for (final s in res.songs) {
          candidates.add(model.Song(
            id: s.id,
            title: s.title,
            artist: s.artistId,
            album: s.albumId,
            duration: s.duration.value,
            artworkUrl: s.artwork.url,
            source: s.sourceId,
            lyrics: null,
          ));
        }
      } catch (_) {}
    }());

    searchFutures.add(() async {
      try {
        final res = await adapter.search('trending $detectedGenre');
        for (final s in res.songs) {
          candidates.add(model.Song(
            id: s.id,
            title: s.title,
            artist: s.artistId,
            album: s.albumId,
            duration: s.duration.value,
            artworkUrl: s.artwork.url,
            source: s.sourceId,
            lyrics: null,
          ));
        }
      } catch (_) {}
    }());

    await Future.wait(searchFutures).timeout(const Duration(seconds: 4), onTimeout: () => []);

    final List<MapEntry<model.Song, Map<String, dynamic>>> scoredCandidates = [];
    final Set<String> seenNormalizedTitles = {
      _normalizeTitle(seedSong.title)
    };

    bool isSameArtist(String artistA, String artistB) {
      final cleanA = artistA.toLowerCase().trim();
      final cleanB = artistB.toLowerCase().trim();
      if (cleanA == cleanB) return true;
      if (cleanA == 'various' || cleanA == 'various artists' || cleanB == 'various' || cleanB == 'various artists') {
        return false;
      }
      if (cleanA.contains(cleanB) || cleanB.contains(cleanA)) return true;
      return false;
    }

    bool isCompatibleGenre(String genreA, String genreB) {
      if (genreA == genreB) return true;
      final compatiblePairs = {
        'Pop': ['Lo-fi', 'Hindi', 'Punjabi', 'K-Pop'],
        'Lo-fi': ['Pop'],
        'Hip-Hop': ['Punjabi', 'Hindi', 'Rap'],
        'Punjabi': ['Hip-Hop', 'Pop'],
        'Hindi': ['Pop', 'Hip-Hop'],
      };
      final list = compatiblePairs[genreA];
      return list != null && list.contains(genreB);
    }

    bool isCompatibleLanguage(String langA, String langB) {
      if (langA == langB) return true;
      if (langA == 'English' || langB == 'English') return true;
      return false;
    }

    double calculateScore(model.Song song) {
      double score = 0.0;
      
      // 1. Same Album boost
      final cleanAlbum = song.album.toLowerCase().trim();
      final seedAlbum = seedSong.album.toLowerCase().trim();
      if (cleanAlbum.isNotEmpty && cleanAlbum == seedAlbum && cleanAlbum != 'single' && cleanAlbum != 'unknown album') {
        score += 50.0;
      }
      
      // 2. Personal History boost (liked or downloaded)
      final isLiked = likedSongs.any((s) => s.id == song.id);
      final isDownloaded = downloadedSongs.any((s) => s.id == song.id);
      if (isLiked) score += 20.0;
      if (isDownloaded) score += 15.0;

      // 3. Play count boost
      final playCount = recentlyPlayedSongs.where((s) => s.id == song.id).length;
      score += playCount * 5.0;

      // 4. DNA Artist / Genre affinities
      final artistAff = dna.artistAffinities[song.artist] ?? 0.0;
      score += artistAff * 10.0;
      
      final songGenre = detectGenre(song.artist, song.title);
      final genreAff = dna.genreAffinities[songGenre] ?? 0.0;
      score += genreAff * 5.0;

      return score;
    }

    final List<MapEntry<model.Song, Map<String, dynamic>>> sameArtistCandidates = [];
    final List<MapEntry<model.Song, Map<String, dynamic>>> similarGenreCandidates = [];

    for (final song in candidates) {
      if (seenIds.contains(song.id)) continue;
      
      final normalizedTitle = _normalizeTitle(song.title);
      if (seenNormalizedTitles.contains(normalizedTitle)) {
        continue;
      }

      String? rejectReason;
      final isValid = isValidMusicCandidate(
        song.title,
        song.artist,
        song.duration,
        onReject: (reason) => rejectReason = reason,
      );

      if (!isValid) {
        continue;
      }

      if (isAlternativeVersion(song.title, seedSong.title)) {
        continue;
      }

      final candidateChannelId = YouTubeMusicAdapter.videoChannelIdMap[song.id];
      final candidateAuthor = YouTubeMusicAdapter.videoAuthorMap[song.id] ?? song.artist;
      final isOfficial = isOfficialMusicChannel(candidateChannelId, candidateAuthor, seedSong.artist);
      if (!isOfficial) {
        continue;
      }

      final songGenre = detectGenre(song.artist, song.title);
      final songLanguage = detectLanguage(song.artist, song.title);

      // Validate genre compatibility
      if (!isCompatibleGenre(songGenre, primarySessionGenre)) {
        continue;
      }

      // Validate language compatibility
      if (!isCompatibleLanguage(songLanguage, primarySessionLanguage)) {
        continue;
      }

      final double score = calculateScore(song);

      final candidateData = {
        'song': song,
        'finalScore': score,
        'detectedGenre': songGenre,
        'reason': _buildReason(
          isSameArtist(song.artist, seedSong.artist) ? 20.0 : 0.0,
          songGenre == primarySessionGenre ? 40.0 : 0.0,
          similarArtists.any((a) => song.artist.toLowerCase().contains(a.toLowerCase())) ? 15.0 : 0.0,
          0.0,
          seedSong.artist,
          songGenre,
        ),
      };

      if (isSameArtist(song.artist, seedSong.artist)) {
        sameArtistCandidates.add(MapEntry(song, candidateData));
      } else {
        similarGenreCandidates.add(MapEntry(song, candidateData));
      }

      seenIds.add(song.id);
      seenNormalizedTitles.add(normalizedTitle);
    }

    // Sort both descending by finalScore
    sameArtistCandidates.sort((a, b) => (b.value['finalScore'] as double).compareTo(a.value['finalScore'] as double));
    similarGenreCandidates.sort((a, b) => (b.value['finalScore'] as double).compareTo(a.value['finalScore'] as double));

    final List<model.Song> finalSmartQueue = [];
    final Set<String> addedIds = {};

    void addSong(model.Song s, Map<String, dynamic> metrics) {
      if (!addedIds.contains(s.id)) {
        finalSmartQueue.add(s);
        addedIds.add(s.id);
        
        // ignore: avoid_print
        print(' [Smart Queue] SELECTED Candidate:');
        // ignore: avoid_print
        print('   - Title: "${s.title}"');
        // ignore: avoid_print
        print('   - Artist: "${s.artist}"');
        // ignore: avoid_print
        print('   - Genre: "${metrics['detectedGenre']}"');
        // ignore: avoid_print
        print('   - Rank Score: ${metrics['finalScore']}');
        // ignore: avoid_print
        print('   - Reason: ${metrics['reason']}');
        // ignore: avoid_print
        print('-------------------------------------------');
      }
    }

    // ignore: avoid_print
    print('=== SMART QUEUE GENERATION DIAGNOSTICS ===');
    // ignore: avoid_print
    print('- Seed Song: "${seedSong.title}" by ${seedSong.artist}');
    // ignore: avoid_print
    print('- Seed Artist: ${seedSong.artist}');
    // ignore: avoid_print
    print('- Seed Genre: $detectedGenre');
    // ignore: avoid_print
    print('- Same Artist Candidates: ${sameArtistCandidates.length}');
    // ignore: avoid_print
    print('- Similar Genre Candidates: ${similarGenreCandidates.length}');
    // ignore: avoid_print
    print('-------------------------------------------');

    // 1. Take up to 10 same artist songs (~70% of a 14-song queue)
    int sameArtistCount = 0;
    for (final entry in sameArtistCandidates) {
      if (sameArtistCount >= 10) break;
      addSong(entry.key, entry.value);
      sameArtistCount++;
    }

    // 2. Take similar genre/mood/style songs (~30%), ensuring diversity of at most 1 song per artist
    final Map<String, int> otherArtistCounts = {};
    int similarGenreCount = 0;
    final int targetGenreCount = 14 - finalSmartQueue.length; // Intelligently backfill up to 14 slots
    
    for (final entry in similarGenreCandidates) {
      if (similarGenreCount >= targetGenreCount) break;
      final song = entry.key;
      final count = otherArtistCounts[song.artist] ?? 0;
      if (count < 1) {
        addSong(song, entry.value);
        otherArtistCounts[song.artist] = count + 1;
        similarGenreCount++;
      }
    }

    // 3. Fallback: if we still haven't reached 14, relax the diversity limit to 2 songs per other artist
    if (finalSmartQueue.length < 14) {
      for (final entry in similarGenreCandidates) {
        if (finalSmartQueue.length >= 14) break;
        final song = entry.key;
        if (!addedIds.contains(song.id)) {
          final count = otherArtistCounts[song.artist] ?? 0;
          if (count < 2) {
            addSong(song, entry.value);
            otherArtistCounts[song.artist] = count + 1;
          }
        }
      }
    }

    // 4. Ultimate fallback: if we still have space, just add any remaining candidates
    if (finalSmartQueue.length < 14) {
      for (final entry in sameArtistCandidates) {
        if (finalSmartQueue.length >= 14) break;
        addSong(entry.key, entry.value);
      }
    }
    if (finalSmartQueue.length < 14) {
      for (final entry in similarGenreCandidates) {
        if (finalSmartQueue.length >= 14) break;
        addSong(entry.key, entry.value);
      }
    }

    // 5. Raw Fallback: if we still have space or queue is empty (due to strict filters), add raw candidates directly
    if (finalSmartQueue.isEmpty) {
      for (final song in candidates) {
        if (finalSmartQueue.length >= 10) break;
        if (song.id != seedSong.id && !addedIds.contains(song.id)) {
          finalSmartQueue.add(song);
          addedIds.add(song.id);
        }
      }
    }

    // 6. Database/History Fallback: if we STILL have nothing (e.g. no network results returned at all),
    // use liked, downloaded or recently played songs to guarantee autoplay doesn't fail!
    if (finalSmartQueue.isEmpty) {
      final fallbackList = [...likedSongs, ...downloadedSongs, ...recentlyPlayedSongs];
      for (final song in fallbackList) {
        if (finalSmartQueue.length >= 10) break;
        if (song.id != seedSong.id && !addedIds.contains(song.id)) {
          finalSmartQueue.add(song);
          addedIds.add(song.id);
        }
      }
    }

    return finalSmartQueue;
  }
}
