import 'dart:io';
import 'logger_service.dart';

class LocalStreamProxy {
  HttpServer? _server;
  int get port => _server?.port ?? 0;

  Future<void> start() async {
    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _server!.listen(_handleRequest);
      DALogger.info('LocalStreamProxy: Started on http://127.0.0.1:$port');
    } catch (e, stack) {
      DALogger.error('LocalStreamProxy: Failed to start server', e, stack);
    }
  }

  void _handleRequest(HttpRequest request) async {
    if (request.uri.path != '/stream') {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    final targetUrl = request.uri.queryParameters['url'];
    if (targetUrl == null || targetUrl.isEmpty) {
      request.response.statusCode = HttpStatus.badRequest;
      await request.response.close();
      return;
    }

    final targetUri = Uri.parse(targetUrl);
    final client = HttpClient();

    // Force IPv4 for proxy client requests
    client.connectionFactory = (Uri url, String? proxyHost, int? proxyPort) async {
      final host = proxyHost ?? url.host;
      final port = proxyPort ?? (url.port != 0 ? url.port : (url.scheme == 'https' ? 443 : 80));
      try {
        final addresses = await InternetAddress.lookup(host, type: InternetAddressType.IPv4);
        if (addresses.isNotEmpty) {
          return await Socket.startConnect(addresses.first, port);
        }
      } catch (_) {}
      return await Socket.startConnect(host, port);
    };

    int httpStatusCode = -1;
    List<String> redirectChain = [];
    String cdnEndpoint = targetUri.host;
    String networkProtocol = 'IPv4';
    String failureStage = 'Connection';
    String exceptionDetails = '';
    const int timeoutMs = 15000;

    try {
      failureStage = 'Opening connection';
      final forwardReq = await client.openUrl(request.method, targetUri)
          .timeout(const Duration(milliseconds: timeoutMs));

      // Copy headers from client request to forward request
      request.headers.forEach((name, values) {
        if (name.toLowerCase() != 'host') {
          for (final val in values) {
            forwardReq.headers.add(name, val);
          }
        }
      });

      // Set browser user-agent to avoid 403 Forbidden
      forwardReq.headers.set(
        'User-Agent',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      );

      failureStage = 'Waiting for response';
      final forwardRes = await forwardReq.close()
          .timeout(const Duration(milliseconds: timeoutMs));
      httpStatusCode = forwardRes.statusCode;
      redirectChain = forwardRes.redirects.map((r) => r.location.toString()).toList();

      // Copy status code and headers back to client
      request.response.statusCode = forwardRes.statusCode;
      forwardRes.headers.forEach((name, values) {
        for (final val in values) {
          request.response.headers.add(name, val);
        }
      });

      failureStage = 'Streaming payload';
      await request.response.addStream(forwardRes);
    } catch (e) {
      exceptionDetails = e.toString();
      // Only log diagnostics if the request didn't fail due to standard player client cancellation/seek disconnects
      if (e is! SocketException || !exceptionDetails.contains('Connection closed by peer')) {
        DALogger.error('=== STREAM PROXY FAILURE DIAGNOSTIC ===');
        DALogger.error('- Target CDN Endpoint: $cdnEndpoint');
        DALogger.error('- HTTP Status Code: $httpStatusCode');
        DALogger.error('- Redirect Chain: $redirectChain');
        DALogger.error('- Network Protocol: $networkProtocol');
        DALogger.error('- Failure Stage: $failureStage');
        DALogger.error('- Exception Details: $exceptionDetails');
        DALogger.error('- Timeout Setting: ${timeoutMs}ms');
        DALogger.error('=======================================');
      }
    } finally {
      try {
        await request.response.close();
      } catch (_) {}
      client.close();
    }
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    DALogger.info('LocalStreamProxy: Stopped');
  }
}
