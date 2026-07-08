import 'value_objects.dart';

/// Immutable domain entity representing a single music track.
class Song {
  final String id;
  final String title;
  final String artistId;
  final String albumId;
  final DurationValue duration;
  final Artwork thumbnail;
  final Artwork artwork;
  final String? streamUrl;
  final String? lyricsId;
  final bool isLiked;
  final bool isDownloaded;
  final String sourceId;

  Song({
    required this.id,
    required this.title,
    required this.artistId,
    required this.albumId,
    required this.duration,
    required this.thumbnail,
    required this.artwork,
    this.streamUrl,
    this.lyricsId,
    this.isLiked = false,
    this.isDownloaded = false,
    required this.sourceId,
  }) {
    if (id.isEmpty) throw ArgumentError('Song ID reference cannot be empty.');
    if (title.isEmpty) throw ArgumentError('Song title label cannot be empty.');
    if (artistId.isEmpty) throw ArgumentError('Song artist reference ID cannot be empty.');
    if (albumId.isEmpty) throw ArgumentError('Song album reference ID cannot be empty.');
    if (sourceId.isEmpty) throw ArgumentError('Song adapter source registry reference cannot be empty.');
  }

  Song copyWith({
    String? id,
    String? title,
    String? artistId,
    String? albumId,
    DurationValue? duration,
    Artwork? thumbnail,
    Artwork? artwork,
    String? streamUrl,
    String? lyricsId,
    bool? isLiked,
    bool? isDownloaded,
    String? sourceId,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artistId: artistId ?? this.artistId,
      albumId: albumId ?? this.albumId,
      duration: duration ?? this.duration,
      thumbnail: thumbnail ?? this.thumbnail,
      artwork: artwork ?? this.artwork,
      streamUrl: streamUrl ?? this.streamUrl,
      lyricsId: lyricsId ?? this.lyricsId,
      isLiked: isLiked ?? this.isLiked,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      sourceId: sourceId ?? this.sourceId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Song &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          artistId == other.artistId &&
          albumId == other.albumId &&
          duration == other.duration &&
          thumbnail == other.thumbnail &&
          artwork == other.artwork &&
          streamUrl == other.streamUrl &&
          lyricsId == other.lyricsId &&
          isLiked == other.isLiked &&
          isDownloaded == other.isDownloaded &&
          sourceId == other.sourceId;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      artistId.hashCode ^
      albumId.hashCode ^
      duration.hashCode ^
      thumbnail.hashCode ^
      artwork.hashCode ^
      streamUrl.hashCode ^
      lyricsId.hashCode ^
      isLiked.hashCode ^
      isDownloaded.hashCode ^
      sourceId.hashCode;

  @override
  String toString() {
    return 'Song{id: $id, title: $title, artistId: $artistId, albumId: $albumId, duration: $duration, isLiked: $isLiked, isDownloaded: $isDownloaded, sourceId: $sourceId}';
  }
}
