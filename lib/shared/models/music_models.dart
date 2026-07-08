import 'package:freezed_annotation/freezed_annotation.dart';

part 'music_models.freezed.dart';
part 'music_models.g.dart';

@freezed
class Song with _$Song {
  const factory Song({
    required String id,
    required String title,
    required String artist,
    required String album,
    required Duration duration,
    required String? artworkUrl,
    required String source,
    required String? lyrics,
    @Default(false) bool isFavorite,
  }) = _Song;

  factory Song.fromJson(Map<String, dynamic> json) => _$SongFromJson(json);
}

@freezed
class Album with _$Album {
  const factory Album({
    required String id,
    required String name,
    required String artist,
    required String? artworkUrl,
    required List<Song> songs,
  }) = _Album;

  factory Album.fromJson(Map<String, dynamic> json) => _$AlbumFromJson(json);
}

@freezed
class Artist with _$Artist {
  const factory Artist({
    required String id,
    required String name,
    required String? artworkUrl,
  }) = _Artist;

  factory Artist.fromJson(Map<String, dynamic> json) => _$ArtistFromJson(json);
}

@freezed
class Playlist with _$Playlist {
  const factory Playlist({
    required String id,
    required String name,
    required List<Song> songs,
  }) = _Playlist;

  factory Playlist.fromJson(Map<String, dynamic> json) => _$PlaylistFromJson(json);
}

@freezed
class QueueItem with _$QueueItem {
  const factory QueueItem({
    required String id,
    required Song song,
  }) = _QueueItem;

  factory QueueItem.fromJson(Map<String, dynamic> json) => _$QueueItemFromJson(json);
}

enum RepeatMode { off, one, all }

@freezed
class PlayerSettings with _$PlayerSettings {
  const factory PlayerSettings({
    @Default(80) int volume,
    @Default(false) bool isMuted,
    @Default(RepeatMode.off) RepeatMode repeatMode,
    @Default(false) bool isShuffle,
  }) = _PlayerSettings;

  factory PlayerSettings.fromJson(Map<String, dynamic> json) => _$PlayerSettingsFromJson(json);
}
