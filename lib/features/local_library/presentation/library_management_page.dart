import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../app/theme/tokens.dart';
import '../../../shared/widgets/da_card.dart';
import '../data/local_library_repository.dart';

class LibraryManagementPage extends ConsumerWidget {
  const LibraryManagementPage({super.key});

  Future<void> _addFolder(BuildContext context, WidgetRef ref) async {
    // 1. Storage Permission Handling for Android
    if (Platform.isAndroid) {
      final audioStatus = await Permission.audio.status;
      if (!audioStatus.isGranted) {
        final result = await Permission.audio.request();
        if (!result.isGranted) {
          final storageStatus = await Permission.storage.status;
          if (!storageStatus.isGranted) {
            final storageResult = await Permission.storage.request();
            if (!storageResult.isGranted) {
              _showPermissionDeniedSnackBar(context);
              return;
            }
          }
        }
      }
    }

    // 2. Open Folder Picker
    try {
      final selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory != null) {
        await ref.read(localLibraryRepositoryProvider.notifier).addFolder(selectedDirectory);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added local folder: $selectedDirectory'),
              backgroundColor: context.daColors.primary,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick directory: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showPermissionDeniedSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Storage read permission is required to scan local music.'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.daColors;
    final typography = context.daTypography;

    final state = ref.watch(localLibraryRepositoryProvider);
    final isScanning = state.isScanning;
    final folders = state.folders;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: colors.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Local Library Management',
          style: typography.title.copyWith(fontSize: 20.0, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DATokens.spacingLarge),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scanning Status Card
            DACard(
              child: Padding(
                padding: const EdgeInsets.all(DATokens.spacingMedium),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          isScanning ? Icons.sync : Icons.library_music_outlined,
                          color: colors.primary,
                          size: 28,
                        ),
                        const SizedBox(width: DATokens.spacingMedium),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isScanning ? 'Scanning Folders...' : 'Library Scanned',
                                style: typography.title.copyWith(fontSize: 16),
                              ),
                              const SizedBox(height: DATokens.spacingTiny),
                              Text(
                                isScanning
                                    ? 'Parsing audio files and embedding covers...'
                                    : 'Scanned ${state.songs.length} audio tracks.',
                                style: typography.body.copyWith(
                                  color: colors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (isScanning) ...[
                      const SizedBox(height: DATokens.spacingMedium),
                      LinearProgressIndicator(
                        value: state.scanProgress,
                        backgroundColor: Colors.white10,
                        color: colors.primary,
                      ),
                      const SizedBox(height: DATokens.spacingTiny),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${(state.scanProgress * 100).round()}%',
                          style: typography.caption.copyWith(color: colors.textSecondary),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: DATokens.spacingLarge),

            // Section Header: Scanned Locations
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SCAN LOCATIONS',
                  style: typography.caption.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                TextButton.icon(
                  onPressed: isScanning ? null : () => _addFolder(context, ref),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Location'),
                  style: TextButton.styleFrom(foregroundColor: colors.primary),
                ),
              ],
            ),
            const SizedBox(height: DATokens.spacingSmall),

            // Scan locations list
            if (folders.isEmpty)
              DACard(
                child: Padding(
                  padding: const EdgeInsets.all(DATokens.spacingLarge),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.folder_off_outlined, size: 48, color: Colors.white30),
                        const SizedBox(height: DATokens.spacingMedium),
                        Text(
                          'No folders added yet',
                          style: typography.body.copyWith(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: folders.length,
                itemBuilder: (context, idx) {
                  final folder = folders[idx];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: DATokens.spacingSmall),
                    child: DACard(
                      child: ListTile(
                        leading: const Icon(Icons.folder_outlined, color: Colors.white70),
                        title: Text(
                          p.basename(folder),
                          style: typography.title.copyWith(fontSize: 14),
                        ),
                        subtitle: Text(
                          folder,
                          style: typography.body.copyWith(
                            color: colors.textSecondary,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () {
                            ref.read(localLibraryRepositoryProvider.notifier).removeFolder(folder);
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: DATokens.spacingLarge),

            // Settings Card
            Text(
              'SETTINGS',
              style: typography.caption.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: DATokens.spacingSmall),
            DACard(
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    activeColor: colors.primary,
                    title: Text(
                      'Auto Scan on Startup',
                      style: typography.title.copyWith(fontSize: 14),
                    ),
                    subtitle: Text(
                      'Automatically refresh directories when starting the application',
                      style: typography.body.copyWith(color: colors.textSecondary, fontSize: 11),
                    ),
                    value: state.autoScan,
                    onChanged: (val) {
                      ref.read(localLibraryRepositoryProvider.notifier).toggleAutoScan(val);
                    },
                  ),
                  const Divider(height: 1, color: Colors.white10),
                  ListTile(
                    leading: const Icon(Icons.refresh_outlined),
                    title: Text(
                      'Force Full Rescan',
                      style: typography.title.copyWith(fontSize: 14),
                    ),
                    subtitle: Text(
                      'Re-evaluate all files and rebuild metadata cache',
                      style: typography.body.copyWith(color: colors.textSecondary, fontSize: 11),
                    ),
                    trailing: isScanning
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : TextButton(
                            onPressed: () => ref
                                .read(localLibraryRepositoryProvider.notifier)
                                .scanFolders(),
                            child: const Text('Rescan'),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
