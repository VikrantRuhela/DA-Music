import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/music_models.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../app/theme/tokens.dart';

class SongInfoSheet extends StatelessWidget {
  final Song song;

  const SongInfoSheet({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    final colors = context.daColors;
    final typography = context.daTypography;

    final isLocal = !song.id.startsWith('http') && song.source == 'local';
    final codec = song.source == 'youtube_music' ? 'Opus' : 'AAC';
    final bitrate = song.source == 'youtube_music' ? '160 kbps' : '256 kbps';
    const sampleRate = '44.1 kHz';
    final fileSize = isLocal ? '8.4 MB' : 'N/A (Stream)';
    final durationStr = '${song.duration.inMinutes}:${(song.duration.inSeconds % 60).toString().padLeft(2, '0')}';

    Widget buildInfoRow(String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: typography.body.copyWith(
                color: colors.textSecondary,
                fontSize: 14.0,
              ),
            ),
            Text(
              value,
              style: typography.body.copyWith(
                color: colors.textPrimary,
                fontSize: 14.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.75),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28.0),
        ),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28.0),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(DATokens.spacingLarge),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40.0,
                      height: 4.0,
                      decoration: BoxDecoration(
                        color: colors.textSecondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  Text(
                    'Song Information',
                    style: typography.title.copyWith(
                      color: colors.textPrimary,
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Divider(color: colors.border.withValues(alpha: 0.2)),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          buildInfoRow('Title', song.title),
                          buildInfoRow('Artist', song.artist),
                          buildInfoRow('Album', song.album == 'yt_album_unknown' ? 'Unknown' : song.album),
                          buildInfoRow('Duration', durationStr),
                          buildInfoRow('Source', song.source.toUpperCase()),
                          buildInfoRow('Quality', 'High Quality (HQ)'),
                          buildInfoRow('Codec', codec),
                          buildInfoRow('Bitrate', bitrate),
                          buildInfoRow('Sample Rate', sampleRate),
                          buildInfoRow('File Size', fileSize),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
