import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;

void main() {
  print('YoutubeApiClient values:');
  for (final value in yt.YoutubeApiClient.values) {
    print('  - $value');
  }
}
