import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../shared/providers/backend_providers.dart';

class GreetingWidget extends ConsumerStatefulWidget {
  const GreetingWidget({super.key});

  @override
  ConsumerState<GreetingWidget> createState() => _GreetingWidgetState();
}

class _GreetingWidgetState extends ConsumerState<GreetingWidget> {
  late Timer _timer;
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    // Check every 10 seconds to keep synchronized with the system clock
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        final now = DateTime.now();
        if (now.hour != _currentTime.hour || now.minute != _currentTime.minute) {
          setState(() {
            _currentTime = now;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _getGreetingPhrase(int hour) {
    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else if (hour >= 17 && hour < 22) {
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.daColors;
    final typography = context.daTypography;

    final session = ref.watch(sessionManagerProvider);
    final username = session.accountName ?? 'Voyager';
    final phrase = _getGreetingPhrase(_currentTime.hour);

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: DATokens.spacingLarge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$phrase,\n$username',
            style: typography.display.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: DATokens.spacingTiny),
          Text(
            'Ready to explore the soundscapes today?',
            style: typography.body.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
