import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

void main() {
  HttpOverrides.global = null;

  test('Check raw title of UNk6LTZYokk', () async {
    final ytClient = yt.YoutubeExplode();
    final video = await ytClient.videos.get('UNk6LTZYokk');
    print('Raw Title: ${video.title}');
    ytClient.close();
  }, skip: 'YouTube rate limiting');
}
