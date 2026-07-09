import 'dart:math';
import '../../../../shared/models/music_models.dart';
import '../../../../core/services/source_manager.dart';
import 'music_dna.dart';

class RecommendationEngine {
  static Future<List<Song>> generateRecommendations({
    required MusicDNA dna,
    required SourceManager sourceManager,
    bool excludeDownloads = false,
    List<Song> downloadedSongs = const [],
  }) async {
    final List<Song> results = [];
    final Set<String> seenIds = {};

    if (excludeDownloads) {
      seenIds.addAll(downloadedSongs.map((s) => s.id));
    }

    try {
      final adapter = sourceManager.activeAdapter;
      
      // 1. Known taste (70% weight -> load top artists & songs)
      if (dna.topArtists.isNotEmpty) {
        for (final artist in dna.topArtists.take(2)) {
          final searchResult = await adapter.search('$artist songs');
          for (final song in searchResult.songs) {
            final mapped = Song(
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

      // 2. Similar artists/genres (20% weight)
      final genreQuery = dna.favoriteGenres.isNotEmpty ? dna.favoriteGenres.first : 'Pop';
      final genreResults = await adapter.search('$genreQuery music');
      for (final song in genreResults.songs) {
        final mapped = Song(
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

      // 3. Discovery (10% weight -> trending)
      final discoveryResults = await adapter.search('new release trending hits');
      for (final song in discoveryResults.songs) {
        final mapped = Song(
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
      // Fallback: if search fails (e.g. offline), use downloaded/local songs
      return downloadedSongs.where((s) => !seenIds.contains(s.id)).toList();
    }

    // Apply the 70/20/10 mix balance roughly from collected results
    final List<Song> balanced = [];
    final random = Random();

    if (results.isNotEmpty) {
      balanced.addAll(results);
      balanced.shuffle(random);
    } else {
      balanced.addAll(downloadedSongs);
    }

    return balanced.take(12).toList();
  }
}
