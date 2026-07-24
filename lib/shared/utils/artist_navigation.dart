import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/backend_providers.dart';

/// Dynamically search and resolve an artist's name to their Channel ID, then navigate.
Future<void> navigateToArtistByName(BuildContext context, WidgetRef ref, String name) async {
  if (name.isEmpty ||
      name.toLowerCase() == 'unknown artist' ||
      name.toLowerCase() == 'various artists' ||
      name.toLowerCase() == 'youtube') {
    return;
  }
  
  try {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Resolving artist "$name"...'),
          duration: const Duration(milliseconds: 800),
          backgroundColor: Colors.indigo,
        ),
      );
    }

    final sourceManager = ref.read(sourceManagerProvider);
    final artists = await sourceManager.searchArtists(name);
    
    if (artists.isNotEmpty) {
      final artistId = artists.first.id;
      if (context.mounted) {
        context.push('/artist/$artistId');
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not resolve artist "$name"'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  } catch (e) {
    debugPrint('Failed to navigate to artist by name: $e');
  }
}
