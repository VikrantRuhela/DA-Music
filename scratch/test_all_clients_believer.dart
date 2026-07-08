import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import 'dart:io';

Future<void> checkClient(String name, yt.YoutubeApiClient client) async {
  final ytClient = yt.YoutubeExplode();
  try {
    final manifest = await ytClient.videos.streamsClient.getManifest(
      'Kx7B-XvmFtE',
      ytClients: [client],
    );
    final audioStreams = manifest.audioOnly.where((s) => s.container.name == 'mp4').toList();
    if (audioStreams.isEmpty) {
      print('  $name: Resolved successfully but no MP4 audio streams.');
      return;
    }
    final bestAudio = audioStreams.withHighestBitrate();
    final url = bestAudio.url.toString();

    final httpClient = HttpClient();
    final request = await httpClient.getUrl(Uri.parse(url));
    final response = await request.close();
    print('  $name: Resolved! HTTP Status = ${response.statusCode}');
    httpClient.close();
  } catch (e) {
    print('  $name: Failed with exception: $e');
  } finally {
    ytClient.close();
  }
}

void main() async {
  print('--- Checking all YouTube API Clients for Believer ---');
  await checkClient('iOS', yt.YoutubeApiClient.ios);
  await checkClient('Android', yt.YoutubeApiClient.android);
  await checkClient('Android Sdkless', yt.YoutubeApiClient.androidSdkless);
  await checkClient('Android Music', yt.YoutubeApiClient.androidMusic);
  await checkClient('Android VR', yt.YoutubeApiClient.androidVr);
  await checkClient('Safari', yt.YoutubeApiClient.safari);
  await checkClient('TV', yt.YoutubeApiClient.tv);
  await checkClient('MediaConnect', yt.YoutubeApiClient.mediaConnect);
  await checkClient('MWEB', yt.YoutubeApiClient.mweb);
  await checkClient('WebCreator', yt.YoutubeApiClient.webCreator);
  await checkClient('TVSimplyEmbedded', yt.YoutubeApiClient.tvSimplyEmbedded);
}
