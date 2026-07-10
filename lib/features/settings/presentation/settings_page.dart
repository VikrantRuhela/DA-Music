import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/services/ytm_sync_manager.dart';
import '../../../shared/animations/motion_system.dart';
import '../../../shared/providers/source_providers.dart';
import '../../../shared/providers/library_providers.dart';
import '../../../shared/providers/backend_providers.dart' hide sourceManagerProvider;
import '../../../shared/widgets/da_card.dart';
import '../../taste_engine/presentation/music_dna_page.dart';
import '../../taste_engine/presentation/taste_settings_page.dart';
import '../../onboarding/presentation/widgets/auth_webview_page.dart';
import '../../onboarding/presentation/widgets/cookie_login_dialog.dart';
import '../../onboarding/presentation/desktop_auth_helper.dart';

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
    final showAlbumArt = ref.watch(showAlbumArtBackgroundProvider);

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

            // Section 0: YouTube Music Account Management
            _buildSectionHeader(context, 'YouTube Music'),
            _buildYtmAccountSection(context, ref, colors, typography),
            const SizedBox(height: DATokens.spacingLarge),

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

            // Section 1.5: Appearance
            _buildSectionHeader(context, 'Appearance'),
            DACard(
              child: Column(
                children: [
                  _buildSwitchTile(
                    context: context,
                    icon: Icons.image_outlined,
                    title: 'Show Album Art as Background',
                    subtitle: 'Use blurred current playing album artwork as app background',
                    value: showAlbumArt,
                    onChanged: (val) {
                      ref.read(showAlbumArtBackgroundProvider.notifier).toggle(val);
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
            const SizedBox(height: DATokens.spacingLarge),
            _buildSectionHeader(context, 'Music Taste & Privacy'),
            DACard(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.bubble_chart_outlined, color: colors.primary),
                    title: Text('Music DNA Insights', style: typography.title.copyWith(fontSize: 15.0)),
                    subtitle: Text('View personalized listening habits and trends', style: typography.body.copyWith(fontSize: 12.0, color: colors.textSecondary)),
                    trailing: const Icon(Icons.chevron_right, size: 20.0),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MusicDnaPage()),
                      );
                    },
                  ),
                  const Divider(height: 1, color: Colors.white10),
                  ListTile(
                    leading: Icon(Icons.security_outlined, color: colors.primary),
                    title: Text('Taste Engine & Privacy', style: typography.title.copyWith(fontSize: 15.0)),
                    subtitle: Text('Manage listening logs and recommendation profile', style: typography.body.copyWith(fontSize: 12.0, color: colors.textSecondary)),
                    trailing: const Icon(Icons.chevron_right, size: 20.0),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TasteSettingsPage()),
                      );
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

  Widget _buildYtmAccountSection(
    BuildContext context,
    WidgetRef ref,
    dynamic colors,
    dynamic typography,
  ) {
    final session = ref.watch(sessionManagerProvider);
    final syncManager = ref.watch(ytmSyncManagerProvider);

    if (!session.isLoggedIn) {
      return DACard(
        child: Padding(
          padding: const EdgeInsets.all(DATokens.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YouTube Music Account',
                style: typography.title.copyWith(fontSize: 15.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4.0),
              Text(
                'Status: Not Logged In',
                style: typography.body.copyWith(fontSize: 13.0, color: Colors.redAccent),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Login to your YouTube Music account to synchronize your personalized home feed, history, recommendations, and playlists.',
                style: typography.body.copyWith(fontSize: 12.0, color: colors.textSecondary),
              ),
              const SizedBox(height: DATokens.spacingMedium),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () => _handleLogin(context, ref),
                  icon: const Icon(Icons.login),
                  label: const Text('Sign in to YouTube Music'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.textPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DATokens.radiusMedium),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final displayName = session.accountName ?? session.accountEmail ?? "YouTube Music Member";
    final lastSyncText = syncManager.lastSuccessfulSync != null
        ? 'Last Synced: ${_formatDateTime(syncManager.lastSuccessfulSync!)}'
        : 'Never Synced';

    return DACard(
      child: Padding(
        padding: const EdgeInsets.all(DATokens.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'YouTube Music Account',
              style: typography.title.copyWith(fontSize: 15.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4.0),
            Text(
              'Status: Logged In as $displayName',
              style: typography.body.copyWith(fontSize: 13.0, color: Colors.greenAccent),
            ),
            if (session.accountEmail != null && session.accountEmail != session.accountName) ...[
              const SizedBox(height: 2.0),
              Text(
                session.accountEmail!,
                style: typography.caption.copyWith(color: colors.textSecondary),
              ),
            ],
            const SizedBox(height: 6.0),
            Text(
              lastSyncText,
              style: typography.caption.copyWith(color: colors.textSecondary),
            ),
            if (syncManager.status == YtmSyncStatus.syncing) ...[
              const SizedBox(height: 8.0),
              Row(
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    'Syncing details...',
                    style: typography.caption.copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            ],
            const SizedBox(height: DATokens.spacingMedium),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: syncManager.status == YtmSyncStatus.syncing
                        ? null
                        : () => ref.read(ytmSyncManagerProvider.notifier).startSync(force: true),
                    icon: const Icon(Icons.sync),
                    label: Text(syncManager.status == YtmSyncStatus.syncing ? 'Syncing...' : 'Sync Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DATokens.radiusSmall),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: DATokens.spacingSmall),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('YouTube Music Profile'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Name: $displayName', style: typography.title.copyWith(fontSize: 14.0)),
                              const SizedBox(height: 4.0),
                              Text('Email: ${session.accountEmail ?? "Unknown"}', style: typography.title.copyWith(fontSize: 14.0)),
                              const SizedBox(height: 4.0),
                              Text('Authorized Client: Active', style: typography.caption.copyWith(color: colors.textSecondary)),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.account_circle_outlined),
                    label: const Text('Manage'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textPrimary,
                      side: BorderSide(color: colors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DATokens.radiusSmall),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: DATokens.spacingSmall),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => ref.read(sessionManagerProvider.notifier).logout(),
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DATokens.radiusSmall),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogin(BuildContext context, WidgetRef ref) async {
    if (Platform.isAndroid || Platform.isIOS) {
      final success = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (context) => const AuthWebViewPage()),
      );
      if (success == true) {
        ref.read(ytmSyncManagerProvider.notifier).startSync();
      }
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Connect to YouTube Music'),
          content: const Text(
            'Choose how you want to sign in to YouTube Music:\n\n'
            '1. In-App Webview: Simple sign-in window.\n'
            '2. Copy-Paste Cookies (Recommended): Copy your browser cookie header for a fully authenticated session.'
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => const CookieLoginDialog(),
                );
              },
              child: const Text('Copy-Paste Cookies'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final sessionManager = ref.read(sessionManagerProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening secure YouTube Music sign-in window...')),
                );
                await DesktopAuthHelper.loginWithDesktopWebview(
                  sessionManager,
                  onFinished: (success) {
                    if (success) {
                      ref.read(ytmSyncManagerProvider.notifier).startSync();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sign-in cancelled or failed.')),
                      );
                    }
                  },
                );
              },
              child: const Text('In-App Webview'),
            ),
          ],
        ),
      );
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
