import 'package:flutter/material.dart';
import '../../core/extensions/context_extensions.dart';
import '../../app/theme/tokens.dart';

class DASearchBar extends StatefulWidget {
  final String placeholder;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final bool readOnly;

  const DASearchBar({
    super.key,
    this.placeholder = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.readOnly = false,
  });

  @override
  State<DASearchBar> createState() => _DASearchBarState();
}

class _DASearchBarState extends State<DASearchBar> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.daColors;
    final typography = context.daTypography;

    final borderColor = _isFocused
        ? colors.primary
        : (_isHovered ? colors.textSecondary.withValues(alpha: 0.5) : colors.border);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: DATokens.durationFast,
        curve: DATokens.curveHover,
        decoration: BoxDecoration(
          color: _isFocused ? colors.surface : colors.surfaceCard,
          borderRadius: BorderRadius.circular(DATokens.radiusCircular),
          border: Border.all(
            color: borderColor,
            width: 1.5,
          ),
          boxShadow: _isFocused
              ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.15),
                    blurRadius: 12.0,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: DATokens.spacingMedium,
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_outlined,
              size: DATokens.iconMedium,
              color: _isFocused ? colors.primary : colors.textSecondary,
            ),
            const SizedBox(width: DATokens.spacingSmall),
            Expanded(
              child: TextField(
                focusNode: _focusNode,
                controller: _controller,
                readOnly: widget.readOnly,
                onTap: widget.onTap,
                onSubmitted: widget.onSubmitted,
                onChanged: (value) {
                  setState(() {});
                  if (widget.onChanged != null) widget.onChanged!(value);
                },
                style: typography.body.copyWith(color: colors.textPrimary),
                cursorColor: colors.primary,
                decoration: InputDecoration(
                  hintText: widget.placeholder,
                  hintStyle: typography.body.copyWith(color: colors.textSecondary.withValues(alpha: 0.7)),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: DATokens.spacingSmall + 4,
                  ),
                ),
              ),
            ),
            if (_controller.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _controller.clear();
                  if (widget.onChanged != null) widget.onChanged!('');
                  setState(() {});
                },
                child: Icon(
                  Icons.close_outlined,
                  size: DATokens.iconSmall,
                  color: colors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
