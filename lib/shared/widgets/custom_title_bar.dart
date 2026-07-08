import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../../core/extensions/context_extensions.dart';
import '../../app/theme/tokens.dart';

class CustomTitleBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomTitleBar({super.key});

  @override
  State<CustomTitleBar> createState() => _CustomTitleBarState();

  @override
  Size get preferredSize => const Size.fromHeight(32.0);
}

class _CustomTitleBarState extends State<CustomTitleBar> {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    _checkMaximizedState();
  }

  Future<void> _checkMaximizedState() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      final val = await windowManager.isMaximized();
      if (mounted) setState(() => _isMaximized = val);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux)) {
      return const SizedBox.shrink();
    }

    final colors = context.daColors;
    final typography = context.daTypography;

    return GestureDetector(
      onDoubleTap: () async {
        final val = await windowManager.isMaximized();
        if (val) {
          await windowManager.unmaximize();
        } else {
          await windowManager.maximize();
        }
        setState(() => _isMaximized = !val);
      },
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(
        height: 32.0,
        color: colors.background,
        child: Row(
          children: [
            const SizedBox(width: DATokens.spacingMedium),
            Icon(
              Icons.album_outlined,
              size: 16.0,
              color: colors.primary,
            ),
            const SizedBox(width: DATokens.spacingSmall),
            Text(
              'DA Music',
              style: typography.body.copyWith(
                fontSize: 12.0,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                _TitleBarButton(
                  icon: Icons.minimize_outlined,
                  onPressed: () => windowManager.minimize(),
                ),
                _TitleBarButton(
                  icon: _isMaximized ? Icons.filter_none_outlined : Icons.crop_square_outlined,
                  onPressed: () async {
                    final val = await windowManager.isMaximized();
                    if (val) {
                      await windowManager.unmaximize();
                    } else {
                      await windowManager.maximize();
                    }
                    setState(() => _isMaximized = !val);
                  },
                ),
                _TitleBarButton(
                  icon: Icons.close_outlined,
                  isClose: true,
                  onPressed: () => windowManager.close(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TitleBarButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isClose;

  const _TitleBarButton({
    required this.icon,
    required this.onPressed,
    this.isClose = false,
  });

  @override
  State<_TitleBarButton> createState() => _TitleBarButtonState();
}

class _TitleBarButtonState extends State<_TitleBarButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.daColors;

    final hoverColor = widget.isClose
        ? Colors.red.shade600
        : colors.surfaceHover;

    final iconColor = _isHovered
        ? (widget.isClose ? Colors.white : colors.textPrimary)
        : colors.textSecondary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: DATokens.durationFast,
          curve: DATokens.curveHover,
          width: 46.0,
          height: 32.0,
          color: _isHovered ? hoverColor : Colors.transparent,
          child: Icon(
            widget.icon,
            size: 14.0,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}
