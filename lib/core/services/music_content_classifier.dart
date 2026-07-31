// SPDX-License-Identifier: GPL-3.0-only

import '../../domain/entities/song.dart';

class MusicContentClassifier {
  static const Set<String> _blacklistKeywords = {
    'gameplay',
    'walkthrough',
    'podcast',
    'reaction',
    'review',
    'unboxing',
    'tutorial',
    'asmr',
    'vlog',
    'playthrough',
    'guide',
    'funny moments',
    'spotify hits',
    'top spotify',
    'spotify',
    'trending hits',
    'pop hits',
  };

  static bool isBlacklistedTitleOrChannel(String title, String channel) {
    final lowerTitle = title.toLowerCase();
    final lowerChannel = channel.toLowerCase();

    for (final kw in _blacklistKeywords) {
      if (lowerTitle.contains(kw) || lowerChannel.contains(kw)) {
        return true;
      }
    }
    return false;
  }

  static int calculateConfidenceScore({
    required String title,
    required String artist,
    required Duration duration,
    bool isTopicChannel = false,
    bool isOfficialArtistChannel = false,
    bool hasMusicPageType = false,
    bool fromMusicShelf = false,
  }) {
    int score = 50;

    if (fromMusicShelf) score += 30;
    if (hasMusicPageType) score += 20;
    if (isTopicChannel || isOfficialArtistChannel) score += 20;

    final seconds = duration.inSeconds;
    if (seconds >= 90 && seconds <= 420) {
      score += 10;
    } else if (seconds < 45 || seconds > 900) {
      score -= 40;
    }

    if (isBlacklistedTitleOrChannel(title, artist)) {
      score -= 50;
    }

    return score.clamp(0, 100);
  }

  static bool isMusicSong(Song song) {
    if (isBlacklistedTitleOrChannel(song.title, song.artistId)) {
      return false;
    }
    final secs = song.duration.value.inSeconds;
    if (secs > 0 && (secs < 30 || secs > 1200)) {
      return false;
    }
    return true;
  }
}
