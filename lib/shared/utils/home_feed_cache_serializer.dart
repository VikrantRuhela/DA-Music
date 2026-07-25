// SPDX-License-Identifier: GPL-3.0-only
// Copyright (c) 2026 DA Music Contributors
// Licensed under GPL-3.0.

import 'dart:convert';
import '../../../domain/entities/home_feed.dart';
import '../../../domain/entities/song.dart';
import '../../../domain/entities/album.dart';
import '../../../domain/entities/playlist.dart';
import '../../../domain/entities/value_objects.dart';

class HomeFeedCacheSerializer {
  static String serialize(HomeFeed feed) {
    final List<Map<String, dynamic>> sectionsList = [];
    for (final section in feed.sections) {
      final List<Map<String, dynamic>> itemsList = [];
      for (final item in section.items) {
        if (item is Song) {
          itemsList.add({
            '__type': 'song',
            'id': item.id,
            'title': item.title,
            'artistId': item.artistId,
            'albumId': item.albumId,
            'durationMs': item.duration.value.inMilliseconds,
            'thumbnailUrl': item.thumbnail.url,
            'artworkUrl': item.artwork.url,
            'sourceId': item.sourceId,
          });
        } else if (item is Album) {
          itemsList.add({
            '__type': 'album',
            'id': item.id,
            'title': item.title,
            'artistId': item.artistId,
            'coverUrl': item.cover.url,
            'year': item.year,
            'trackCount': item.trackCount,
            'durationMs': item.duration.value.inMilliseconds,
          });
        } else if (item is Playlist) {
          itemsList.add({
            '__type': 'playlist',
            'id': item.id,
            'title': item.title,
            'description': item.description,
            'coverUrl': item.cover.url,
            'owner': item.owner,
            'songIds': item.songIds,
            'createdAt': item.createdAt.toIso8601String(),
            'updatedAt': item.updatedAt.toIso8601String(),
          });
        }
      }
      sectionsList.add({
        'title': section.title,
        'type': section.type,
        'items': itemsList,
      });
    }
    return jsonEncode(sectionsList);
  }

  static HomeFeed deserialize(String jsonStr) {
    try {
      final List<dynamic> sectionsList = jsonDecode(jsonStr);
      final List<HomeFeedSection> sections = [];
      for (final secMap in sectionsList) {
        if (secMap is Map) {
          final String title = secMap['title'] as String? ?? 'Untitled Section';
          final String type = secMap['type'] as String? ?? 'generic';
          final List<dynamic> itemsList = secMap['items'] as List? ?? [];
          final List<dynamic> items = [];

          for (final itemMap in itemsList) {
            if (itemMap is Map) {
              final typeKey = itemMap['__type'] as String?;
              if (typeKey == 'song') {
                items.add(Song(
                  id: itemMap['id'] as String? ?? '',
                  title: itemMap['title'] as String? ?? '',
                  artistId: itemMap['artistId'] as String? ?? '',
                  albumId: itemMap['albumId'] as String? ?? '',
                  duration: DurationValue(Duration(milliseconds: itemMap['durationMs'] as int? ?? 0)),
                  thumbnail: Artwork(itemMap['thumbnailUrl'] as String?),
                  artwork: Artwork(itemMap['artworkUrl'] as String?),
                  sourceId: itemMap['sourceId'] as String? ?? '',
                ));
              } else if (typeKey == 'album') {
                items.add(Album(
                  id: itemMap['id'] as String? ?? '',
                  title: itemMap['title'] as String? ?? '',
                  artistId: itemMap['artistId'] as String? ?? '',
                  cover: Artwork(itemMap['coverUrl'] as String?),
                  year: itemMap['year'] as int? ?? 2026,
                  trackCount: itemMap['trackCount'] as int? ?? 0,
                  duration: DurationValue(Duration(milliseconds: itemMap['durationMs'] as int? ?? 0)),
                ));
              } else if (typeKey == 'playlist') {
                items.add(Playlist(
                  id: itemMap['id'] as String? ?? '',
                  title: itemMap['title'] as String? ?? '',
                  description: itemMap['description'] as String? ?? '',
                  cover: Artwork(itemMap['coverUrl'] as String?),
                  owner: itemMap['owner'] as String? ?? '',
                  songIds: List<String>.from(itemMap['songIds'] ?? []),
                  createdAt: DateTime.tryParse(itemMap['createdAt'] as String? ?? '') ?? DateTime.now(),
                  updatedAt: DateTime.tryParse(itemMap['updatedAt'] as String? ?? '') ?? DateTime.now(),
                ));
              }
            }
          }
          sections.add(HomeFeedSection(
            title: title,
            type: type,
            items: items,
          ));
        }
      }
      return HomeFeed(sections: sections);
    } catch (_) {
      return HomeFeed(sections: []);
    }
  }
}
