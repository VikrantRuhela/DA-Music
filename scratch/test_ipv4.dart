import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import 'dart:io';
import 'package:http/io_client.dart' as io_http;

void main() async {
  print('--- Forcing IPv4 Connection Factory Diagnosis ---');
  
  final nativeClient = HttpClient();
  nativeClient.connectionFactory = (uri, proxyHost, proxyPort) {
    final host = uri.host;
    final port = uri.port;
    print('Resolving socket connection for $host to IPv4...');
    return InternetAddress.lookup(host, type: InternetAddressType.IPv4).then((addresses) {
      if (addresses.isEmpty) {
        throw SocketException('Could not resolve IPv4 address for host: $host');
      }
      final targetAddress = addresses.first;
      print('Connecting to target IPv4 address: ${targetAddress.address}');
      return Socket.startConnect(targetAddress, port);
    });
  };

  final httpIoClient = io_http.IOClient(nativeClient);
  final ytHttpClient = yt.YoutubeHttpClient(httpIoClient);
  final ytClient = yt.YoutubeExplode(httpClient: ytHttpClient);

  final id = '1UQzJfsT2eo'; // Perfect - Ed Sheeran
  print('Resolving streams for video: $id');
  try {
    final manifest = await ytClient.videos.streamsClient.getManifest(id);
    final mp4Streams = manifest.audioOnly.where((s) => s.container.name == 'mp4');
    if (mp4Streams.isEmpty) {
      print('No MP4 audio streams found!');
      return;
    }
    final bestMp4 = mp4Streams.withHighestBitrate();
    final url = bestMp4.url.toString();
    print('Resolved URL: $url');

    // Make an HTTP request using the same IPv4 client
    print('Testing HTTP fetch using IPv4 client...');
    final request = await nativeClient.getUrl(Uri.parse(url));
    final response = await request.close();
    print('HTTP Response Status Code: ${response.statusCode}');
    if (response.statusCode == 403) {
      print('FAILED: YouTube blocked the request with 403 Forbidden!');
    } else {
      print('SUCCESS: HTTP fetch returned status code ${response.statusCode}!');
    }
  } catch (e, stack) {
    print('Error: $e');
    print(stack);
  } finally {
    ytClient.close();
  }
}
