import 'dart:io';
import 'package:flutter/material.dart';

/// A unified image loader widget that transparently supports both remote HTTP URLs
/// and local absolute file paths, with built-in placeholder fallback behavior.
class DAImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final String? trackId;
  final String? albumId;
  final String? artistId;
  final bool isTrack;

  const DAImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorBuilder,
    this.trackId,
    this.albumId,
    this.artistId,
    this.isTrack = true,
  });

  @override
  Widget build(BuildContext context) {
    var cleanUrl = url?.trim();
    if ((cleanUrl == null || cleanUrl.isEmpty) && isTrack) {
      cleanUrl = 'assets/images/da_placeholder.jpg';
    } else if (cleanUrl == 'assets/images/da_placeholder.jpg' && !isTrack) {
      cleanUrl = '';
    }

    final fallback = placeholder ?? Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: const Center(
        child: Icon(Icons.music_note_outlined, color: Colors.white30),
      ),
    );

    if (trackId != null) print('[ARTWORK] Track ID: $trackId');
    if (albumId != null) print('[ARTWORK] Album ID: $albumId');
    if (artistId != null) print('[ARTWORK] Artist ID: $artistId');
    print('[ARTWORK] Artwork URL: ${cleanUrl ?? "empty"}');

    if (cleanUrl == null || cleanUrl.isEmpty) {
      print('[ARTWORK] Placeholder Used');
      return fallback;
    }

    final hasNetwork = cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://');
    final hasAsset = cleanUrl.startsWith('assets/');

    if (hasAsset) {
      return Image.asset(
        cleanUrl,
        width: width,
        height: height,
        fit: fit,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (frame != null) {
            print('[ARTWORK] Image Loaded');
            print('[ARTWORK] Cache Hit');
            return child;
          }
          return fallback;
        },
        errorBuilder: (ctx, err, st) {
          print('[ARTWORK] Placeholder Used (Error loading asset)');
          return fallback;
        },
      );
    }

    if (hasNetwork) {
      return Image.network(
        cleanUrl,
        width: width,
        height: height,
        fit: fit,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (frame != null) {
            print('[ARTWORK] Image Loaded');
            print('[ARTWORK] Cache ${wasSynchronouslyLoaded ? "Hit" : "Miss"}');
            return child;
          }
          return fallback;
        },
        errorBuilder: (ctx, err, st) {
          print('[ARTWORK] Placeholder Used (Error loading network image)');
          return errorBuilder?.call(ctx, err, st) ?? fallback;
        },
      );
    } else {
      // Local image file path
      final file = File(cleanUrl);
      if (file.existsSync()) {
        final int targetCacheWidth = (width != null) ? (width! * 2).round() : 400;
        final int targetCacheHeight = (height != null) ? (height! * 2).round() : 400;
        return Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          cacheWidth: targetCacheWidth,
          cacheHeight: targetCacheHeight,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (frame != null) {
              print('[ARTWORK] Image Loaded');
              print('[ARTWORK] Cache ${wasSynchronouslyLoaded ? "Hit" : "Miss"}');
              return child;
            }
            return fallback;
          },
          errorBuilder: (ctx, err, st) {
            print('[ARTWORK] Placeholder Used (Error loading local file)');
            return fallback;
          },
        );
      }
      print('[ARTWORK] Placeholder Used (File does not exist)');
      return fallback;
    }
  }
}
