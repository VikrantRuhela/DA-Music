import 'package:flutter/material.dart';
import '../../core/extensions/context_extensions.dart';
import '../../app/theme/tokens.dart';

class DAButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isSecondary;
  final IconData? icon;

  const DAButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isSecondary = false,
    this.icon,
  });

  @override
  State<DAButton> createState() => _DAButtonState();
}

class _DAButtonState extends State<DAButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.daColors;
    final typography = context.daTypography;

    final backgroundColor = widget.isSecondary
        ? (_isHovered ? colors.surfaceHover : colors.surfaceCard)
        : (_isHovered ? colors.primary.withValues(alpha: 0.9) : colors.primary);

    final textColor = widget.isSecondary ? colors.textPrimary : Colors.white;

    return MouseRegion(
      cursor: widget.onPressed != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: DATokens.durationFast,
          curve: DATokens.curveHover,
          padding: const EdgeInsets.symmetric(
            horizontal: DATokens.spacingLarge,
            vertical: DATokens.spacingSmall + 2,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(DATokens.radiusMedium),
            border: Border.all(
              color: widget.isSecondary ? colors.border : Colors.transparent,
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: DATokens.iconSmall,
                  color: textColor,
                ),
                const SizedBox(width: DATokens.spacingSmall),
              ],
              Text(
                widget.label,
                style: typography.title.copyWith(
                  color: textColor,
                  fontSize: 14.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
