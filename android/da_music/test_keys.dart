import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final keys = [
    'AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30', // key in getHome
    'AIzaSyAOghZGza2MQSZkY_zfZ370N-PUdXEo8AI', // key in _fetchPlaylistDetails
  ];

  for (final key in keys) {
    print('Testing key: $key');
    try {
      final response = await http.post(
        Uri.parse('https://music.youtube.com/youtubei/v1/browse?key=$key&prettyPrint=false'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'x-youtube-client-name': '67',
          'x-youtube-client-version': '1.20260304.03.00',
          'x-origin': 'https://music.youtube.com',
        },
        body: jsonEncode({
          "context": {
            "client": {
              "clientName": "WEB_REMIX",
              "clientVersion": "1.20260304.03.00",
              "hl": "en",
              "gl": "US"
            }
          },
          "browseId": "FEmusic_home"
        }),
      );
      print('Status code: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('SUCCESS for key: $key!');
        final json = jsonDecode(response.body);
        print('Response keys: ${json.keys}');
      } else {
        print('FAILED for key: $key: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
      }
    } catch (e) {
      print('Error: $e');
    }
    print('-----------------------------------------');
  }
}
