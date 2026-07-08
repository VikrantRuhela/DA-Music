import 'package:flutter/material.dart';
import '../../core/extensions/context_extensions.dart';
import '../../app/theme/tokens.dart';

class DAIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final String? tooltip;
  final Color? color;
  final bool isSelected;

  const DAIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = DATokens.iconMedium,
    this.tooltip,
    this.color,
    this.isSelected = false,
  });

  @override
  State<DAIconButton> createState() => _DAIconButtonState();
}

class _DAIconButtonState extends State<DAIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.daColors;

    final defaultColor = widget.isSelected ? colors.primary : colors.textSecondary;
    final finalColor = widget.color ?? (_isHovered ? colors.textPrimary : defaultColor);

    Widget button = MouseRegion(
      cursor: widget.onPressed != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: DATokens.durationFast,
          curve: DATokens.curveHover,
          padding: const EdgeInsets.all(DATokens.spacingSmall),
          decoration: BoxDecoration(
            color: _isHovered ? colors.surfaceHover : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.icon,
            size: widget.size,
            color: finalColor,
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      button = Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }

    return button;
  }
}
