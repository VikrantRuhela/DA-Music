import 'package:freezed_annotation/freezed_annotation.dart';
import 'music_models.dart';

part 'source_models.freezed.dart';
part 'source_models.g.dart';

@freezed
class SearchResultItem with _$SearchResultItem {
  const factory SearchResultItem.song(Song song) = _SongItem;
  const factory SearchResultItem.album(Album album) = _AlbumItem;
  const factory SearchResultItem.artist(Artist artist) = _ArtistItem;
  const factory SearchResultItem.playlist(Playlist playlist) = _PlaylistItem;

  factory SearchResultItem.fromJson(Map<String, dynamic> json) => _$SearchResultItemFromJson(json);
}

@freezed
class SearchResult with _$SearchResult {
  const factory SearchResult({
    required String query,
    SearchResultItem? topResult,
    @Default([]) List<SearchResultItem> items,
  }) = _SearchResult;

  factory SearchResult.fromJson(Map<String, dynamic> json) => _$SearchResultFromJson(json);
}

@freezed
class HomeFeedSection with _$HomeFeedSection {
  const factory HomeFeedSection({
    required String id,
    required String title,
    @Default([]) List<SearchResultItem> items,
  }) = _HomeFeedSection;

  factory HomeFeedSection.fromJson(Map<String, dynamic> json) => _$HomeFeedSectionFromJson(json);
}

@freezed
class HomeFeed with _$HomeFeed {
  const factory HomeFeed({
    @Default([]) List<HomeFeedSection> sections,
  }) = _HomeFeed;

  factory HomeFeed.fromJson(Map<String, dynamic> json) => _$HomeFeedFromJson(json);
}

@freezed
class AudioStream with _$AudioStream {
  const factory AudioStream({
    required String id,
    required String streamUrl,
    required String format,
    required int bitrate,
    required Duration expiration,
  }) = _AudioStream;

  factory AudioStream.fromJson(Map<String, dynamic> json) => _$AudioStreamFromJson(json);
}

@freezed
class Lyrics with _$Lyrics {
  const factory Lyrics({
    required String text,
    @Default(false) bool isTimed,
  }) = _Lyrics;

  factory Lyrics.fromJson(Map<String, dynamic> json) => _$LyricsFromJson(json);
}
