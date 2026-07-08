import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import 'dart:convert';
import 'dart:io';

void main() async {
  final albumId = 'MPREb_WOqUMNyA4PV';
  final client = HttpClient();
  try {
    const apiKey = 'AIzaSyAOghZGza2MQSZkY_zfZ370N-PUdXEo8AI';
    final url = Uri.parse('https://music.youtube.com/youtubei/v1/browse?key=$apiKey');
    
    final request = await client.postUrl(url);
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
    
    final payload = {
      'browseId': albumId,
      'context': {
        'client': {
          'clientName': 'WEB_REMIX',
          'clientVersion': '1.20260707.01.00',
          'hl': 'en',
          'gl': 'US',
        }
      }
    };

    request.write(json.encode(payload));
    final responseObj = await request.close();
    final rawBody = await responseObj.transform(utf8.decoder).join();
    final response = json.decode(rawBody) as Map<String, dynamic>;

    final contents = response['contents'];
    if (contents != null) {
      final twoCol = contents['twoColumnBrowseResultsRenderer'];
      if (twoCol != null) {
        final secondaryContents = twoCol['secondaryContents'];
        if (secondaryContents != null) {
          final sectionList = secondaryContents['sectionListRenderer'];
          final contentsList = sectionList['contents'] as List?;
          if (contentsList != null && contentsList.isNotEmpty) {
            final shelf = contentsList[0]['musicPlaylistShelfRenderer'] ?? contentsList[0]['musicShelfRenderer'];
            final trackItems = shelf?['contents'] as List?;
            if (trackItems != null) {
              print('Track Items count: ${trackItems.length}');
              for (var i = 0; i < trackItems.length; i++) {
                final item = trackItems[i]['musicResponsiveListItemRenderer'];
                if (item == null) continue;
                final trackTitle = item['flexColumns']?[0]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs']?[0]?['text'];
                final videoId = item['playlistItemData']?['videoId'] ?? item['onTap']?['watchEndpoint']?['videoId'];
                print('  Track $i: Title = "$trackTitle", videoId = "$videoId"');
              }
            } else {
              print('shelf contents is null!');
            }
          }
        }
      }
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    client.close();
  }
}
