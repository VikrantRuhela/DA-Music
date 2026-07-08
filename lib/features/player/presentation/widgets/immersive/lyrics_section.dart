import 'package:flutter/material.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../app/theme/tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../shared/providers/player_providers.dart';
import '../../../../../core/services/lyrics_controller.dart';

class LyricsSection extends ConsumerStatefulWidget {
  const LyricsSection({super.key});

  @override
  ConsumerState<LyricsSection> createState() => _LyricsSectionState();
}

class _LyricsSectionState extends ConsumerState<LyricsSection> {
  String? _lastSongId;

  @override
  Widget build(BuildContext context) {
    final colors = context.daColors;
    final typography = context.daTypography;
    final currentSong = ref.watch(currentSongProvider);
    final lyricsState = ref.watch(lyricsControllerProvider);
    final playbackPosition = ref.watch(playbackControllerProvider).position;

    if (currentSong != null && currentSong.id != _lastSongId) {
      _lastSongId = currentSong.id;
    }

    if (currentSong == null || lyricsState.isLoading || lyricsState.songId != currentSong.id) {
      return const SizedBox.shrink();
    }

    if (lyricsState.isInstrumental) {
      return const SizedBox.shrink();
    }

    int activeIndex = -1;
    List<String> lines = [];

    if (lyricsState.syncedLyrics != null && lyricsState.syncedLyrics!.isNotEmpty) {
      final sortedTimestamps = lyricsState.syncedLyrics!.keys.toList()..sort();
      lines = sortedTimestamps.map((t) => lyricsState.syncedLyrics![t]!).toList();
      for (int i = 0; i < sortedTimestamps.length; i++) {
        if (sortedTimestamps[i] <= playbackPosition) {
          activeIndex = i;
        } else {
          break;
        }
      }
    } else if (lyricsState.plainLyrics.isNotEmpty) {
      lines = lyricsState.plainLyrics.split('\n');
    }

    // Completely hide the card if lyrics are unavailable
    final bool hasLyrics = lines.isNotEmpty && 
        !lines.contains('Lyrics unavailable.') && 
        !lines.contains('Lyrics are unavailable for this song.');
    if (!hasLyrics) {
      return const SizedBox.shrink();
    }

    final String currentLine = activeIndex >= 0 && activeIndex < lines.length
        ? lines[activeIndex]
        : (lines.isNotEmpty && lyricsState.syncedLyrics == null ? lines.first : '...');

    final String nextLine = activeIndex + 1 >= 0 && activeIndex + 1 < lines.length
        ? lines[activeIndex + 1]
        : '';

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 480.0),
      margin: const EdgeInsets.symmetric(horizontal: DATokens.spacingLarge),
      padding: const EdgeInsets.all(DATokens.spacingLarge),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DATokens.radiusLarge),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.25),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.lyrics_outlined, size: 16.0, color: colors.primary),
              const SizedBox(width: DATokens.spacingSmall),
              Text(
                'LYRICS',
                style: typography.caption.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: DATokens.spacingMedium),
          Text(
            currentLine,
            style: typography.body.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (nextLine.isNotEmpty) ...[
            const SizedBox(height: DATokens.spacingSmall),
            Text(
              nextLine,
              style: typography.body.copyWith(
                color: colors.textSecondary.withValues(alpha: 0.6),
                fontSize: 13.0,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
