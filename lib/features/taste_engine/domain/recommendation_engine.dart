import 'dart:math';
import '../../../../shared/models/music_models.dart' as model;
import '../../../../core/services/source_manager.dart';
import '../../../../domain/entities/album.dart' as domain;
import '../../../../domain/entities/playlist.dart' as domain;
import '../../../../domain/entities/value_objects.dart' as domain;
import 'music_dna.dart';

class RecommendationEngine {
  static Future<List<model.Song>> generateRecommendations({
    required MusicDNA dna,
    required SourceManager sourceManager,
    bool excludeDownloads = false,
    List<model.Song> downloadedSongs = const [],
    List<model.Song> ytmRecommendations = const [],
  }) async {
    final List<model.Song> results = [];
    final Set<String> seenIds = {};

    if (excludeDownloads) {
      seenIds.addAll(downloadedSongs.map((s) => s.id));
    }

    if (ytmRecommendations.isNotEmpty) {
      for (final song in ytmRecommendations) {
        if (!seenIds.contains(song.id)) {
          results.add(song);
          seenIds.add(song.id);
        }
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
            if (!seenIds.contains(mapped.id)) {
              results.add(mapped);
              seenIds.add(mapped.id);
            }
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
        if (!seenIds.contains(mapped.id)) {
          results.add(mapped);
          seenIds.add(mapped.id);
        }
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
        if (!seenIds.contains(mapped.id)) {
          results.add(mapped);
          seenIds.add(mapped.id);
        }
      }
    } catch (_) {
      return downloadedSongs.where((s) => !seenIds.contains(s.id)).toList();
    }

    final List<model.Song> balanced = [];
    final random = Random();

    if (results.isNotEmpty) {
      balanced.addAll(results);
      balanced.shuffle(random);
    } else {
      balanced.addAll(downloadedSongs);
    }

    return balanced.take(12).toList();
  }

  static Future<List<domain.Album>> generateAlbumRecommendations({
    required MusicDNA dna,
    required SourceManager sourceManager,
    required List<domain.Album> ytmAlbums,
  }) async {
    final List<domain.Album> results = [];
    final Set<String> seenIds = {};

    for (final album in ytmAlbums) {
      if (!seenIds.contains(album.id)) {
        results.add(album);
        seenIds.add(album.id);
      }
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
              results.add(mappedAlbum);
              seenIds.add(albumId);
            }
          }
          for (final album in searchResult.albums) {
            if (!seenIds.contains(album.id)) {
              results.add(album);
              seenIds.add(album.id);
            }
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
              results.add(mappedAlbum);
              seenIds.add(albumId);
            }
          }
          for (final album in searchResult.albums) {
            if (!seenIds.contains(album.id)) {
              results.add(album);
              seenIds.add(album.id);
            }
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
      final artist = album.artistId;
      final currentCount = artistCounts[artist] ?? 0;
      if (currentCount < 2) {
        balanced.add(album);
        artistCounts[artist] = currentCount + 1;
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

    for (final playlist in ytmPlaylists) {
      if (!seenIds.contains(playlist.id)) {
        results.add(playlist);
        seenIds.add(playlist.id);
      }
    }

    try {
      final adapter = sourceManager.activeAdapter;

      if (dna.topArtists.isNotEmpty) {
        for (final artist in dna.topArtists.take(3)) {
          final searchResult = await adapter.search('$artist playlist');
          for (final playlist in searchResult.playlists) {
            if (!seenIds.contains(playlist.id)) {
              results.add(playlist);
              seenIds.add(playlist.id);
            }
          }
        }
      }

      if (dna.favoriteGenres.isNotEmpty) {
        for (final genre in dna.favoriteGenres.take(2)) {
          final searchResult = await adapter.search('$genre mix playlist');
          for (final playlist in searchResult.playlists) {
            if (!seenIds.contains(playlist.id)) {
              results.add(playlist);
              seenIds.add(playlist.id);
            }
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

    final List<domain.Playlist> balanced = scored.map((e) => e.key).toList();

    return balanced.isEmpty ? ytmPlaylists : balanced.take(12).toList();
  }
}
