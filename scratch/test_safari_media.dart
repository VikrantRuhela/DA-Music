import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import 'dart:io';

Future<void> checkVideo(String title, String id) async {
  final ytClient = yt.YoutubeExplode();
  print('\n--- Checking Song: "$title" (ID: $id) ---');

  final clients = {
    'Safari': yt.YoutubeApiClient.safari,
    'MediaConnect': yt.YoutubeApiClient.mediaConnect,
  };

  for (final entry in clients.entries) {
    final clientName = entry.key;
    final clientType = entry.value;

    try {
      final manifest = await ytClient.videos.streamsClient.getManifest(
        id,
        ytClients: [clientType],
      );
      final audioStreams = manifest.audioOnly.where((s) => s.container.name == 'mp4').toList();
      if (audioStreams.isEmpty) {
        print('  $clientName: No MP4 audio streams.');
        continue;
      }
      final bestAudio = audioStreams.withHighestBitrate();
      final url = bestAudio.url.toString();

      // Test HTTP status of resolved stream
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      print('  $clientName: Status Code = ${response.statusCode}');
      client.close();
    } catch (e) {
      print('  $clientName: Error: $e');
    }
  }
  ytClient.close();
}

void main() async {
  await checkVideo('Imagine Dragons - Believer', 'Kx7B-XvmFtE');
}
