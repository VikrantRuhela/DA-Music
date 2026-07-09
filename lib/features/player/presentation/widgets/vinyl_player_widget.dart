import 'package:flutter/material.dart';
import 'immersive/vinyl_widget.dart';
import 'immersive/tonearm_widget.dart';

class VinylPlayerWidget extends StatelessWidget {
  const VinylPlayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: FittedBox(
        child: SizedBox(
          width: 460.0,
          height: 380.0,
          child: Stack(
            children: [
              // Platter / Record (left side: center at X=230, Y=190)
              Positioned(
                left: 70,
                top: 30,
                child: SizedBox(
                  width: 320.0,
                  height: 320.0,
                  child: VinylWidget(),
                ),
              ),

              // Tonearm assembly mounted on the right (pivot at X=380, Y=90)
              Positioned.fill(
                child: TonearmWidget(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
