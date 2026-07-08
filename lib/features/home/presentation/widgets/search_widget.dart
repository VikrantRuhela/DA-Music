import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/da_search_bar.dart';
import '../../../../app/theme/tokens.dart';

class SearchWidget extends StatelessWidget {
  const SearchWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: DATokens.spacingLarge,
      ),
      child: DASearchBar(
        placeholder: 'Search your music...',
        onTap: () {
          context.go('/search');
        },
        onSubmitted: (query) {
          if (query.trim().isNotEmpty) {
            context.go('/search?q=${Uri.encodeComponent(query.trim())}');
          } else {
            context.go('/search');
          }
        },
      ),
    );
  }
}
