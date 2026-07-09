import 'dart:io';

/// Value object wrapper representing checked duration lengths.
class DurationValue {
  final Duration value;

  DurationValue(this.value) {
    if (value.isNegative) {
      throw ArgumentError('DurationValue cannot represent a negative time segment.');
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DurationValue && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value.toString();
}

/// Value object wrapper representing validated web URLs for artwork images.
class Artwork {
  final String url;

  static const String defaultArtwork = 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819';

  Artwork(String? url) : url = _validateAndNormalize(url);

  static String _validateAndNormalize(String? rawUrl) {
    if (rawUrl == null) return defaultArtwork;
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return defaultArtwork;

    // Check if it is a local file path that exists, or looks like a local file path
    // (e.g. starts with '/' or has a Windows drive prefix like 'C:\' or 'c:\')
    final file = File(trimmed);
    if (file.existsSync() ||
        trimmed.startsWith('/') ||
        trimmed.startsWith(r'\') ||
        (trimmed.length > 2 && trimmed[1] == ':' && (trimmed[2] == '/' || trimmed[2] == r'\'))) {
      return trimmed;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return defaultArtwork;

    final scheme = uri.scheme.toLowerCase();
    if (scheme == 'file') {
      return trimmed;
    }
    if ((scheme == 'http' || scheme == 'https') && uri.hasAuthority) {
      return trimmed;
    }

    return defaultArtwork;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Artwork && url == other.url;

  @override
  int get hashCode => url.hashCode;

  @override
  String toString() => url;
}

/// Value object wrapper representing pluggable adapter metadata.
class Source {
  final String id;
  final String name;

  Source({required this.id, required this.name}) {
    if (id.isEmpty) {
      throw ArgumentError('Source ID reference cannot be empty.');
    }
    if (name.isEmpty) {
      throw ArgumentError('Source display name cannot be empty.');
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Source && id == other.id && name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;

  @override
  String toString() => '$name ($id)';
}

/// Value object wrapper representing hex color styles.
class ThemeColor {
  final String hex;

  ThemeColor(this.hex) {
    if (hex.isEmpty) {
      throw ArgumentError('ThemeColor hex value cannot be empty.');
    }
    if (hex.length != 4 && hex.length != 7) {
      throw ArgumentError(
        'Invalid ThemeColor hex format. Must represent 3 or 6 digit hex symbols.',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ThemeColor && hex == other.hex;

  @override
  int get hashCode => hex.hashCode;

  @override
  String toString() => hex;
}
