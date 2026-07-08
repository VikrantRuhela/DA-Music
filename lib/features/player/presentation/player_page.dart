import 'package:flutter/material.dart';
import '../../../shared/widgets/da_empty_state.dart';

class PlayerPage extends StatelessWidget {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: DAEmptyState(
          icon: Icons.music_note_outlined,
          title: 'Full Screen Player',
          description: 'Expanded playback view will be loaded here.',
        ),
      ),
    );
  }
}
