import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/services/device_memory_manager.dart';

/// A unified image loader widget that transparently supports both remote HTTP URLs
/// and local absolute file paths, with built-in placeholder fallback behavior
/// and memory-efficient bitmap downscaling for low-end (4GB RAM) devices.
class DAImage extends StatelessWidget {
  static String? cacheDirPath;
  static String? documentsDirPath;

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

    if (trackId != null && trackId!.isNotEmpty) {
      if (cacheDirPath != null) {
        final cachedArtwork = File('$cacheDirPath/da_tunes_cache/$trackId.jpg');
        if (cachedArtwork.existsSync()) {
          cleanUrl = cachedArtwork.path;
        }
      }
      if ((cleanUrl == null || cleanUrl.startsWith('http')) && documentsDirPath != null) {
        final downloadedArtwork = File('$documentsDirPath/da_tunes_downloads/$trackId.jpg');
        if (downloadedArtwork.existsSync()) {
          cleanUrl = downloadedArtwork.path;
        }
      }
    }

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

    if (cleanUrl == null || cleanUrl.isEmpty) {
      return fallback;
    }

    final hasNetwork = cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://');
    final hasAsset = cleanUrl.startsWith('assets/');

    final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 2.0;
    final int? targetCacheWidth = width != null ? DeviceMemoryManager.instance.getTargetCacheDimension(width, devicePixelRatio: dpr) : null;
    final int? targetCacheHeight = height != null ? DeviceMemoryManager.instance.getTargetCacheDimension(height, devicePixelRatio: dpr) : null;

    if (hasAsset) {
      return Image.asset(
        cleanUrl,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: targetCacheWidth,
        cacheHeight: targetCacheHeight,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (frame != null) return child;
          return fallback;
        },
        errorBuilder: (ctx, err, st) => fallback,
      );
    }

    if (hasNetwork) {
      return Image.network(
        cleanUrl,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: targetCacheWidth,
        cacheHeight: targetCacheHeight,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (frame != null) return child;
          return fallback;
        },
        errorBuilder: (ctx, err, st) {
          return errorBuilder?.call(ctx, err, st) ?? fallback;
        },
      );
    } else {
      // Local image file path
      final file = File(cleanUrl);
      if (file.existsSync()) {
        final int targetWidth = targetCacheWidth ?? DeviceMemoryManager.instance.getTargetCacheDimension(400, devicePixelRatio: dpr);
        final int targetHeight = targetCacheHeight ?? DeviceMemoryManager.instance.getTargetCacheDimension(400, devicePixelRatio: dpr);
        return Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          cacheWidth: targetWidth,
          cacheHeight: targetHeight,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (frame != null) return child;
            return fallback;
          },
          errorBuilder: (ctx, err, st) => fallback,
        );
      }
      return fallback;
    }
  }
}
