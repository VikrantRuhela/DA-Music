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
  final ScrollController _scrollController = ScrollController();
  int _lastActiveIndex = -1;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActiveLine(int index) {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      (index * 32.0).clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.daColors;
    final typography = context.daTypography;
    final lyricsState = ref.watch(lyricsControllerProvider);
    final playbackPosition = ref.watch(playbackControllerProvider).position;

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

    if (lyricsState.isInstrumental) {
      lines = ['Instrumental'];
    }

    // If lyrics are not available, completely hide the card
    final bool hasLyrics = lines.isNotEmpty && !lines.contains('Lyrics unavailable.');
    if (!hasLyrics) {
      return const SizedBox.shrink();
    }

    if (activeIndex != _lastActiveIndex && activeIndex != -1) {
      _lastActiveIndex = activeIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToActiveLine(activeIndex);
      });
    }

    return Container(
      height: 160.0,
      constraints: const BoxConstraints(maxWidth: 600.0),
      margin: const EdgeInsets.symmetric(horizontal: DATokens.spacingLarge),
      decoration: BoxDecoration(
        color: colors.surfaceCard.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(DATokens.radiusLarge),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      child: Stack(
        children: [
          // Scrollable Lyrics List
          ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                vertical: DATokens.spacingMedium,
                horizontal: DATokens.spacingLarge,
              ),
              physics: const BouncingScrollPhysics(),
              itemCount: lines.length,
              itemBuilder: (context, index) {
                final isActive = activeIndex != -1 && index == activeIndex;
                final color = isActive
                    ? colors.primary
                    : colors.textSecondary.withValues(alpha: 0.6);

                final style = isActive
                    ? typography.body.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      )
                    : typography.body.copyWith(
                        color: color,
                        fontSize: 14.0,
                      );

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: DATokens.spacingTiny + 2.0,
                  ),
                  child: Center(
                    child: Text(
                      lines[index],
                      style: style,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ),
          ),

          // Top Fade Gradient Overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 32.0,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colors.surface.withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom Fade Gradient Overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 32.0,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      colors.surface.withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
