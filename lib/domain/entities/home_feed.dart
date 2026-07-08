/// Immutable domain entity representing a single section on the home page.
class HomeFeedSection {
  final String title;
  final String type; // e.g. "trending", "recently_played", "recommended"
  final List<dynamic> items; // Can hold Songs, Albums, Artists, or Playlists

  HomeFeedSection({
    required this.title,
    required this.type,
    required this.items,
  }) {
    if (title.isEmpty) throw ArgumentError('HomeFeedSection title cannot be empty.');
    if (type.isEmpty) throw ArgumentError('HomeFeedSection type tag cannot be empty.');
  }

  HomeFeedSection copyWith({
    String? title,
    String? type,
    List<dynamic>? items,
  }) {
    return HomeFeedSection(
      title: title ?? this.title,
      type: type ?? this.type,
      items: items ?? this.items,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeFeedSection &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          type == other.type &&
          _listEquals(items, other.items);

  @override
  int get hashCode =>
      title.hashCode ^
      type.hashCode ^
      items.fold(0, (prev, element) => prev ^ element.hashCode);

  bool _listEquals(List<dynamic> a, List<dynamic> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'HomeFeedSection{title: $title, type: $type, itemsCount: ${items.length}}';
  }
}

/// Immutable domain entity representing the home feed grid content.
class HomeFeed {
  final List<HomeFeedSection> sections;

  HomeFeed({required this.sections}) {
    if (sections.isEmpty) throw ArgumentError('HomeFeed sections list cannot be empty.');
  }

  HomeFeed copyWith({List<HomeFeedSection>? sections}) {
    return HomeFeed(sections: sections ?? this.sections);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeFeed &&
          runtimeType == other.runtimeType &&
          _listEquals(sections, other.sections);

  @override
  int get hashCode => sections.fold(0, (prev, element) => prev ^ element.hashCode);

  bool _listEquals(List<dynamic> a, List<dynamic> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() => 'HomeFeed{sectionsCount: ${sections.length}}';
}
