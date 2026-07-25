import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;

class InterceptingClient extends http.BaseClient {
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    print('Sending request: ${request.url}');
    final response = await _inner.send(request);
    final urlStr = request.url.toString();
    if (urlStr.contains('youtubei/v1/search') || urlStr.contains('results?search_query=')) {
      print('Intercepting URL: $urlStr');
      print('Original status: ${response.statusCode}');
      print('Original headers: ${response.headers}');
      final bytes = await response.stream.toBytes();
      var body = utf8.decode(bytes);
      print('Decoded body length: ${body.length}');
      body = body.replaceAll('"viewCountText":{"runs":', '"viewCountText":{"simpleText":"0 views","_runs":');
      final modifiedBytes = utf8.encode(body);
      
      // Let's remove content-encoding: gzip if present, because the modified stream is uncompressed
      final headers = Map<String, String>.from(response.headers);
      headers.remove('content-encoding');
      headers['content-length'] = modifiedBytes.length.toString();

      return http.StreamedResponse(
        Stream.value(modifiedBytes),
        response.statusCode,
        contentLength: modifiedBytes.length,
        request: request,
        headers: headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
      );
    }
    return response;
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}

void main() async {
  final ytClient = yt.YoutubeExplode(httpClient: yt.YoutubeHttpClient(InterceptingClient()));
  try {
    print('Sending search via YoutubeExplode with InterceptingClient...');
    final result = await ytClient.search.searchContent('trending Pop');
    print('Result found! Length: ${result.length}');
  } catch (e, stack) {
    print('Error: $e');
    print('Stack trace: $stack');
  } finally {
    ytClient.close();
  }
}
