import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import 'dart:io';

Future<void> checkVideo(String title, String id) async {
  final ytClient = yt.YoutubeExplode();
  print('\n--- Checking Song: "$title" (ID: $id) ---');

  final clients = {
    'Default': null,
    'Android VR': yt.YoutubeApiClient.androidVr,
    'TV': yt.YoutubeApiClient.tv,
    'MWEB': yt.YoutubeApiClient.mweb,
    'iOS': yt.YoutubeApiClient.ios,
  };

  for (final entry in clients.entries) {
    final clientName = entry.key;
    final clientType = entry.value;

    try {
      final manifest = await ytClient.videos.streamsClient.getManifest(
        id,
        ytClients: clientType != null ? [clientType] : null,
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
  // Test a working song vs a skipped song if possible
  // Let's test a few common songs
  await checkVideo('Imagine Dragons - Believer', 'Kx7B-XvmFtE');
  await checkVideo('Ed Sheeran - Perfect', '1UQzJfsT2eo');
  await checkVideo('Adele - Hello', 'YQHsXMglC9A');
}
