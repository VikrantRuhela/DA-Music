import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../app/theme/tokens.dart';
import '../../../shared/providers/player_providers.dart';
import '../../../core/services/lyrics_controller.dart';
import '../../../shared/widgets/da_empty_state.dart';

class LyricsPage extends ConsumerStatefulWidget {
  const LyricsPage({super.key});

  @override
  ConsumerState<LyricsPage> createState() => _LyricsPageState();
}

class _LyricsPageState extends ConsumerState<LyricsPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isUserScrolling = false;
  Timer? _userScrollTimer;
  int _lastActiveIndex = -1;
  String? _lastSongId;

  @override
  void dispose() {
    _scrollController.dispose();
    _userScrollTimer?.cancel();
    super.dispose();
  }

  void _scrollToActiveLine(int index, double viewportHeight) {
    if (_isUserScrolling || !_scrollController.hasClients) return;

    // Use 70.0 as height per item + spacing
    final targetOffset = index * 70.0 - (viewportHeight / 2) + 35.0;
    
    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 500),
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.daColors;
    final typography = context.daTypography;
    
    final currentSong = ref.watch(currentSongProvider);
    final lyricsState = ref.watch(lyricsControllerProvider);
    final playbackPosition = ref.watch(playbackControllerProvider).position;

    if (currentSong != null && currentSong.id != _lastSongId) {
      _lastSongId = currentSong.id;
      _lastActiveIndex = -1;
      _isUserScrolling = false;
      _userScrollTimer?.cancel();
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0.0);
      }
    }

    if (currentSong == null) {
      return Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            color: colors.textPrimary,
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: DAEmptyState(
            icon: Icons.music_note_outlined,
            title: 'No Song Playing',
            description: 'Start playing a song to view lyrics.',
          ),
        ),
      );
    }

    // Determine active index for synced lyrics
    int activeIndex = -1;
    List<Duration> timestamps = [];
    List<String> lines = [];

    if (lyricsState.syncedLyrics != null && lyricsState.syncedLyrics!.isNotEmpty) {
      timestamps = lyricsState.syncedLyrics!.keys.toList()..sort();
      lines = timestamps.map((t) => lyricsState.syncedLyrics![t]!).toList();
      
      for (int i = 0; i < timestamps.length; i++) {
        if (timestamps[i] <= playbackPosition) {
          activeIndex = i;
        } else {
          break;
        }
      }
    } else if (lyricsState.plainLyrics.isNotEmpty) {
      lines = lyricsState.plainLyrics.split('\n');
    }

    // Auto-scroll when active line changes
    if (activeIndex != _lastActiveIndex && activeIndex != -1) {
      _lastActiveIndex = activeIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final height = MediaQuery.of(context).size.height;
        _scrollToActiveLine(activeIndex, height);
      });
    }

    final artworkUrl = currentSong.artworkUrl ?? '';

    return Scaffold(
      body: Stack(
        children: [
          // 1. Dynamic blurred album art background
          Positioned.fill(
            child: artworkUrl.isNotEmpty
                ? Image.network(
                    artworkUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: colors.surface),
                  )
                : Container(color: colors.surface),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.55),
            ),
          ),
          const Positioned.fill(
            child: BackdropFilter(
              filter: ColorFilter.mode(Colors.black12, BlendMode.darken),
              child: SizedBox(),
            ),
          ),

          // 2. Full-Screen content Layout
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom App Bar Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DATokens.spacingMedium,
                    vertical: DATokens.spacingSmall,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down, size: 32.0),
                        color: Colors.white,
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: DATokens.spacingSmall),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(DATokens.radiusSmall),
                        child: artworkUrl.isNotEmpty
                            ? Image.network(
                                artworkUrl,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.music_note, color: Colors.white),
                              )
                            : const Icon(Icons.music_note, color: Colors.white),
                      ),
                      const SizedBox(width: DATokens.spacingMedium),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentSong.title,
                              style: typography.body.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              currentSong.artist,
                              style: typography.caption.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white10, height: 1.0),

                // Main body: Lyrics display list
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (lyricsState.isLoading || lyricsState.songId != currentSong.id) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      }

                      if (lyricsState.isInstrumental) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.music_note, size: 64, color: Colors.white70),
                              const SizedBox(height: DATokens.spacingMedium),
                              Text(
                                'Instrumental',
                                style: typography.title.copyWith(color: Colors.white),
                              ),
                            ],
                          ),
                        );
                      }

                      if (lyricsState.error != null || lines.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.lyrics_outlined, size: 64, color: Colors.white70),
                              const SizedBox(height: DATokens.spacingMedium),
                              Text(
                                lyricsState.error ?? 'No lyrics available',
                                style: typography.title.copyWith(color: Colors.white),
                              ),
                            ],
                          ),
                        );
                      }

                      // Dynamic scrolled / non-scrolled lyric views
                      return NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification is ScrollStartNotification) {
                            if (notification.dragDetails != null) {
                              setState(() {
                                _isUserScrolling = true;
                              });
                              _userScrollTimer?.cancel();
                              _userScrollTimer = Timer(const Duration(seconds: 4), () {
                                if (mounted) {
                                  setState(() {
                                    _isUserScrolling = false;
                                  });
                                }
                              });
                            }
                          }
                          return false;
                        },
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            vertical: 120.0,
                            horizontal: DATokens.spacingLarge,
                          ),
                          physics: const BouncingScrollPhysics(),
                          itemCount: lines.length,
                          itemBuilder: (context, index) {
                            final isSynced = timestamps.isNotEmpty;
                            final isActive = isSynced && index == activeIndex;
                            
                            // Dim lines that are not currently active
                            final color = isSynced
                                ? (isActive ? colors.primary : Colors.white.withValues(alpha: 0.35))
                                : Colors.white;

                            final style = typography.title.copyWith(
                              color: color,
                              fontSize: isActive ? 23.0 : 19.0,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                              height: 1.4,
                            );

                            return InkWell(
                              onTap: isSynced
                                  ? () {
                                      ref.read(playbackControllerProvider).seek(timestamps[index]);
                                      setState(() {
                                        _isUserScrolling = false;
                                      });
                                    }
                                  : null,
                              splashColor: Colors.white12,
                              borderRadius: BorderRadius.circular(DATokens.radiusMedium),
                              child: Container(
                                constraints: const BoxConstraints(minHeight: 70.0),
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(
                                  vertical: DATokens.spacingSmall,
                                  horizontal: DATokens.spacingSmall,
                                ),
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 250),
                                  style: style,
                                  child: Text(lines[index]),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Return to sync button overlay
          if (_isUserScrolling && timestamps.isNotEmpty)
            Positioned(
              bottom: 30,
              right: 20,
              child: FloatingActionButton.extended(
                backgroundColor: colors.primary,
                onPressed: () {
                  setState(() {
                    _isUserScrolling = false;
                  });
                  if (activeIndex != -1) {
                    final height = MediaQuery.of(context).size.height;
                    _scrollToActiveLine(activeIndex, height);
                  }
                },
                icon: const Icon(Icons.sync, color: Colors.white),
                label: const Text(
                  'Sync View',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
