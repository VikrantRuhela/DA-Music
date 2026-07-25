import 'dart:io';
import 'logger_service.dart';
import 'stream_resolver.dart';

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
    final trackId = request.uri.queryParameters['trackId'];
    if (targetUrl == null || targetUrl.isEmpty) {
      request.response.statusCode = HttpStatus.badRequest;
      await request.response.close();
      return;
    }

    final targetUri = Uri.parse(targetUrl);
    final client = HttpClient();

    // Try forcing IPv4 connection first (crucial to bypass IPv6 CDN blocks on cellular networks like Jio/Airtel)
    client.connectionFactory = (Uri url, String? proxyHost, int? proxyPort) async {
      final host = proxyHost ?? url.host;
      final port = proxyPort ?? (url.port != 0 ? url.port : (url.scheme == 'https' ? 443 : 80));
      
      Socket socket;
      try {
        // Enforce a tight 1.5s timeout on standard connection so we fail-fast on blackholed IPv6 routes
        socket = await Socket.connect(host, port).timeout(const Duration(milliseconds: 1500));
      } catch (_) {
        try {
          final addresses = await InternetAddress.lookup(host, type: InternetAddressType.IPv4);
          if (addresses.isNotEmpty) {
            socket = await Socket.connect(addresses.first, port);
          } else {
            rethrow;
          }
        } catch (e2) {
          socket = await Socket.connect(host, port);
        }
      }

      if (url.scheme.toLowerCase() == 'https') {
        final secureSocket = await SecureSocket.secure(socket, host: host);
        return ConnectionTask.fromSocket(Future.value(secureSocket), () {});
      }
      return ConnectionTask.fromSocket(Future.value(socket), () {});
    };

    int httpStatusCode = -1;
    List<String> redirectChain = [];
    String cdnEndpoint = targetUri.host;
    String networkProtocol = 'IPv4';
    String failureStage = 'Connection';
    String exceptionDetails = '';
    const int timeoutMs = 15000;
    const int retryCount = 3;

    try {
      HttpClientResponse? forwardRes;
      
      for (int attempt = 1; attempt <= retryCount; attempt++) {
        try {
          failureStage = 'Opening connection (Attempt $attempt)';
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

          failureStage = 'Waiting for response (Attempt $attempt)';
          forwardRes = await forwardReq.close()
              .timeout(const Duration(milliseconds: timeoutMs));
          
          httpStatusCode = forwardRes.statusCode;
          redirectChain = forwardRes.redirects.map((r) => r.location.toString()).toList();

          if (httpStatusCode >= 400) {
            throw HttpException('Server returned status code $httpStatusCode');
          }
          
          // Copy status code and headers back to client
          request.response.statusCode = forwardRes.statusCode;
          forwardRes.headers.forEach((name, values) {
            for (final val in values) {
              request.response.headers.add(name, val);
            }
          });

          failureStage = 'Streaming payload';
          await request.response.addStream(forwardRes);
          break; // Exit retry loop on success
        } catch (e) {
          exceptionDetails = e.toString();
          
          // Determine if we should fail or retry
          final isPeerClosed = e is SocketException && exceptionDetails.contains('Connection closed by peer');
          if (attempt == retryCount || isPeerClosed) {
            if (!isPeerClosed) {
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

            // Invalidate cache immediately on failure so fresh URL is fetched on retry
            if (trackId != null && trackId.isNotEmpty) {
              StreamResolver.invalidate(trackId);
            }
            rethrow;
          }
          
          DALogger.warning('LocalStreamProxy: Attempt $attempt failed, retrying in ${attempt * 400}ms... (Error: $e)');
          await Future.delayed(Duration(milliseconds: attempt * 400));
        }
      }
    } catch (e) {
      // Errors already reported in loop
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
