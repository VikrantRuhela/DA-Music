// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'source_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SearchResultItem _$SearchResultItemFromJson(Map<String, dynamic> json) {
  switch (json['runtimeType']) {
    case 'song':
      return _SongItem.fromJson(json);
    case 'album':
      return _AlbumItem.fromJson(json);
    case 'artist':
      return _ArtistItem.fromJson(json);
    case 'playlist':
      return _PlaylistItem.fromJson(json);

    default:
      throw CheckedFromJsonException(
        json,
        'runtimeType',
        'SearchResultItem',
        'Invalid union type "${json['runtimeType']}"!',
      );
  }
}

/// @nodoc
mixin _$SearchResultItem {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Song song) song,
    required TResult Function(Album album) album,
    required TResult Function(Artist artist) artist,
    required TResult Function(Playlist playlist) playlist,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Song song)? song,
    TResult? Function(Album album)? album,
    TResult? Function(Artist artist)? artist,
    TResult? Function(Playlist playlist)? playlist,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Song song)? song,
    TResult Function(Album album)? album,
    TResult Function(Artist artist)? artist,
    TResult Function(Playlist playlist)? playlist,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_SongItem value) song,
    required TResult Function(_AlbumItem value) album,
    required TResult Function(_ArtistItem value) artist,
    required TResult Function(_PlaylistItem value) playlist,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_SongItem value)? song,
    TResult? Function(_AlbumItem value)? album,
    TResult? Function(_ArtistItem value)? artist,
    TResult? Function(_PlaylistItem value)? playlist,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_SongItem value)? song,
    TResult Function(_AlbumItem value)? album,
    TResult Function(_ArtistItem value)? artist,
    TResult Function(_PlaylistItem value)? playlist,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;

  /// Serializes this SearchResultItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SearchResultItemCopyWith<$Res> {
  factory $SearchResultItemCopyWith(
    SearchResultItem value,
    $Res Function(SearchResultItem) then,
  ) = _$SearchResultItemCopyWithImpl<$Res, SearchResultItem>;
}

/// @nodoc
class _$SearchResultItemCopyWithImpl<$Res, $Val extends SearchResultItem>
    implements $SearchResultItemCopyWith<$Res> {
  _$SearchResultItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SearchResultItem
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$SongItemImplCopyWith<$Res> {
  factory _$$SongItemImplCopyWith(
    _$SongItemImpl value,
    $Res Function(_$SongItemImpl) then,
  ) = __$$SongItemImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Song song});

  $SongCopyWith<$Res> get song;
}

/// @nodoc
class __$$SongItemImplCopyWithImpl<$Res>
    extends _$SearchResultItemCopyWithImpl<$Res, _$SongItemImpl>
    implements _$$SongItemImplCopyWith<$Res> {
  __$$SongItemImplCopyWithImpl(
    _$SongItemImpl _value,
    $Res Function(_$SongItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SearchResultItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? song = null}) {
    return _then(
      _$SongItemImpl(
        null == song
            ? _value.song
            : song // ignore: cast_nullable_to_non_nullable
                  as Song,
      ),
    );
  }

  /// Create a copy of SearchResultItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SongCopyWith<$Res> get song {
    return $SongCopyWith<$Res>(_value.song, (value) {
      return _then(_value.copyWith(song: value));
    });
  }
}

/// @nodoc
@JsonSerializable()
class _$SongItemImpl implements _SongItem {
  const _$SongItemImpl(this.song, {final String? $type})
    : $type = $type ?? 'song';

  factory _$SongItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$SongItemImplFromJson(json);

  @override
  final Song song;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'SearchResultItem.song(song: $song)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SongItemImpl &&
            (identical(other.song, song) || other.song == song));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, song);

  /// Create a copy of SearchResultItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SongItemImplCopyWith<_$SongItemImpl> get copyWith =>
      __$$SongItemImplCopyWithImpl<_$SongItemImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Song song) song,
    required TResult Function(Album album) album,
    required TResult Function(Artist artist) artist,
    required TResult Function(Playlist playlist) playlist,
  }) {
    return song(this.song);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Song song)? song,
    TResult? Function(Album album)? album,
    TResult? Function(Artist artist)? artist,
    TResult? Function(Playlist playlist)? playlist,
  }) {
    return song?.call(this.song);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Song song)? song,
    TResult Function(Album album)? album,
    TResult Function(Artist artist)? artist,
    TResult Function(Playlist playlist)? playlist,
    required TResult orElse(),
  }) {
    if (song != null) {
      return song(this.song);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_SongItem value) song,
    required TResult Function(_AlbumItem value) album,
    required TResult Function(_ArtistItem value) artist,
    required TResult Function(_PlaylistItem value) playlist,
  }) {
    return song(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_SongItem value)? song,
    TResult? Function(_AlbumItem value)? album,
    TResult? Function(_ArtistItem value)? artist,
    TResult? Function(_PlaylistItem value)? playlist,
  }) {
    return song?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_SongItem value)? song,
    TResult Function(_AlbumItem value)? album,
    TResult Function(_ArtistItem value)? artist,
    TResult Function(_PlaylistItem value)? playlist,
    required TResult orElse(),
  }) {
    if (song != null) {
      return song(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$SongItemImplToJson(this);
  }
}

abstract class _SongItem implements SearchResultItem {
  const factory _SongItem(final Song song) = _$SongItemImpl;

  factory _SongItem.fromJson(Map<String, dynamic> json) =
      _$SongItemImpl.fromJson;

  Song get song;

  /// Create a copy of SearchResultItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SongItemImplCopyWith<_$SongItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$AlbumItemImplCopyWith<$Res> {
  factory _$$AlbumItemImplCopyWith(
    _$AlbumItemImpl value,
    $Res Function(_$AlbumItemImpl) then,
  ) = __$$AlbumItemImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Album album});

  $AlbumCopyWith<$Res> get album;
}

/// @nodoc
class __$$AlbumItemImplCopyWithImpl<$Res>
    extends _$SearchResultItemCopyWithImpl<$Res, _$AlbumItemImpl>
    implements _$$AlbumItemImplCopyWith<$Res> {
  __$$AlbumItemImplCopyWithImpl(
    _$AlbumItemImpl _value,
    $Res Function(_$AlbumItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SearchResultItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? album = null}) {
    return _then(
      _$AlbumItemImpl(
        null == album
            ? _value.album
            : album // ignore: cast_nullable_to_non_nullable
                  as Album,
      ),
    );
  }

  /// Create a copy of SearchResultItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AlbumCopyWith<$Res> get album {
    return $AlbumCopyWith<$Res>(_value.album, (value) {
      return _then(_value.copyWith(album: value));
    });
  }
}

/// @nodoc
@JsonSerializable()
class _$AlbumItemImpl implements _AlbumItem {
  const _$AlbumItemImpl(this.album, {final String? $type})
    : $type = $type ?? 'album';

  factory _$AlbumItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$AlbumItemImplFromJson(json);

  @override
  final Album album;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'SearchResultItem.album(album: $album)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AlbumItemImpl &&
            (identical(other.album, album) || other.album == album));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, album);

  /// Create a copy of SearchResultItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AlbumItemImplCopyWith<_$AlbumItemImpl> get copyWith =>
      __$$AlbumItemImplCopyWithImpl<_$AlbumItemImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Song song) song,
    required TResult Function(Album album) album,
    required TResult Function(Artist artist) artist,
    required TResult Function(Playlist playlist) playlist,
  }) {
    return album(this.album);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Song song)? song,
    TResult? Function(Album album)? album,
    TResult? Function(Artist artist)? artist,
    TResult? Function(Playlist playlist)? playlist,
  }) {
    return album?.call(this.album);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Song song)? song,
    TResult Function(Album album)? album,
    TResult Function(Artist artist)? artist,
    TResult Function(Playlist playlist)? playlist,
    required TResult orElse(),
  }) {
    if (album != null) {
      return album(this.album);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_SongItem value) song,
    required TResult Function(_AlbumItem value) album,
    required TResult Function(_ArtistItem value) artist,
    required TResult Function(_PlaylistItem value) playlist,
  }) {
    return album(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_SongItem value)? song,
    TResult? Function(_AlbumItem value)? album,
    TResult? Function(_ArtistItem value)? artist,
    TResult? Function(_PlaylistItem value)? playlist,
  }) {
    return album?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_SongItem value)? song,
    TResult Function(_AlbumItem value)? album,
    TResult Function(_ArtistItem value)? artist,
    TResult Function(_PlaylistItem value)? playlist,
    required TResult orElse(),
  }) {
    if (album != null) {
      return album(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$AlbumItemImplToJson(this);
  }
}

abstract class _AlbumItem implements SearchResultItem {
  const factory _AlbumItem(final Album album) = _$AlbumItemImpl;

  factory _AlbumItem.fromJson(Map<String, dynamic> json) =
      _$AlbumItemImpl.fromJson;

  Album get album;

  /// Create a copy of SearchResultItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AlbumItemImplCopyWith<_$AlbumItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ArtistItemImplCopyWith<$Res> {
  factory _$$ArtistItemImplCopyWith(
    _$ArtistItemImpl value,
    $Res Function(_$ArtistItemImpl) then,
  ) = __$$ArtistItemImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Artist artist});

  $ArtistCopyWith<$Res> get artist;
}

/// @nodoc
class __$$ArtistItemImplCopyWithImpl<$Res>
    extends _$SearchResultItemCopyWithImpl<$Res, _$ArtistItemImpl>
    implements _$$ArtistItemImplCopyWith<$Res> {
  __$$ArtistItemImplCopyWithImpl(
    _$ArtistItemImpl _value,
    $Res Function(_$ArtistItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SearchResultItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? artist = null}) {
    return _then(
      _$ArtistItemImpl(
        null == artist
            ? _value.artist
            : artist // ignore: cast_nullable_to_non_nullable
                  as Artist,
      ),
    );
  }

  /// Create a copy of SearchResultItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ArtistCopyWith<$Res> get artist {
    return $ArtistCopyWith<$Res>(_value.artist, (value) {
      return _then(_value.copyWith(artist: value));
    });
  }
}

/// @nodoc
@JsonSerializable()
class _$ArtistItemImpl implements _ArtistItem {
  const _$ArtistItemImpl(this.artist, {final String? $type})
    : $type = $type ?? 'artist';

  factory _$ArtistItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$ArtistItemImplFromJson(json);

  @override
  final Artist artist;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'SearchResultItem.artist(artist: $artist)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ArtistItemImpl &&
            (identical(other.artist, artist) || other.artist == artist));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, artist);

  /// Create a copy of SearchResultItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ArtistItemImplCopyWith<_$ArtistItemImpl> get copyWith =>
      __$$ArtistItemImplCopyWithImpl<_$ArtistItemImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Song song) song,
    required TResult Function(Album album) album,
    required TResult Function(Artist artist) artist,
    required TResult Function(Playlist playlist) playlist,
  }) {
    return artist(this.artist);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Song song)? song,
    TResult? Function(Album album)? album,
    TResult? Function(Artist artist)? artist,
    TResult? Function(Playlist playlist)? playlist,
  }) {
    return artist?.call(this.artist);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Song song)? song,
    TResult Function(Album album)? album,
    TResult Function(Artist artist)? artist,
    TResult Function(Playlist playlist)? playlist,
    required TResult orElse(),
  }) {
    if (artist != null) {
      return artist(this.artist);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_SongItem value) song,
    required TResult Function(_AlbumItem value) album,
    required TResult Function(_ArtistItem value) artist,
    required TResult Function(_PlaylistItem value) playlist,
  }) {
    return artist(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_SongItem value)? song,
    TResult? Function(_AlbumItem value)? album,
    TResult? Function(_ArtistItem value)? artist,
    TResult? Function(_PlaylistItem value)? playlist,
  }) {
    return artist?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_SongItem value)? song,
    TResult Function(_AlbumItem value)? album,
    TResult Function(_ArtistItem value)? artist,
    TResult Function(_PlaylistItem value)? playlist,
    required TResult orElse(),
  }) {
    if (artist != null) {
      return artist(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$ArtistItemImplToJson(this);
  }
}

abstract class _ArtistItem implements SearchResultItem {
  const factory _ArtistItem(final Artist artist) = _$ArtistItemImpl;

  factory _ArtistItem.fromJson(Map<String, dynamic> json) =
      _$ArtistItemImpl.fromJson;

  Artist get artist;

  /// Create a copy of SearchResultItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ArtistItemImplCopyWith<_$ArtistItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PlaylistItemImplCopyWith<$Res> {
  factory _$$PlaylistItemImplCopyWith(
    _$PlaylistItemImpl value,
    $Res Function(_$PlaylistItemImpl) then,
  ) = __$$PlaylistItemImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Playlist playlist});

  $PlaylistCopyWith<$Res> get playlist;
}

/// @nodoc
class __$$PlaylistItemImplCopyWithImpl<$Res>
    extends _$SearchResultItemCopyWithImpl<$Res, _$PlaylistItemImpl>
    implements _$$PlaylistItemImplCopyWith<$Res> {
  __$$PlaylistItemImplCopyWithImpl(
    _$PlaylistItemImpl _value,
    $Res Function(_$PlaylistItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SearchResultItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? playlist = null}) {
    return _then(
      _$PlaylistItemImpl(
        null == playlist
            ? _value.playlist
            : playlist // ignore: cast_nullable_to_non_nullable
                  as Playlist,
      ),
    );
  }

  /// Create a copy of SearchResultItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PlaylistCopyWith<$Res> get playlist {
    return $PlaylistCopyWith<$Res>(_value.playlist, (value) {
      return _then(_value.copyWith(playlist: value));
    });
  }
}

/// @nodoc
@JsonSerializable()
class _$PlaylistItemImpl implements _PlaylistItem {
  const _$PlaylistItemImpl(this.playlist, {final String? $type})
    : $type = $type ?? 'playlist';

  factory _$PlaylistItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlaylistItemImplFromJson(json);

  @override
  final Playlist playlist;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'SearchResultItem.playlist(playlist: $playlist)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlaylistItemImpl &&
            (identical(other.playlist, playlist) ||
                other.playlist == playlist));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, playlist);

  /// Create a copy of SearchResultItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlaylistItemImplCopyWith<_$PlaylistItemImpl> get copyWith =>
      __$$PlaylistItemImplCopyWithImpl<_$PlaylistItemImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Song song) song,
    required TResult Function(Album album) album,
    required TResult Function(Artist artist) artist,
    required TResult Function(Playlist playlist) playlist,
  }) {
    return playlist(this.playlist);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Song song)? song,
    TResult? Function(Album album)? album,
    TResult? Function(Artist artist)? artist,
    TResult? Function(Playlist playlist)? playlist,
  }) {
    return playlist?.call(this.playlist);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Song song)? song,
    TResult Function(Album album)? album,
    TResult Function(Artist artist)? artist,
    TResult Function(Playlist playlist)? playlist,
    required TResult orElse(),
  }) {
    if (playlist != null) {
      return playlist(this.playlist);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_SongItem value) song,
    required TResult Function(_AlbumItem value) album,
    required TResult Function(_ArtistItem value) artist,
    required TResult Function(_PlaylistItem value) playlist,
  }) {
    return playlist(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_SongItem value)? song,
    TResult? Function(_AlbumItem value)? album,
    TResult? Function(_ArtistItem value)? artist,
    TResult? Function(_PlaylistItem value)? playlist,
  }) {
    return playlist?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_SongItem value)? song,
    TResult Function(_AlbumItem value)? album,
    TResult Function(_ArtistItem value)? artist,
    TResult Function(_PlaylistItem value)? playlist,
    required TResult orElse(),
  }) {
    if (playlist != null) {
      return playlist(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PlaylistItemImplToJson(this);
  }
}

abstract class _PlaylistItem implements SearchResultItem {
  const factory _PlaylistItem(final Playlist playlist) = _$PlaylistItemImpl;

  factory _PlaylistItem.fromJson(Map<String, dynamic> json) =
      _$PlaylistItemImpl.fromJson;

  Playlist get playlist;

  /// Create a copy of SearchResultItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlaylistItemImplCopyWith<_$PlaylistItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SearchResult _$SearchResultFromJson(Map<String, dynamic> json) {
  return _SearchResult.fromJson(json);
}

/// @nodoc
mixin _$SearchResult {
  String get query => throw _privateConstructorUsedError;
  SearchResultItem? get topResult => throw _privateConstructorUsedError;
  List<SearchResultItem> get items => throw _privateConstructorUsedError;

  /// Serializes this SearchResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SearchResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SearchResultCopyWith<SearchResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SearchResultCopyWith<$Res> {
  factory $SearchResultCopyWith(
    SearchResult value,
    $Res Function(SearchResult) then,
  ) = _$SearchResultCopyWithImpl<$Res, SearchResult>;
  @useResult
  $Res call({
    String query,
    SearchResultItem? topResult,
    List<SearchResultItem> items,
  });

  $SearchResultItemCopyWith<$Res>? get topResult;
}

/// @nodoc
class _$SearchResultCopyWithImpl<$Res, $Val extends SearchResult>
    implements $SearchResultCopyWith<$Res> {
  _$SearchResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SearchResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? query = null,
    Object? topResult = freezed,
    Object? items = null,
  }) {
    return _then(
      _value.copyWith(
            query: null == query
                ? _value.query
                : query // ignore: cast_nullable_to_non_nullable
                      as String,
            topResult: freezed == topResult
                ? _value.topResult
                : topResult // ignore: cast_nullable_to_non_nullable
                      as SearchResultItem?,
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<SearchResultItem>,
          )
          as $Val,
    );
  }

  /// Create a copy of SearchResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SearchResultItemCopyWith<$Res>? get topResult {
    if (_value.topResult == null) {
      return null;
    }

    return $SearchResultItemCopyWith<$Res>(_value.topResult!, (value) {
      return _then(_value.copyWith(topResult: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SearchResultImplCopyWith<$Res>
    implements $SearchResultCopyWith<$Res> {
  factory _$$SearchResultImplCopyWith(
    _$SearchResultImpl value,
    $Res Function(_$SearchResultImpl) then,
  ) = __$$SearchResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String query,
    SearchResultItem? topResult,
    List<SearchResultItem> items,
  });

  @override
  $SearchResultItemCopyWith<$Res>? get topResult;
}

/// @nodoc
class __$$SearchResultImplCopyWithImpl<$Res>
    extends _$SearchResultCopyWithImpl<$Res, _$SearchResultImpl>
    implements _$$SearchResultImplCopyWith<$Res> {
  __$$SearchResultImplCopyWithImpl(
    _$SearchResultImpl _value,
    $Res Function(_$SearchResultImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SearchResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? query = null,
    Object? topResult = freezed,
    Object? items = null,
  }) {
    return _then(
      _$SearchResultImpl(
        query: null == query
            ? _value.query
            : query // ignore: cast_nullable_to_non_nullable
                  as String,
        topResult: freezed == topResult
            ? _value.topResult
            : topResult // ignore: cast_nullable_to_non_nullable
                  as SearchResultItem?,
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<SearchResultItem>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SearchResultImpl implements _SearchResult {
  const _$SearchResultImpl({
    required this.query,
    this.topResult,
    final List<SearchResultItem> items = const [],
  }) : _items = items;

  factory _$SearchResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$SearchResultImplFromJson(json);

  @override
  final String query;
  @override
  final SearchResultItem? topResult;
  final List<SearchResultItem> _items;
  @override
  @JsonKey()
  List<SearchResultItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'SearchResult(query: $query, topResult: $topResult, items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SearchResultImpl &&
            (identical(other.query, query) || other.query == query) &&
            (identical(other.topResult, topResult) ||
                other.topResult == topResult) &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    query,
    topResult,
    const DeepCollectionEquality().hash(_items),
  );

  /// Create a copy of SearchResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SearchResultImplCopyWith<_$SearchResultImpl> get copyWith =>
      __$$SearchResultImplCopyWithImpl<_$SearchResultImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SearchResultImplToJson(this);
  }
}

abstract class _SearchResult implements SearchResult {
  const factory _SearchResult({
    required final String query,
    final SearchResultItem? topResult,
    final List<SearchResultItem> items,
  }) = _$SearchResultImpl;

  factory _SearchResult.fromJson(Map<String, dynamic> json) =
      _$SearchResultImpl.fromJson;

  @override
  String get query;
  @override
  SearchResultItem? get topResult;
  @override
  List<SearchResultItem> get items;

  /// Create a copy of SearchResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SearchResultImplCopyWith<_$SearchResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

HomeFeedSection _$HomeFeedSectionFromJson(Map<String, dynamic> json) {
  return _HomeFeedSection.fromJson(json);
}

/// @nodoc
mixin _$HomeFeedSection {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  List<SearchResultItem> get items => throw _privateConstructorUsedError;

  /// Serializes this HomeFeedSection to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HomeFeedSection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HomeFeedSectionCopyWith<HomeFeedSection> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HomeFeedSectionCopyWith<$Res> {
  factory $HomeFeedSectionCopyWith(
    HomeFeedSection value,
    $Res Function(HomeFeedSection) then,
  ) = _$HomeFeedSectionCopyWithImpl<$Res, HomeFeedSection>;
  @useResult
  $Res call({String id, String title, List<SearchResultItem> items});
}

/// @nodoc
class _$HomeFeedSectionCopyWithImpl<$Res, $Val extends HomeFeedSection>
    implements $HomeFeedSectionCopyWith<$Res> {
  _$HomeFeedSectionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HomeFeedSection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? title = null, Object? items = null}) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<SearchResultItem>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$HomeFeedSectionImplCopyWith<$Res>
    implements $HomeFeedSectionCopyWith<$Res> {
  factory _$$HomeFeedSectionImplCopyWith(
    _$HomeFeedSectionImpl value,
    $Res Function(_$HomeFeedSectionImpl) then,
  ) = __$$HomeFeedSectionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String title, List<SearchResultItem> items});
}

/// @nodoc
class __$$HomeFeedSectionImplCopyWithImpl<$Res>
    extends _$HomeFeedSectionCopyWithImpl<$Res, _$HomeFeedSectionImpl>
    implements _$$HomeFeedSectionImplCopyWith<$Res> {
  __$$HomeFeedSectionImplCopyWithImpl(
    _$HomeFeedSectionImpl _value,
    $Res Function(_$HomeFeedSectionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of HomeFeedSection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? title = null, Object? items = null}) {
    return _then(
      _$HomeFeedSectionImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<SearchResultItem>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$HomeFeedSectionImpl implements _HomeFeedSection {
  const _$HomeFeedSectionImpl({
    required this.id,
    required this.title,
    final List<SearchResultItem> items = const [],
  }) : _items = items;

  factory _$HomeFeedSectionImpl.fromJson(Map<String, dynamic> json) =>
      _$$HomeFeedSectionImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  final List<SearchResultItem> _items;
  @override
  @JsonKey()
  List<SearchResultItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'HomeFeedSection(id: $id, title: $title, items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HomeFeedSectionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    const DeepCollectionEquality().hash(_items),
  );

  /// Create a copy of HomeFeedSection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HomeFeedSectionImplCopyWith<_$HomeFeedSectionImpl> get copyWith =>
      __$$HomeFeedSectionImplCopyWithImpl<_$HomeFeedSectionImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$HomeFeedSectionImplToJson(this);
  }
}

abstract class _HomeFeedSection implements HomeFeedSection {
  const factory _HomeFeedSection({
    required final String id,
    required final String title,
    final List<SearchResultItem> items,
  }) = _$HomeFeedSectionImpl;

  factory _HomeFeedSection.fromJson(Map<String, dynamic> json) =
      _$HomeFeedSectionImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  List<SearchResultItem> get items;

  /// Create a copy of HomeFeedSection
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HomeFeedSectionImplCopyWith<_$HomeFeedSectionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

HomeFeed _$HomeFeedFromJson(Map<String, dynamic> json) {
  return _HomeFeed.fromJson(json);
}

/// @nodoc
mixin _$HomeFeed {
  List<HomeFeedSection> get sections => throw _privateConstructorUsedError;

  /// Serializes this HomeFeed to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HomeFeed
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HomeFeedCopyWith<HomeFeed> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HomeFeedCopyWith<$Res> {
  factory $HomeFeedCopyWith(HomeFeed value, $Res Function(HomeFeed) then) =
      _$HomeFeedCopyWithImpl<$Res, HomeFeed>;
  @useResult
  $Res call({List<HomeFeedSection> sections});
}

/// @nodoc
class _$HomeFeedCopyWithImpl<$Res, $Val extends HomeFeed>
    implements $HomeFeedCopyWith<$Res> {
  _$HomeFeedCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HomeFeed
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? sections = null}) {
    return _then(
      _value.copyWith(
            sections: null == sections
                ? _value.sections
                : sections // ignore: cast_nullable_to_non_nullable
                      as List<HomeFeedSection>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$HomeFeedImplCopyWith<$Res>
    implements $HomeFeedCopyWith<$Res> {
  factory _$$HomeFeedImplCopyWith(
    _$HomeFeedImpl value,
    $Res Function(_$HomeFeedImpl) then,
  ) = __$$HomeFeedImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<HomeFeedSection> sections});
}

/// @nodoc
class __$$HomeFeedImplCopyWithImpl<$Res>
    extends _$HomeFeedCopyWithImpl<$Res, _$HomeFeedImpl>
    implements _$$HomeFeedImplCopyWith<$Res> {
  __$$HomeFeedImplCopyWithImpl(
    _$HomeFeedImpl _value,
    $Res Function(_$HomeFeedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of HomeFeed
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? sections = null}) {
    return _then(
      _$HomeFeedImpl(
        sections: null == sections
            ? _value._sections
            : sections // ignore: cast_nullable_to_non_nullable
                  as List<HomeFeedSection>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$HomeFeedImpl implements _HomeFeed {
  const _$HomeFeedImpl({final List<HomeFeedSection> sections = const []})
    : _sections = sections;

  factory _$HomeFeedImpl.fromJson(Map<String, dynamic> json) =>
      _$$HomeFeedImplFromJson(json);

  final List<HomeFeedSection> _sections;
  @override
  @JsonKey()
  List<HomeFeedSection> get sections {
    if (_sections is EqualUnmodifiableListView) return _sections;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sections);
  }

  @override
  String toString() {
    return 'HomeFeed(sections: $sections)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HomeFeedImpl &&
            const DeepCollectionEquality().equals(other._sections, _sections));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_sections));

  /// Create a copy of HomeFeed
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HomeFeedImplCopyWith<_$HomeFeedImpl> get copyWith =>
      __$$HomeFeedImplCopyWithImpl<_$HomeFeedImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HomeFeedImplToJson(this);
  }
}

abstract class _HomeFeed implements HomeFeed {
  const factory _HomeFeed({final List<HomeFeedSection> sections}) =
      _$HomeFeedImpl;

  factory _HomeFeed.fromJson(Map<String, dynamic> json) =
      _$HomeFeedImpl.fromJson;

  @override
  List<HomeFeedSection> get sections;

  /// Create a copy of HomeFeed
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HomeFeedImplCopyWith<_$HomeFeedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AudioStream _$AudioStreamFromJson(Map<String, dynamic> json) {
  return _AudioStream.fromJson(json);
}

/// @nodoc
mixin _$AudioStream {
  String get id => throw _privateConstructorUsedError;
  String get streamUrl => throw _privateConstructorUsedError;
  String get format => throw _privateConstructorUsedError;
  int get bitrate => throw _privateConstructorUsedError;
  Duration get expiration => throw _privateConstructorUsedError;

  /// Serializes this AudioStream to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AudioStream
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AudioStreamCopyWith<AudioStream> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AudioStreamCopyWith<$Res> {
  factory $AudioStreamCopyWith(
    AudioStream value,
    $Res Function(AudioStream) then,
  ) = _$AudioStreamCopyWithImpl<$Res, AudioStream>;
  @useResult
  $Res call({
    String id,
    String streamUrl,
    String format,
    int bitrate,
    Duration expiration,
  });
}

/// @nodoc
class _$AudioStreamCopyWithImpl<$Res, $Val extends AudioStream>
    implements $AudioStreamCopyWith<$Res> {
  _$AudioStreamCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AudioStream
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? streamUrl = null,
    Object? format = null,
    Object? bitrate = null,
    Object? expiration = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            streamUrl: null == streamUrl
                ? _value.streamUrl
                : streamUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            format: null == format
                ? _value.format
                : format // ignore: cast_nullable_to_non_nullable
                      as String,
            bitrate: null == bitrate
                ? _value.bitrate
                : bitrate // ignore: cast_nullable_to_non_nullable
                      as int,
            expiration: null == expiration
                ? _value.expiration
                : expiration // ignore: cast_nullable_to_non_nullable
                      as Duration,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AudioStreamImplCopyWith<$Res>
    implements $AudioStreamCopyWith<$Res> {
  factory _$$AudioStreamImplCopyWith(
    _$AudioStreamImpl value,
    $Res Function(_$AudioStreamImpl) then,
  ) = __$$AudioStreamImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String streamUrl,
    String format,
    int bitrate,
    Duration expiration,
  });
}

/// @nodoc
class __$$AudioStreamImplCopyWithImpl<$Res>
    extends _$AudioStreamCopyWithImpl<$Res, _$AudioStreamImpl>
    implements _$$AudioStreamImplCopyWith<$Res> {
  __$$AudioStreamImplCopyWithImpl(
    _$AudioStreamImpl _value,
    $Res Function(_$AudioStreamImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AudioStream
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? streamUrl = null,
    Object? format = null,
    Object? bitrate = null,
    Object? expiration = null,
  }) {
    return _then(
      _$AudioStreamImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        streamUrl: null == streamUrl
            ? _value.streamUrl
            : streamUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        format: null == format
            ? _value.format
            : format // ignore: cast_nullable_to_non_nullable
                  as String,
        bitrate: null == bitrate
            ? _value.bitrate
            : bitrate // ignore: cast_nullable_to_non_nullable
                  as int,
        expiration: null == expiration
            ? _value.expiration
            : expiration // ignore: cast_nullable_to_non_nullable
                  as Duration,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AudioStreamImpl implements _AudioStream {
  const _$AudioStreamImpl({
    required this.id,
    required this.streamUrl,
    required this.format,
    required this.bitrate,
    required this.expiration,
  });

  factory _$AudioStreamImpl.fromJson(Map<String, dynamic> json) =>
      _$$AudioStreamImplFromJson(json);

  @override
  final String id;
  @override
  final String streamUrl;
  @override
  final String format;
  @override
  final int bitrate;
  @override
  final Duration expiration;

  @override
  String toString() {
    return 'AudioStream(id: $id, streamUrl: $streamUrl, format: $format, bitrate: $bitrate, expiration: $expiration)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AudioStreamImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.streamUrl, streamUrl) ||
                other.streamUrl == streamUrl) &&
            (identical(other.format, format) || other.format == format) &&
            (identical(other.bitrate, bitrate) || other.bitrate == bitrate) &&
            (identical(other.expiration, expiration) ||
                other.expiration == expiration));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, streamUrl, format, bitrate, expiration);

  /// Create a copy of AudioStream
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AudioStreamImplCopyWith<_$AudioStreamImpl> get copyWith =>
      __$$AudioStreamImplCopyWithImpl<_$AudioStreamImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AudioStreamImplToJson(this);
  }
}

abstract class _AudioStream implements AudioStream {
  const factory _AudioStream({
    required final String id,
    required final String streamUrl,
    required final String format,
    required final int bitrate,
    required final Duration expiration,
  }) = _$AudioStreamImpl;

  factory _AudioStream.fromJson(Map<String, dynamic> json) =
      _$AudioStreamImpl.fromJson;

  @override
  String get id;
  @override
  String get streamUrl;
  @override
  String get format;
  @override
  int get bitrate;
  @override
  Duration get expiration;

  /// Create a copy of AudioStream
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AudioStreamImplCopyWith<_$AudioStreamImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Lyrics _$LyricsFromJson(Map<String, dynamic> json) {
  return _Lyrics.fromJson(json);
}

/// @nodoc
mixin _$Lyrics {
  String get text => throw _privateConstructorUsedError;
  bool get isTimed => throw _privateConstructorUsedError;

  /// Serializes this Lyrics to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Lyrics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LyricsCopyWith<Lyrics> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LyricsCopyWith<$Res> {
  factory $LyricsCopyWith(Lyrics value, $Res Function(Lyrics) then) =
      _$LyricsCopyWithImpl<$Res, Lyrics>;
  @useResult
  $Res call({String text, bool isTimed});
}

/// @nodoc
class _$LyricsCopyWithImpl<$Res, $Val extends Lyrics>
    implements $LyricsCopyWith<$Res> {
  _$LyricsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Lyrics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? text = null, Object? isTimed = null}) {
    return _then(
      _value.copyWith(
            text: null == text
                ? _value.text
                : text // ignore: cast_nullable_to_non_nullable
                      as String,
            isTimed: null == isTimed
                ? _value.isTimed
                : isTimed // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LyricsImplCopyWith<$Res> implements $LyricsCopyWith<$Res> {
  factory _$$LyricsImplCopyWith(
    _$LyricsImpl value,
    $Res Function(_$LyricsImpl) then,
  ) = __$$LyricsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String text, bool isTimed});
}

/// @nodoc
class __$$LyricsImplCopyWithImpl<$Res>
    extends _$LyricsCopyWithImpl<$Res, _$LyricsImpl>
    implements _$$LyricsImplCopyWith<$Res> {
  __$$LyricsImplCopyWithImpl(
    _$LyricsImpl _value,
    $Res Function(_$LyricsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Lyrics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? text = null, Object? isTimed = null}) {
    return _then(
      _$LyricsImpl(
        text: null == text
            ? _value.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
        isTimed: null == isTimed
            ? _value.isTimed
            : isTimed // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LyricsImpl implements _Lyrics {
  const _$LyricsImpl({required this.text, this.isTimed = false});

  factory _$LyricsImpl.fromJson(Map<String, dynamic> json) =>
      _$$LyricsImplFromJson(json);

  @override
  final String text;
  @override
  @JsonKey()
  final bool isTimed;

  @override
  String toString() {
    return 'Lyrics(text: $text, isTimed: $isTimed)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LyricsImpl &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.isTimed, isTimed) || other.isTimed == isTimed));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, text, isTimed);

  /// Create a copy of Lyrics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LyricsImplCopyWith<_$LyricsImpl> get copyWith =>
      __$$LyricsImplCopyWithImpl<_$LyricsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LyricsImplToJson(this);
  }
}

abstract class _Lyrics implements Lyrics {
  const factory _Lyrics({required final String text, final bool isTimed}) =
      _$LyricsImpl;

  factory _Lyrics.fromJson(Map<String, dynamic> json) = _$LyricsImpl.fromJson;

  @override
  String get text;
  @override
  bool get isTimed;

  /// Create a copy of Lyrics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LyricsImplCopyWith<_$LyricsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
