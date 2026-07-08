import 'value_objects.dart';

/// Immutable domain entity representing a music artist/creator.
class Artist {
  final String id;
  final String name;
  final Artwork image;
  final int subscriberCount;
  final String description;
  final List<String> genres;

  Artist({
    required this.id,
    required this.name,
    required this.image,
    required this.subscriberCount,
    required this.description,
    required this.genres,
  }) {
    if (id.isEmpty) throw ArgumentError('Artist ID reference cannot be empty.');
    if (name.isEmpty) throw ArgumentError('Artist name label cannot be empty.');
    if (subscriberCount < 0) throw ArgumentError('Artist subscriber count cannot be negative.');
  }

  Artist copyWith({
    String? id,
    String? name,
    Artwork? image,
    int? subscriberCount,
    String? description,
    List<String>? genres,
  }) {
    return Artist(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      subscriberCount: subscriberCount ?? this.subscriberCount,
      description: description ?? this.description,
      genres: genres ?? this.genres,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Artist &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          image == other.image &&
          subscriberCount == other.subscriberCount &&
          description == other.description &&
          _listEquals(genres, other.genres);

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      image.hashCode ^
      subscriberCount.hashCode ^
      description.hashCode ^
      genres.fold(0, (prev, element) => prev ^ element.hashCode);

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'Artist{id: $id, name: $name, subscriberCount: $subscriberCount, genres: $genres}';
  }
}
