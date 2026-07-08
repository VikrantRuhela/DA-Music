import 'value_objects.dart';

/// Immutable domain entity representing a user-curated playlist of tracks.
class Playlist {
  final String id;
  final String title;
  final String description;
  final Artwork cover;
  final String owner;
  final List<String> songIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  Playlist({
    required this.id,
    required this.title,
    required this.description,
    required this.cover,
    required this.owner,
    required this.songIds,
    required this.createdAt,
    required this.updatedAt,
  }) {
    if (id.isEmpty) throw ArgumentError('Playlist ID reference cannot be empty.');
    if (title.isEmpty) throw ArgumentError('Playlist title label cannot be empty.');
    if (owner.isEmpty) throw ArgumentError('Playlist owner reference ID cannot be empty.');
  }

  Playlist copyWith({
    String? id,
    String? title,
    String? description,
    Artwork? cover,
    String? owner,
    List<String>? songIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Playlist(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      cover: cover ?? this.cover,
      owner: owner ?? this.owner,
      songIds: songIds ?? this.songIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Playlist &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          cover == other.cover &&
          owner == other.owner &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          _listEquals(songIds, other.songIds);

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      description.hashCode ^
      cover.hashCode ^
      owner.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      songIds.fold(0, (prev, element) => prev ^ element.hashCode);

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'Playlist{id: $id, title: $title, owner: $owner, songCount: ${songIds.length}}';
  }
}
