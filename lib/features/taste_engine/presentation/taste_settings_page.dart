import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../shared/widgets/da_card.dart';
import 'providers/taste_engine_providers.dart';

class TasteSettingsPage extends ConsumerWidget {
  const TasteSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.daColors;
    final typography = context.daTypography;
    final state = ref.watch(tasteEngineNotifierProvider);
    final notifier = ref.read(tasteEngineNotifierProvider.notifier);

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
          'Taste Engine & Privacy',
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
            // Preference Controls Section
            Text('Control Your Experience', style: typography.title.copyWith(fontSize: 16.0, fontWeight: FontWeight.bold, color: colors.textPrimary)),
            const SizedBox(height: DATokens.spacingSmall),
            DACard(
              child: Column(
                children: [
                  _buildSwitchTile(
                    context: context,
                    icon: Icons.pause_circle_outline,
                    title: 'Pause Taste Learning',
                    subtitle: 'Temporarily stop logging playback and searches',
                    value: state.isLearningPaused,
                    onChanged: (val) {
                      notifier.setLearningPaused(val);
                    },
                    colors: colors,
                  ),
                  const Divider(height: 1, color: Colors.white10),
                  _buildSwitchTile(
                    context: context,
                    icon: Icons.psychology_outlined,
                    title: 'Personalized Recommendations',
                    subtitle: 'Use your Music DNA to curate the Home Feed',
                    value: state.isPersonalizationEnabled,
                    onChanged: (val) {
                      notifier.setPersonalizationEnabled(val);
                    },
                    colors: colors,
                  ),
                  const Divider(height: 1, color: Colors.white10),
                  _buildSwitchTile(
                    context: context,
                    icon: Icons.download_done_outlined,
                    title: 'Exclude Downloads',
                    subtitle: 'Exclude downloaded songs from recommendation algorithms',
                    value: state.excludeDownloads,
                    onChanged: (val) {
                      notifier.setExcludeDownloads(val);
                    },
                    colors: colors,
                  ),
                ],
              ),
            ),
            const SizedBox(height: DATokens.spacingLarge),

            // History Management Section
            Text('Data & Privacy', style: typography.title.copyWith(fontSize: 16.0, fontWeight: FontWeight.bold, color: colors.textPrimary)),
            const SizedBox(height: DATokens.spacingSmall),
            DACard(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
                    title: Text('Clear Listening History', style: TextStyle(color: colors.textPrimary)),
                    subtitle: Text('Deletes all local play logs permanently', style: TextStyle(color: colors.textSecondary, fontSize: 12.0)),
                    onTap: () => _showClearConfirmationDialog(context, ref, false),
                  ),
                  const Divider(height: 1, color: Colors.white10),
                  ListTile(
                    leading: const Icon(Icons.restart_alt_outlined, color: Colors.redAccent),
                    title: Text('Reset Music DNA Profile', style: TextStyle(color: colors.textPrimary)),
                    subtitle: Text('Deletes history and rebuilds listening insights', style: TextStyle(color: colors.textSecondary, fontSize: 12.0)),
                    onTap: () => _showClearConfirmationDialog(context, ref, true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DATokens.spacingLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required dynamic colors,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: colors.primary),
      title: Text(title, style: TextStyle(color: colors.textPrimary)),
      subtitle: Text(subtitle, style: TextStyle(color: colors.textSecondary, fontSize: 12.0)),
      value: value,
      activeThumbColor: colors.primary,
      onChanged: onChanged,
    );
  }

  void _showClearConfirmationDialog(BuildContext context, WidgetRef ref, bool isDnaReset) {
    final colors = context.daColors;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colors.surfaceCard,
          title: Text(isDnaReset ? 'Reset Music DNA?' : 'Clear History?', style: TextStyle(color: colors.textPrimary)),
          content: Text(
            isDnaReset
                ? 'This will delete all listening history logs and reset your Music DNA profile. This action cannot be undone.'
                : 'This will delete your local listening history play logs. This action cannot be undone.',
            style: TextStyle(color: colors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                final notifier = ref.read(tasteEngineNotifierProvider.notifier);
                if (isDnaReset) {
                  await notifier.resetMusicDNA();
                } else {
                  await notifier.clearHistory();
                }
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isDnaReset ? 'Music DNA has been reset.' : 'Listening history cleared.'),
                    ),
                  );
                }
              },
              child: const Text('Confirm', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
