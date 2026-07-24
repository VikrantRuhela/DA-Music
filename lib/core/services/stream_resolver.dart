import 'dart:async';
import 'package:flutter/material.dart';
import 'source_manager.dart';
import 'logger_service.dart';
import 'local_stream_proxy.dart';
import '../exceptions/playback_exceptions.dart';
import '../errors/failures.dart';
import '../../domain/entities/audio_stream.dart';
import '../../domain/entities/song.dart';
import '../../app/router/router.dart';

enum StreamQuality {
  auto,
  low,
  medium,
  high,
  highest,
}

/// Stream resolver bridging Pluggable Source Adapters and Playback Engine.
class StreamResolver {
  final SourceManager _sourceManager;
  final LocalStreamProxy? _proxy;
  final Map<String, AudioStream> _streamCache = {};

  static Song? lastResolvedSong;
  static String? lastResolvedUrl;

  StreamResolver(this._sourceManager, [this._proxy]);

  /// Extract audio URL and standardize payload, checking caching bounds.
  Future<AudioStream> resolve({
    required String trackId,
    required String providerId,
    StreamQuality quality = StreamQuality.auto,
  }) async {
    final startTime = DateTime.now();
    DALogger.info('StreamResolver: Resolving stream for track "$trackId" (quality: ${quality.name})');

    if (providerId == 'local') {
      final localStream = AudioStream(
        id: trackId,
        providerId: providerId,
        streamUrl: trackId,
        mimeType: 'audio/mpeg',
        bitrate: 320,
        duration: const Duration(minutes: 3),
        expiresAt: DateTime.now().add(const Duration(days: 365)),
        headers: const {},
        quality: quality.name,
        codec: 'MP3',
        isLive: false,
        isCached: true,
      );
      lastResolvedUrl = trackId;
      return localStream;
    }

    // Return cache if valid
    final cached = _streamCache[trackId];
    if (cached != null && !cached.isExpired) {
      DALogger.info('StreamResolver: Reusing cached stream for track "$trackId"');
      lastResolvedSong = await _sourceManager.getSong(trackId);
      lastResolvedUrl = cached.streamUrl;
      return cached;
    }

    String title = 'Unknown Title';
    try {
      final song = await _sourceManager.getSong(trackId);
      title = song.title;
      lastResolvedSong = song;
    } catch (_) {}

    AudioStream stream;
    try {
      final raw = await _sourceManager.getAudioStream(trackId);

      final resolvedUrl = _proxy != null && _proxy.port > 0
          ? 'http://127.0.0.1:${_proxy.port}/stream?url=${Uri.encodeComponent(raw.streamUrl)}'
          : raw.streamUrl;

      stream = AudioStream(
        id: trackId,
        providerId: providerId,
        streamUrl: resolvedUrl,
        mimeType: raw.mimeType,
        bitrate: raw.bitrate,
        duration: raw.duration,
        expiresAt: raw.expiresAt,
        headers: raw.headers,
        quality: quality.name,
        codec: raw.codec,
        isLive: raw.isLive,
        isCached: false,
      );

      _validateStream(stream);
      lastResolvedUrl = stream.streamUrl;

      // Cache it
      _streamCache[trackId] = stream.copyWith(isCached: true);

      final duration = DateTime.now().difference(startTime).inMilliseconds;
      DALogger.info('StreamResolver: Resolved stream in ${duration}ms');
      return stream;
    } catch (e, stack) {
      String reason = 'Stream resolution failed in YouTube.';
      final errorMsg = e.toString();
      if (errorMsg.contains('LiveStreamException') || errorMsg.contains('live')) {
        reason = 'Live streams are not supported.';
      } else if (errorMsg.contains('VideoUnplayableException') && errorMsg.contains('confirm you’re not a bot')) {
        reason = 'Sign-in verification required / bot check.';
      } else if (errorMsg.contains('VideoUnavailableException') || errorMsg.contains('private') || errorMsg.contains('unavailable')) {
        reason = 'This song is private or unavailable.';
      } else if (errorMsg.contains('login') || errorMsg.contains('age')) {
        reason = 'Age-restricted content is not supported.';
      } else if (errorMsg.contains('Invalid argument') || errorMsg.contains('invalid id')) {
        reason = 'Invalid YouTube Video ID metadata.';
      }

      // ignore: avoid_print
      print('=== SKIPPED SONG DIAGNOSTIC ===');
      // ignore: avoid_print
      print('- Song Title: $title');
      // ignore: avoid_print
      print('- Song ID: $trackId');
      // ignore: avoid_print
      print('- Provider ID: $providerId');
      // ignore: avoid_print
      print('- Resolved Stream URL: N/A (Resolution Failed)');
      // ignore: avoid_print
      print('- Exception from StreamResolver (if any): $e');
      // ignore: avoid_print
      print('- Exception from the audio backend (if any): None');
      // ignore: avoid_print
      print('- Exact reason why playback was skipped: $reason');
      // ignore: avoid_print
      print('===============================');

      // Display SnackBar to the user
      final context = rootNavigatorKey.currentContext;
      if (context != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot play "$title": $reason'),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 4),
            ),
          );
        });
      }

      DALogger.error('StreamResolver: Failed resolving stream for "$trackId"', e, stack);
      throw StreamFailure(
        message: 'Failed to resolve stream for playback: $reason',
        exception: e,
        stackTrace: stack,
      );
    }
  }

  void _validateStream(AudioStream stream) {
    if (stream.streamUrl.isEmpty) {
      throw const SourceException('Resolved stream URL target is empty.', 'Empty URL');
    }
    final uri = Uri.tryParse(stream.streamUrl);
    if (uri == null || !uri.hasScheme) {
      throw const SourceException('Resolved stream URL scheme is invalid.', 'Malformed URL');
    }
  }

  void clearCache() {
    _streamCache.clear();
    DALogger.info('StreamResolver: Cache cleared.');
  }
}
