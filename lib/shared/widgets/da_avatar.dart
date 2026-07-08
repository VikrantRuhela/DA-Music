import 'package:flutter/material.dart';
import '../../core/extensions/context_extensions.dart';
import '../../app/theme/tokens.dart';

class DAAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final IconData defaultIcon;

  const DAAvatar({
    super.key,
    this.imageUrl,
    this.size = DATokens.iconXLarge,
    this.defaultIcon = Icons.person_outline,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.daColors;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.surfaceHover,
        shape: BoxShape.circle,
        border: Border.all(
          color: colors.border,
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildPlaceholder(colors),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: SizedBox(
                    width: size * 0.4,
                    height: size * 0.4,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                    ),
                  ),
                );
              },
            )
          : _buildPlaceholder(colors),
    );
  }

  Widget _buildPlaceholder(dynamic colors) {
    return Center(
      child: Icon(
        defaultIcon,
        size: size * 0.45,
        color: colors.textSecondary,
      ),
    );
  }
}
