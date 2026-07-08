import '../../domain/entities/song.dart';
import '../../domain/entities/album.dart';
import '../../domain/entities/artist.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/entities/lyrics.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/entities/value_objects.dart';
import '../../../shared/models/music_models.dart' as shared;

/// Data layer model representing a song record.
class SongModel {
  final String id;
  final String title;
  final String artistId;
  final String albumId;
  final int durationMs;
  final String thumbnailUrl;
  final String artworkUrl;
  final String? streamUrl;
  final String? lyricsId;
  final bool isLiked;
  final bool isDownloaded;
  final String sourceId;

  SongModel({
    required this.id,
    required this.title,
    required this.artistId,
    required this.albumId,
    required this.durationMs,
    required this.thumbnailUrl,
    required this.artworkUrl,
    this.streamUrl,
    this.lyricsId,
    this.isLiked = false,
    this.isDownloaded = false,
    required this.sourceId,
  });

  Song toEntity() {
    return Song(
      id: id,
      title: title,
      artistId: artistId,
      albumId: albumId,
      duration: DurationValue(Duration(milliseconds: durationMs)),
      thumbnail: Artwork(thumbnailUrl),
      artwork: Artwork(artworkUrl),
      streamUrl: streamUrl,
      lyricsId: lyricsId,
      isLiked: isLiked,
      isDownloaded: isDownloaded,
      sourceId: sourceId,
    );
  }

  factory SongModel.fromEntity(Song song) {
    return SongModel(
      id: song.id,
      title: song.title,
      artistId: song.artistId,
      albumId: song.albumId,
      durationMs: song.duration.value.inMilliseconds,
      thumbnailUrl: song.thumbnail.url,
      artworkUrl: song.artwork.url,
      streamUrl: song.streamUrl,
      lyricsId: song.lyricsId,
      isLiked: song.isLiked,
      isDownloaded: song.isDownloaded,
      sourceId: song.sourceId,
    );
  }
}

/// Data layer model representing an album record.
class AlbumModel {
  final String id;
  final String title;
  final String artistId;
  final String coverUrl;
  final int year;
  final int trackCount;
  final int durationMs;

  AlbumModel({
    required this.id,
    required this.title,
    required this.artistId,
    required this.coverUrl,
    required this.year,
    required this.trackCount,
    required this.durationMs,
  });

  Album toEntity() {
    return Album(
      id: id,
      title: title,
      artistId: artistId,
      cover: Artwork(coverUrl),
      year: year,
      trackCount: trackCount,
      duration: DurationValue(Duration(milliseconds: durationMs)),
    );
  }

  factory AlbumModel.fromEntity(Album album) {
    return AlbumModel(
      id: album.id,
      title: album.title,
      artistId: album.artistId,
      coverUrl: album.cover.url,
      year: album.year,
      trackCount: album.trackCount,
      durationMs: album.duration.value.inMilliseconds,
    );
  }
}

/// Data layer model representing an artist record.
class ArtistModel {
  final String id;
  final String name;
  final String imageUrl;
  final int subscriberCount;
  final String description;
  final List<String> genres;

  ArtistModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.subscriberCount,
    required this.description,
    required this.genres,
  });

  Artist toEntity() {
    return Artist(
      id: id,
      name: name,
      image: Artwork(imageUrl),
      subscriberCount: subscriberCount,
      description: description,
      genres: genres,
    );
  }

  factory ArtistModel.fromEntity(Artist artist) {
    return ArtistModel(
      id: artist.id,
      name: artist.name,
      imageUrl: artist.image.url,
      subscriberCount: artist.subscriberCount,
      description: artist.description,
      genres: artist.genres,
    );
  }
}

/// Data layer model representing a playlist record.
class PlaylistModel {
  final String id;
  final String title;
  final String description;
  final String coverUrl;
  final String owner;
  final List<String> songIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  PlaylistModel({
    required this.id,
    required this.title,
    required this.description,
    required this.coverUrl,
    required this.owner,
    required this.songIds,
    required this.createdAt,
    required this.updatedAt,
  });

  Playlist toEntity() {
    return Playlist(
      id: id,
      title: title,
      description: description,
      cover: Artwork(coverUrl),
      owner: owner,
      songIds: songIds,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory PlaylistModel.fromEntity(Playlist playlist) {
    return PlaylistModel(
      id: playlist.id,
      title: playlist.title,
      description: playlist.description,
      coverUrl: playlist.cover.url,
      owner: playlist.owner,
      songIds: playlist.songIds,
      createdAt: playlist.createdAt,
      updatedAt: playlist.updatedAt,
    );
  }
}

/// Data layer model representing song lyrics.
class LyricsModel {
  final String songId;
  final String plainLyrics;
  final Map<Duration, String>? syncedLyrics;
  final String language;
  final String provider;

  LyricsModel({
    required this.songId,
    required this.plainLyrics,
    this.syncedLyrics,
    required this.language,
    required this.provider,
  });

  Lyrics toEntity() {
    return Lyrics(
      songId: songId,
      plainLyrics: plainLyrics,
      syncedLyrics: syncedLyrics,
      language: language,
      provider: provider,
    );
  }

  factory LyricsModel.fromEntity(Lyrics lyrics) {
    return LyricsModel(
      songId: lyrics.songId,
      plainLyrics: lyrics.plainLyrics,
      syncedLyrics: lyrics.syncedLyrics,
      language: lyrics.language,
      provider: lyrics.provider,
    );
  }
}

/// Data layer model representing query search results.
class SearchResultModel {
  final List<SongModel> songs;
  final List<AlbumModel> albums;
  final List<ArtistModel> artists;
  final List<PlaylistModel> playlists;
  final dynamic topResult;

  SearchResultModel({
    required this.songs,
    required this.albums,
    required this.artists,
    required this.playlists,
    this.topResult,
  });

  SearchResult toEntity() {
    return SearchResult(
      songs: songs.map((s) => s.toEntity()).toList(),
      albums: albums.map((a) => a.toEntity()).toList(),
      artists: artists.map((a) => a.toEntity()).toList(),
      playlists: playlists.map((p) => p.toEntity()).toList(),
      topResult: topResult,
    );
  }
}

/// Data layer model representing player settings parameters.
class SettingsModel {
  final int volume;
  final bool isMuted;
  final String repeatMode;
  final bool isShuffle;

  SettingsModel({
    required this.volume,
    required this.isMuted,
    required this.repeatMode,
    required this.isShuffle,
  });

  shared.PlayerSettings toShared() {
    final shared.RepeatMode mode;
    switch (repeatMode) {
      case 'one':
        mode = shared.RepeatMode.one;
        break;
      case 'all':
        mode = shared.RepeatMode.all;
        break;
      default:
        mode = shared.RepeatMode.off;
        break;
    }
    return shared.PlayerSettings(
      volume: volume,
      isMuted: isMuted,
      repeatMode: mode,
      isShuffle: isShuffle,
    );
  }

  factory SettingsModel.fromShared(shared.PlayerSettings settings) {
    final String mode;
    switch (settings.repeatMode) {
      case shared.RepeatMode.one:
        mode = 'one';
        break;
      case shared.RepeatMode.all:
        mode = 'all';
        break;
      default:
        mode = 'off';
        break;
    }
    return SettingsModel(
      volume: settings.volume,
      isMuted: settings.isMuted,
      repeatMode: mode,
      isShuffle: settings.isShuffle,
    );
  }
}
