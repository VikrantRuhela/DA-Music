// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'source_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SongItemImpl _$$SongItemImplFromJson(Map<String, dynamic> json) =>
    _$SongItemImpl(
      Song.fromJson(json['song'] as Map<String, dynamic>),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$SongItemImplToJson(_$SongItemImpl instance) =>
    <String, dynamic>{'song': instance.song, 'runtimeType': instance.$type};

_$AlbumItemImpl _$$AlbumItemImplFromJson(Map<String, dynamic> json) =>
    _$AlbumItemImpl(
      Album.fromJson(json['album'] as Map<String, dynamic>),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$AlbumItemImplToJson(_$AlbumItemImpl instance) =>
    <String, dynamic>{'album': instance.album, 'runtimeType': instance.$type};

_$ArtistItemImpl _$$ArtistItemImplFromJson(Map<String, dynamic> json) =>
    _$ArtistItemImpl(
      Artist.fromJson(json['artist'] as Map<String, dynamic>),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$ArtistItemImplToJson(_$ArtistItemImpl instance) =>
    <String, dynamic>{'artist': instance.artist, 'runtimeType': instance.$type};

_$PlaylistItemImpl _$$PlaylistItemImplFromJson(Map<String, dynamic> json) =>
    _$PlaylistItemImpl(
      Playlist.fromJson(json['playlist'] as Map<String, dynamic>),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$PlaylistItemImplToJson(_$PlaylistItemImpl instance) =>
    <String, dynamic>{
      'playlist': instance.playlist,
      'runtimeType': instance.$type,
    };

_$SearchResultImpl _$$SearchResultImplFromJson(Map<String, dynamic> json) =>
    _$SearchResultImpl(
      query: json['query'] as String,
      topResult: json['topResult'] == null
          ? null
          : SearchResultItem.fromJson(
              json['topResult'] as Map<String, dynamic>,
            ),
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => SearchResultItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$SearchResultImplToJson(_$SearchResultImpl instance) =>
    <String, dynamic>{
      'query': instance.query,
      'topResult': instance.topResult,
      'items': instance.items,
    };

_$HomeFeedSectionImpl _$$HomeFeedSectionImplFromJson(
  Map<String, dynamic> json,
) => _$HomeFeedSectionImpl(
  id: json['id'] as String,
  title: json['title'] as String,
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => SearchResultItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$$HomeFeedSectionImplToJson(
  _$HomeFeedSectionImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'items': instance.items,
};

_$HomeFeedImpl _$$HomeFeedImplFromJson(Map<String, dynamic> json) =>
    _$HomeFeedImpl(
      sections:
          (json['sections'] as List<dynamic>?)
              ?.map((e) => HomeFeedSection.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$HomeFeedImplToJson(_$HomeFeedImpl instance) =>
    <String, dynamic>{'sections': instance.sections};

_$AudioStreamImpl _$$AudioStreamImplFromJson(Map<String, dynamic> json) =>
    _$AudioStreamImpl(
      id: json['id'] as String,
      streamUrl: json['streamUrl'] as String,
      format: json['format'] as String,
      bitrate: (json['bitrate'] as num).toInt(),
      expiration: Duration(microseconds: (json['expiration'] as num).toInt()),
    );

Map<String, dynamic> _$$AudioStreamImplToJson(_$AudioStreamImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'streamUrl': instance.streamUrl,
      'format': instance.format,
      'bitrate': instance.bitrate,
      'expiration': instance.expiration.inMicroseconds,
    };

_$LyricsImpl _$$LyricsImplFromJson(Map<String, dynamic> json) => _$LyricsImpl(
  text: json['text'] as String,
  isTimed: json['isTimed'] as bool? ?? false,
);

Map<String, dynamic> _$$LyricsImplToJson(_$LyricsImpl instance) =>
    <String, dynamic>{'text': instance.text, 'isTimed': instance.isTimed};
