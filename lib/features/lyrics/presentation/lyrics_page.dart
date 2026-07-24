import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../app/theme/tokens.dart';
import '../../../shared/providers/player_providers.dart';
import '../../../core/services/lyrics_controller.dart';
import '../../../shared/widgets/da_empty_state.dart';
import '../../../shared/widgets/da_image.dart';

class AnimatedBackgroundOrbs extends StatefulWidget {
  final String artworkUrl;

  const AnimatedBackgroundOrbs({super.key, required this.artworkUrl});

  @override
  State<AnimatedBackgroundOrbs> createState() => _AnimatedBackgroundOrbsState();
}

class _AnimatedBackgroundOrbsState extends State<AnimatedBackgroundOrbs> with SingleTickerProviderStateMixin {
  late final AnimationController _orbController;

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();
  }

  @override
  void dispose() {
    _orbController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.daColors;
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 1000),
            child: DAImage(
              key: ValueKey<String>(widget.artworkUrl),
              url: widget.artworkUrl,
              fit: BoxFit.cover,
              placeholder: Container(color: Colors.black87),
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _orbController,
          builder: (context, child) {
            final t = _orbController.value;
            final dx1 = sin(t * 2 * pi) * 120.0;
            final dy1 = cos(t * 2 * pi) * 120.0;
            final dx2 = cos(t * 2 * pi + pi) * 140.0;
            final dy2 = sin(t * 2 * pi + pi) * 140.0;

            final size = MediaQuery.of(context).size;

            return Stack(
              children: [
                Positioned(
                  left: size.width * 0.15 + dx1,
                  top: size.height * 0.25 + dy1,
                  child: Container(
                    width: size.width * 0.45,
                    height: size.width * 0.45,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                ),
                Positioned(
                  right: size.width * 0.1 + dx2,
                  bottom: size.height * 0.2 + dy2,
                  child: Container(
                    width: size.width * 0.5,
                    height: size.width * 0.5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.accent.withValues(alpha: 0.25),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class LyricLineWidget extends StatelessWidget {
  final String text;
  final bool isActive;
  final int index;
  final int activeIndex;
  final VoidCallback onTap;
  final String? timestampText;
  final dynamic colors;

  const LyricLineWidget({
    super.key,
    required this.text,
    required this.isActive,
    required this.index,
    required this.activeIndex,
    required this.onTap,
    this.timestampText,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final cleanText = text.replaceAll(RegExp(r'<.*?>'), '').trim();
    final int distanceFromActive = (index - activeIndex).abs();
    final double targetBlur = isActive ? 0.0 : (distanceFromActive.toDouble() * 1.5).clamp(0.0, 5.0);
    final double targetOpacity = isActive ? 1.0 : (0.45 / distanceFromActive).clamp(0.12, 0.45);

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(end: targetBlur),
      builder: (context, blurValue, child) {
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          tween: Tween<double>(end: targetOpacity),
          builder: (context, opacityValue, child) {
            Widget textContent = Text(
              cleanText,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: isActive ? 25.0 : 20.0,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                color: Colors.white,
                height: 1.4,
                shadows: isActive
                    ? [
                        Shadow(
                          color: colors.primary.withValues(alpha: 0.5),
                          blurRadius: 10.0,
                        ),
                      ]
                    : null,
              ),
              textAlign: TextAlign.center,
            );

            if (blurValue > 0.05) {
              textContent = ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: blurValue, sigmaY: blurValue),
                child: Opacity(
                  opacity: opacityValue,
                  child: textContent,
                ),
              );
            } else {
              textContent = Opacity(
                opacity: opacityValue,
                child: textContent,
              );
            }

            return GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.only(left: isActive ? 12.0 : 0.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        width: isActive ? 4.0 : 0.0,
                        height: isActive ? 24.0 : 0.0,
                        margin: EdgeInsets.only(right: isActive ? 12.0 : 0.0),
                        decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius: BorderRadius.circular(2.0),
                          boxShadow: [
                            BoxShadow(
                              color: colors.primary.withValues(alpha: 0.6),
                              blurRadius: 8.0,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: textContent,
                      ),
                      if (timestampText != null) ...[
                        const SizedBox(width: 16.0),
                        Text(
                          timestampText!,
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Colors.white.withValues(alpha: isActive ? 0.6 : 0.2),
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

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
  List<GlobalKey> _lineKeys = [];

  @override
  void dispose() {
    _scrollController.dispose();
    _userScrollTimer?.cancel();
    super.dispose();
  }

  void _scrollToActiveLine(int index) {
    if (_isUserScrolling || index < 0 || index >= _lineKeys.length) return;

    final key = _lineKeys[index];
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
  }

  String _formatTimestamp(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
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
      return PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) {
            ref.read(immersiveModeProvider.notifier).state = true;
          }
        },
        child: Scaffold(
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
        ),
      );
    }

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

    if (lines.length != _lineKeys.length) {
      _lineKeys = List.generate(lines.length, (index) => GlobalKey());
    }

    if (activeIndex != _lastActiveIndex && activeIndex != -1) {
      _lastActiveIndex = activeIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToActiveLine(activeIndex);
      });
    }

    final artworkUrl = currentSong.artworkUrl ?? '';

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          ref.read(immersiveModeProvider.notifier).state = true;
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colors.gradientStart,
                      colors.gradientMiddle,
                      colors.gradientEnd,
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: AnimatedBackgroundOrbs(artworkUrl: artworkUrl),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 45.0, sigmaY: 45.0),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.55),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
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
                            child: DAImage(
                              url: artworkUrl,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              placeholder: const Icon(Icons.music_note, color: Colors.white),
                            ),
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
                    const SizedBox(height: 16.0),
                    Expanded(
                      child: _buildLyricsGlassContainer(
                        colors,
                        lyricsState,
                        lines,
                        activeIndex,
                        timestamps,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isUserScrolling && timestamps.isNotEmpty)
              Positioned(
                bottom: 30,
                right: 30,
                child: FloatingActionButton.extended(
                  backgroundColor: colors.primary,
                  onPressed: () {
                    setState(() {
                      _isUserScrolling = false;
                    });
                    if (activeIndex != -1) {
                      _scrollToActiveLine(activeIndex);
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
      ),
    );
  }

  Widget _buildLyricsGlassContainer(
    dynamic colors,
    dynamic lyricsState,
    List<String> lines,
    int activeIndex,
    List<Duration> timestamps,
  ) {
    Widget innerContent;

    if (lyricsState.isLoading) {
      innerContent = const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator(color: Colors.white),
      );
    } else if (lyricsState.isInstrumental) {
      innerContent = Center(
        key: const ValueKey('instrumental'),
        child: Text(
          'Instrumental Track',
          style: context.daTypography.title.copyWith(color: Colors.white),
        ),
      );
    } else if (lines.isEmpty || lines.contains('Lyrics unavailable.')) {
      innerContent = Center(
        key: const ValueKey('unavailable'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lyrics_outlined, color: Colors.white24, size: 48.0),
            const SizedBox(height: DATokens.spacingMedium),
            Text(
              'Lyrics Unavailable',
              style: context.daTypography.body.copyWith(color: Colors.white54),
            ),
          ],
        ),
      );
    } else {
      innerContent = Column(
        key: const ValueKey('content'),
        mainAxisSize: MainAxisSize.min,
        children: List.generate(lines.length, (index) {
          final isActive = index == activeIndex;
          return LyricLineWidget(
            key: _lineKeys[index],
            text: lines[index],
            isActive: isActive,
            index: index,
            activeIndex: activeIndex,
            colors: colors,
            timestampText: (_isUserScrolling && timestamps.isNotEmpty)
                ? _formatTimestamp(timestamps[index])
                : null,
            onTap: () {
              if (timestamps.isNotEmpty) {
                ref.read(playbackControllerProvider).seek(timestamps[index]);
                setState(() {
                  _isUserScrolling = false;
                });
              }
            },
          );
        }),
      );
    }

    final height = MediaQuery.of(context).size.height;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: ShaderMask(
          shaderCallback: (rect) {
            return const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.white, Colors.white, Colors.transparent],
              stops: [0.0, 0.15, 0.85, 1.0],
            ).createShader(rect);
          },
          blendMode: BlendMode.dstIn,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification) {
                if (notification.dragDetails != null) {
                  setState(() {
                    _isUserScrolling = true;
                  });
                  _userScrollTimer?.cancel();
                }
              } else if (notification is ScrollEndNotification) {
                _userScrollTimer?.cancel();
                _userScrollTimer = Timer(const Duration(seconds: 4), () {
                  if (mounted) {
                    setState(() {
                      _isUserScrolling = false;
                    });
                    if (activeIndex != -1) {
                      _scrollToActiveLine(activeIndex);
                    }
                  }
                });
              }
              return false;
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                vertical: height / 2 - 40.0,
                horizontal: 24.0,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: KeyedSubtree(
                  key: ValueKey<String>('${_lastSongId}_${lyricsState.isLoading}'),
                  child: innerContent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
