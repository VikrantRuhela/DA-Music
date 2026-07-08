import 'package:da_music/core/services/youtube_music_adapter.dart';
import 'package:da_music/core/services/stream_resolver.dart';
import 'package:da_music/core/services/source_manager.dart';
import 'dart:io';

void main() async {
  print('--- Testing Real StreamResolver Resolution and HTTP Status Check ---');
  final adapter = YouTubeMusicAdapter();
  await adapter.initialize();

  final sourceManager = SourceManager();
  sourceManager.registerAdapter(adapter);
  sourceManager.selectSource('youtube_music');

  final resolver = StreamResolver(sourceManager);

  // Let's resolve "Imagine Dragons - Believer" (ID: Kx7B-XvmFtE)
  const trackId = 'Kx7B-XvmFtE';
  print('Resolving track $trackId...');
  try {
    final stream = await resolver.resolve(trackId: trackId, providerId: 'youtube_music');
    print('SUCCESS: Stream resolved and HTTP check passed!');
    print('Stream URL: ${stream.streamUrl}');
  } catch (e) {
    print('FAILED: Stream resolver threw exception: $e');
  } finally {
    await adapter.dispose();
  }
}
