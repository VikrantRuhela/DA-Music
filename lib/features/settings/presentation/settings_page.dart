import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/services/logger_service.dart';
import '../../../shared/animations/motion_system.dart';
import '../../../shared/providers/source_providers.dart';
import '../../../shared/widgets/da_card.dart';

final diagnosticLoggingProvider = StateProvider<bool>((ref) {
  return DALogger.activeLevel == LogLevel.debug;
});

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.daColors;
    final typography = context.daTypography;

    final motionMode = ref.watch(motionScaleModeProvider);
    final diagnosticLogging = ref.watch(diagnosticLoggingProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: DATokens.spacingLarge,
          vertical: DATokens.spacingMedium,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            Padding(
              padding: const EdgeInsets.only(bottom: DATokens.spacingLarge),
              child: Text(
                'Settings',
                style: typography.title.copyWith(fontSize: 28.0),
              ),
            ),

            // Section 1: Animations & Motion System
            _buildSectionHeader(context, 'Motion & Accessibility'),
            DACard(
              child: Column(
                children: [
                  _buildSwitchTile(
                    context: context,
                    icon: Icons.motion_photos_off_outlined,
                    title: 'Reduce Motion',
                    subtitle: 'Simplify page transitions and card hovers',
                    value: motionMode == MotionScaleMode.reduced || motionMode == MotionScaleMode.disabled,
                    onChanged: (val) {
                      ref.read(motionScaleModeProvider.notifier).state =
                          val ? MotionScaleMode.reduced : MotionScaleMode.normal;
                    },
                  ),
                  const Divider(height: 1),
                  _buildDropdownTile<MotionScaleMode>(
                    context: context,
                    icon: Icons.speed_outlined,
                    title: 'Animation Scale',
                    subtitle: 'Adjust global system animation speed',
                    value: motionMode,
                    items: const [
                      DropdownMenuItem(
                        value: MotionScaleMode.normal,
                        child: Text('Normal (100%)'),
                      ),
                      DropdownMenuItem(
                        value: MotionScaleMode.reduced,
                        child: Text('Reduced (50%)'),
                      ),
                      DropdownMenuItem(
                        value: MotionScaleMode.disabled,
                        child: Text('Disabled (0%)'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(motionScaleModeProvider.notifier).state = val;
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: DATokens.spacingLarge),

            // Section 2: Storage & Cache Management
            _buildSectionHeader(context, 'Cache & Local Storage'),
            DACard(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.cleaning_services_outlined, color: colors.primary),
                    title: Text(
                      'Clear Playback Cache',
                      style: typography.title.copyWith(fontSize: 15.0),
                    ),
                    subtitle: Text(
                      'Free up space by removing cached album art and track metadata',
                      style: typography.body.copyWith(fontSize: 12.0, color: colors.textSecondary),
                    ),
                    trailing: TextButton(
                      onPressed: () {
                        // Clear caches
                        ref.read(sourceManagerProvider).clearCache();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Local playback metadata caches successfully cleared.'),
                            backgroundColor: colors.primary,
                          ),
                        );
                      },
                      child: const Text('Clear'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DATokens.spacingLarge),

            // Section 3: General Developer Options
            _buildSectionHeader(context, 'Developer Options'),
            DACard(
              child: Column(
                children: [
                  _buildSwitchTile(
                    context: context,
                    icon: Icons.bug_report_outlined,
                    title: 'Diagnostic Logging',
                    subtitle: 'Dump active platform API and audio backend ticks',
                    value: diagnosticLogging,
                    onChanged: (val) {
                      ref.read(diagnosticLoggingProvider.notifier).state = val;
                      DALogger.activeLevel = val ? LogLevel.debug : LogLevel.error;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final colors = context.daColors;
    final typography = context.daTypography;
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: DATokens.spacingSmall),
      child: Text(
        title.toUpperCase(),
        style: typography.body.copyWith(
          fontSize: 11.0,
          fontWeight: FontWeight.bold,
          color: colors.textSecondary.withValues(alpha: 0.8),
          letterSpacing: 1.2,
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
  }) {
    final colors = context.daColors;
    final typography = context.daTypography;
    return ListTile(
      leading: Icon(icon, color: colors.primary),
      title: Text(title, style: typography.title.copyWith(fontSize: 15.0)),
      subtitle: Text(subtitle, style: typography.body.copyWith(fontSize: 12.0, color: colors.textSecondary)),
      trailing: Switch.adaptive(
        value: value,
        activeThumbColor: colors.primary,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDropdownTile<T>({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    final colors = context.daColors;
    final typography = context.daTypography;
    return ListTile(
      leading: Icon(icon, color: colors.primary),
      title: Text(title, style: typography.title.copyWith(fontSize: 15.0)),
      subtitle: Text(subtitle, style: typography.body.copyWith(fontSize: 12.0, color: colors.textSecondary)),
      trailing: DropdownButton<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        underline: const SizedBox.shrink(),
        dropdownColor: colors.surfaceCard,
        style: typography.body.copyWith(fontSize: 14.0, color: colors.textPrimary),
      ),
    );
  }
}
