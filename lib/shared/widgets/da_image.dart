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

  const DAImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final cleanUrl = url;
    final fallback = placeholder ?? Container(
      width: width,
      height: height,
      color: Colors.white10,
      child: const Icon(Icons.music_note_outlined, color: Colors.white30),
    );

    if (cleanUrl == null || cleanUrl.trim().isEmpty) {
      return fallback;
    }

    final hasNetwork = cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://');

    if (hasNetwork) {
      return Image.network(
        cleanUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: errorBuilder ?? (ctx, err, st) => fallback,
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
          errorBuilder: (ctx, err, st) => fallback,
        );
      }
      return fallback;
    }
  }
}
