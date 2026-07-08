import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import 'dart:io';

Future<void> checkVideo(String title, String id) async {
  final ytClient = yt.YoutubeExplode();
  print('\n--- Checking Song: "$title" (ID: $id) with androidSdkless ---');

  try {
    final manifest = await ytClient.videos.streamsClient.getManifest(
      id,
      ytClients: [yt.YoutubeApiClient.androidSdkless],
    );
    final audioStreams = manifest.audioOnly.where((s) => s.container.name == 'mp4').toList();
    if (audioStreams.isEmpty) {
      print('  androidSdkless: No MP4 audio streams.');
      return;
    }
    final bestAudio = audioStreams.withHighestBitrate();
    final url = bestAudio.url.toString();

    // Test HTTP status of resolved stream
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    print('  androidSdkless: Status Code = ${response.statusCode}');
    client.close();
  } catch (e) {
    print('  androidSdkless: Error: $e');
  }
  ytClient.close();
}

void main() async {
  await checkVideo('Imagine Dragons - Believer', 'Kx7B-XvmFtE');
  await checkVideo('Ed Sheeran - Perfect', '1UQzJfsT2eo');
  await checkVideo('Adele - Hello', 'YQHsXMglC9A');
}
