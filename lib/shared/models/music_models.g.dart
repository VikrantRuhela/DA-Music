// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'music_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SongImpl _$$SongImplFromJson(Map<String, dynamic> json) => _$SongImpl(
  id: json['id'] as String,
  title: json['title'] as String,
  artist: json['artist'] as String,
  album: json['album'] as String,
  duration: Duration(microseconds: (json['duration'] as num).toInt()),
  artworkUrl: json['artworkUrl'] as String?,
  source: json['source'] as String,
  lyrics: json['lyrics'] as String?,
  isFavorite: json['isFavorite'] as bool? ?? false,
);

Map<String, dynamic> _$$SongImplToJson(_$SongImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'artist': instance.artist,
      'album': instance.album,
      'duration': instance.duration.inMicroseconds,
      'artworkUrl': instance.artworkUrl,
      'source': instance.source,
      'lyrics': instance.lyrics,
      'isFavorite': instance.isFavorite,
    };

_$AlbumImpl _$$AlbumImplFromJson(Map<String, dynamic> json) => _$AlbumImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  artist: json['artist'] as String,
  artworkUrl: json['artworkUrl'] as String?,
  songs: (json['songs'] as List<dynamic>)
      .map((e) => Song.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$$AlbumImplToJson(_$AlbumImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'artist': instance.artist,
      'artworkUrl': instance.artworkUrl,
      'songs': instance.songs,
    };

_$ArtistImpl _$$ArtistImplFromJson(Map<String, dynamic> json) => _$ArtistImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  artworkUrl: json['artworkUrl'] as String?,
);

Map<String, dynamic> _$$ArtistImplToJson(_$ArtistImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'artworkUrl': instance.artworkUrl,
    };

_$PlaylistImpl _$$PlaylistImplFromJson(Map<String, dynamic> json) =>
    _$PlaylistImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      songs: (json['songs'] as List<dynamic>)
          .map((e) => Song.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$PlaylistImplToJson(_$PlaylistImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'songs': instance.songs,
    };

_$QueueItemImpl _$$QueueItemImplFromJson(Map<String, dynamic> json) =>
    _$QueueItemImpl(
      id: json['id'] as String,
      song: Song.fromJson(json['song'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$QueueItemImplToJson(_$QueueItemImpl instance) =>
    <String, dynamic>{'id': instance.id, 'song': instance.song};

_$PlayerSettingsImpl _$$PlayerSettingsImplFromJson(Map<String, dynamic> json) =>
    _$PlayerSettingsImpl(
      volume: (json['volume'] as num?)?.toInt() ?? 80,
      isMuted: json['isMuted'] as bool? ?? false,
      repeatMode:
          $enumDecodeNullable(_$RepeatModeEnumMap, json['repeatMode']) ??
          RepeatMode.off,
      isShuffle: json['isShuffle'] as bool? ?? false,
    );

Map<String, dynamic> _$$PlayerSettingsImplToJson(
  _$PlayerSettingsImpl instance,
) => <String, dynamic>{
  'volume': instance.volume,
  'isMuted': instance.isMuted,
  'repeatMode': _$RepeatModeEnumMap[instance.repeatMode]!,
  'isShuffle': instance.isShuffle,
};

const _$RepeatModeEnumMap = {
  RepeatMode.off: 'off',
  RepeatMode.one: 'one',
  RepeatMode.all: 'all',
};
