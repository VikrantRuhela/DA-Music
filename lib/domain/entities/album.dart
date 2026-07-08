import 'value_objects.dart';

/// Immutable domain entity representing a collection of songs under an album.
class Album {
  final String id;
  final String title;
  final String artistId;
  final Artwork cover;
  final int year;
  final int trackCount;
  final DurationValue duration;

  Album({
    required this.id,
    required this.title,
    required this.artistId,
    required this.cover,
    required this.year,
    required this.trackCount,
    required this.duration,
  }) {
    if (id.isEmpty) throw ArgumentError('Album ID reference cannot be empty.');
    if (title.isEmpty) throw ArgumentError('Album title label cannot be empty.');
    if (artistId.isEmpty) throw ArgumentError('Album artist reference ID cannot be empty.');
    if (year <= 1800 || year >= 2100) throw ArgumentError('Album release year is invalid.');
    if (trackCount < 0) throw ArgumentError('Album track count cannot be negative.');
  }

  Album copyWith({
    String? id,
    String? title,
    String? artistId,
    Artwork? cover,
    int? year,
    int? trackCount,
    DurationValue? duration,
  }) {
    return Album(
      id: id ?? this.id,
      title: title ?? this.title,
      artistId: artistId ?? this.artistId,
      cover: cover ?? this.cover,
      year: year ?? this.year,
      trackCount: trackCount ?? this.trackCount,
      duration: duration ?? this.duration,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Album &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          artistId == other.artistId &&
          cover == other.cover &&
          year == other.year &&
          trackCount == other.trackCount &&
          duration == other.duration;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      artistId.hashCode ^
      cover.hashCode ^
      year.hashCode ^
      trackCount.hashCode ^
      duration.hashCode;

  @override
  String toString() {
    return 'Album{id: $id, title: $title, artistId: $artistId, year: $year, trackCount: $trackCount, duration: $duration}';
  }
}
