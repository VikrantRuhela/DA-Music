import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;

void main() async {
  final ytClient = yt.YoutubeExplode();
  try {
    print('Sending search query via YoutubeExplode...');
    final result = await ytClient.search.searchContent('trending Pop');
    print('Result found! Length: ${result.length}');
  } catch (e, stack) {
    print('Error: $e');
    print('Stack trace: $stack');
  } finally {
    ytClient.close();
  }
}
