import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../shared/widgets/da_card.dart';
import 'providers/taste_engine_providers.dart';

class MusicDnaPage extends ConsumerWidget {
  const MusicDnaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.daColors;
    final typography = context.daTypography;
    final state = ref.watch(tasteEngineNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Music DNA Insights',
          style: typography.title.copyWith(fontSize: 20.0, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: DATokens.spacingLarge,
          vertical: DATokens.spacingMedium,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transparency Shield Banner
            _buildTransparencyBanner(context, colors, typography),
            const SizedBox(height: DATokens.spacingMedium),

            // Profile Card (Mood & Peak time)
            _buildMoodProfileCard(context, state, colors, typography),
            const SizedBox(height: DATokens.spacingLarge),

            // Top sections headers and grids
            Text('Top Interests', style: typography.title.copyWith(fontSize: 16.0, fontWeight: FontWeight.bold, color: colors.textPrimary)),
            const SizedBox(height: DATokens.spacingSmall),
            _buildInterestsSection(context, state, colors, typography),
            const SizedBox(height: DATokens.spacingLarge),

            // Metrics
            Text('Listening Habits', style: typography.title.copyWith(fontSize: 16.0, fontWeight: FontWeight.bold, color: colors.textPrimary)),
            const SizedBox(height: DATokens.spacingSmall),
            _buildHabitsSection(context, state, colors, typography),
            const SizedBox(height: DATokens.spacingLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildTransparencyBanner(BuildContext context, dynamic colors, dynamic typography) {
    return DACard(
      child: Padding(
        padding: const EdgeInsets.all(DATokens.spacingMedium),
        child: Row(
          children: [
            const Icon(Icons.security, color: Colors.greenAccent, size: 32.0),
            const SizedBox(width: DATokens.spacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '100% On-Device & Private',
                    style: typography.title.copyWith(fontSize: 13.0, fontWeight: FontWeight.bold, color: colors.textPrimary),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    'All of your music insights are generated locally. Your listening history is never uploaded or shared.',
                    style: typography.caption.copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodProfileCard(BuildContext context, TasteEngineState state, dynamic colors, dynamic typography) {
    final dna = state.dna;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary.withValues(alpha: 0.2), colors.secondary.withValues(alpha: 0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DATokens.radiusLarge),
        border: Border.all(color: colors.primary.withValues(alpha: 0.25)),
      ),
      padding: const EdgeInsets.all(DATokens.spacingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Listening Mood', style: typography.caption.copyWith(color: colors.textSecondary)),
                  const SizedBox(height: 4.0),
                  Text(
                    dna.listeningMood,
                    style: typography.title.copyWith(fontSize: 22.0, fontWeight: FontWeight.bold, color: colors.primary),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(DATokens.spacingMedium),
                child: Icon(Icons.bubble_chart, color: colors.primary, size: 28.0),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 24.0),
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.white54, size: 18.0),
              const SizedBox(width: DATokens.spacingSmall),
              Text(
                'Peak Activity: ',
                style: typography.caption.copyWith(color: colors.textSecondary),
              ),
              Text(
                dna.peakListeningTime,
                style: typography.caption.copyWith(color: colors.textPrimary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsSection(BuildContext context, TasteEngineState state, dynamic colors, dynamic typography) {
    final dna = state.dna;
    return Column(
      children: [
        _buildListCard('Top Artists', dna.topArtists, Icons.person, colors, typography),
        const SizedBox(height: DATokens.spacingSmall),
        _buildListCard('Top Albums', dna.topAlbums, Icons.album, colors, typography),
        const SizedBox(height: DATokens.spacingSmall),
        _buildListCard('Top Genres', dna.favoriteGenres, Icons.music_note, colors, typography),
        const SizedBox(height: DATokens.spacingSmall),
        _buildListCard('Top Languages', dna.favoriteLanguages, Icons.language, colors, typography),
      ],
    );
  }

  Widget _buildListCard(String title, List<String> items, IconData icon, dynamic colors, dynamic typography) {
    return DACard(
      child: Padding(
        padding: const EdgeInsets.all(DATokens.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colors.primary, size: 20.0),
                const SizedBox(width: DATokens.spacingSmall),
                Text(
                  title,
                  style: typography.title.copyWith(fontSize: 14.0, fontWeight: FontWeight.bold, color: colors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: DATokens.spacingMedium),
            if (items.isEmpty)
              Text('No data collected yet.', style: typography.caption.copyWith(color: colors.textSecondary))
            else
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: items.map((item) {
                  return Container(
                    decoration: BoxDecoration(
                      color: colors.surfaceHover,
                      borderRadius: BorderRadius.circular(DATokens.radiusSmall),
                      border: Border.all(color: colors.border.withValues(alpha: 0.2)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                    child: Text(
                      item,
                      style: typography.caption.copyWith(color: colors.textPrimary, fontSize: 12.0),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitsSection(BuildContext context, TasteEngineState state, dynamic colors, dynamic typography) {
    final dna = state.dna;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: DATokens.spacingSmall,
      mainAxisSpacing: DATokens.spacingSmall,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard('Completion Rate', '${(dna.completionRate * 100).toStringAsFixed(0)}%', Colors.blueAccent, colors, typography),
        _buildMetricCard('Skip Rate', '${(dna.skipRate * 100).toStringAsFixed(0)}%', Colors.redAccent, colors, typography),
        _buildMetricCard('Replay Rate', '${(dna.replayRate * 100).toStringAsFixed(0)}%', Colors.amber, colors, typography),
        _buildMetricCard('Avg Session', '${dna.averageSessionLengthMinutes.toStringAsFixed(1)}m', Colors.greenAccent, colors, typography),
        _buildMetricCard('Offline Tracks', '${dna.downloadCount}', Colors.purpleAccent, colors, typography),
        _buildMetricCard('Favorites Count', '${dna.favoriteCount}', Colors.pinkAccent, colors, typography),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, Color accent, dynamic colors, dynamic typography) {
    return DACard(
      child: Padding(
        padding: const EdgeInsets.all(DATokens.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: typography.caption.copyWith(color: colors.textSecondary, fontSize: 11.0)),
            const SizedBox(height: 4.0),
            Text(
              value,
              style: typography.title.copyWith(fontSize: 20.0, fontWeight: FontWeight.bold, color: accent),
            ),
          ],
        ),
      ),
    );
  }
}
