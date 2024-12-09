import 'package:flutter/material.dart';

class AudioVisualizer extends StatelessWidget {
  final List<double> audioLevels;
  final double visualizerHeight;

  const AudioVisualizer({
    super.key,
    required this.audioLevels,
    required this.visualizerHeight,
  });

  Color _getColor(double level) {
    // Create a more gradual color transition
    if (level > 0.8) {
      return Colors.red.withOpacity(0.7);
    } else if (level > 0.6) {
      return Colors.orange.withOpacity(0.7);
    } else if (level > 0.4) {
      return Colors.yellow.withOpacity(0.7);
    } else if (level > 0.2) {
      return Colors.green.withOpacity(0.7);
    } else {
      return Colors.blue.withOpacity(0.7);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: visualizerHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          audioLevels.length,
          (index) {
            final level = audioLevels[index];
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 50),
                  curve: Curves.easeInOut,
                  height:
                      (level * visualizerHeight).clamp(5.0, visualizerHeight),
                  decoration: BoxDecoration(
                    color: _getColor(level),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: _getColor(level).withOpacity(0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
