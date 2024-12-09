import 'package:flutter/material.dart';
import 'dart:math';

class AnimatedCounters extends StatefulWidget {
  final double height;
  final double width;
  final Color color1;
  final Color color2;
  final Color color3;

  const AnimatedCounters({
    super.key,
    this.height = 200,
    this.width = 2, // Reduced default width
    this.color1 = Colors.blue,
    this.color2 = Colors.green,
    this.color3 = Colors.red,
  });

  @override
  State<AnimatedCounters> createState() => _AnimatedCountersState();
}

class _AnimatedCountersState extends State<AnimatedCounters>
    with TickerProviderStateMixin {
  late List<AnimationController> controllers;
  late List<Animation<double>> animations;
  final random = Random();

  @override
  void initState() {
    super.initState();
    controllers = List.generate(
      3,
      (index) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 500 + random.nextInt(500)),
      ),
    );

    animations = controllers.map((controller) {
      return Tween<double>(begin: 0.2, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    // Start the animations
    for (var i = 0; i < controllers.length; i++) {
      _startRandomAnimation(i);
    }
  }

  void _startRandomAnimation(int index) {
    controllers[index].addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controllers[index].reverse();
      } else if (status == AnimationStatus.dismissed) {
        Future.delayed(
          Duration(milliseconds: random.nextInt(200)),
          () {
            if (mounted) controllers[index].forward();
          },
        );
      }
    });
    controllers[index].forward();
  }

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = [widget.color1, widget.color2, widget.color3];

    return SizedBox(
      height: widget.height,
      width: widget.width * 7,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(
          3,
          (index) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: AnimatedBuilder(
                animation: animations[index],
                builder: (context, child) {
                  return Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: widget.width,
                      height: widget.height * animations[index].value,
                      decoration: BoxDecoration(
                        color: colors[index],
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: colors[index].withOpacity(0.3),
                            blurRadius: 2,
                            spreadRadius: 0.5,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
