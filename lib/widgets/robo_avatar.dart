import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme.dart';

enum RoboState { idle, listening, thinking, speaking }

class RoboAvatar extends StatefulWidget {
  final RoboState state;

  const RoboAvatar({Key? key, required this.state}) : super(key: key);

  @override
  State<RoboAvatar> createState() => _RoboAvatarState();
}

class _RoboAvatarState extends State<RoboAvatar> with TickerProviderStateMixin {
  late AnimationController _mainController;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    // Main animation for breathing, speaking, thinking
    _mainController = AnimationController(
       vsync: this,
       duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        
        // Define dynamic properties based on state
        Color glowColor = Colors.transparent;
        double headScale = 1.0;
        double imageBrightness = 1.0;

        switch (widget.state) {
          case RoboState.idle:
            headScale = 1.0 + (_mainController.value * 0.02);
            glowColor = Colors.blueAccent.withOpacity(0.15);
            break;
            
          case RoboState.listening:
            headScale = 1.05 + (_mainController.value * 0.03);
            glowColor = Colors.greenAccent.withOpacity(0.5);
            imageBrightness = 1.1;
            break;
            
          case RoboState.thinking:
            headScale = 1.0;
            glowColor = Colors.orangeAccent.withOpacity(0.4);
            // subtle rotating tilt when thinking
            break;
            
          case RoboState.speaking:
            headScale = 1.0 + (_mainController.value * 0.04);
            glowColor = Colors.cyanAccent.withOpacity(0.6);
            // Image pulses brightly when speaking
            imageBrightness = 1.0 + (math.sin(_mainController.value * math.pi * 4).abs() * 0.2);
            break;
        }

        Widget avatarContainer = Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
             shape: BoxShape.circle,
             color: Theme.of(context).cardColor,
             image: const DecorationImage(
               image: AssetImage('assets/images/avatar.png'),
               fit: BoxFit.cover,
             ),
             boxShadow: [
               BoxShadow(
                 color: glowColor,
                 blurRadius: 35,
                 spreadRadius: 10,
               ),
               const BoxShadow(
                 color: Colors.black12,
                 blurRadius: 15,
                 offset: Offset(0, 8),
               )
             ],
             border: Border.all(
               color: glowColor.withOpacity(0.8), 
               width: 3
             ),
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Simulated lip sync / holographic voice wave over the mouth
              if (widget.state == RoboState.speaking)
                Positioned(
                  bottom: 30, // Positioning directly over the lower mouth area
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      // Create an alternating wave effect using sine and time
                      double waveHeight = 8.0 + (math.sin((_mainController.value * math.pi * 8) + index) * 6).abs();
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2.0),
                        width: 4,
                        height: waveHeight,
                        decoration: BoxDecoration(
                          color: Colors.cyanAccent,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyanAccent.withOpacity(0.6),
                              blurRadius: 4,
                              spreadRadius: 1,
                            )
                          ],
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        );

        // Apply a color filter for the brightness pulse during speaking/listening
        if (imageBrightness != 1.0) {
           avatarContainer = ColorFiltered(
             colorFilter: ColorFilter.matrix([
               imageBrightness, 0, 0, 0, 0,
               0, imageBrightness, 0, 0, 0,
               0, 0, imageBrightness, 0, 0,
               0, 0, 0, 1, 0,
             ]),
             child: avatarContainer,
           );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Transform.scale(
            scale: headScale,
            child: widget.state == RoboState.thinking 
               ? Transform.rotate(
                   angle: math.sin(_mainController.value * math.pi * 2) * 0.05,
                   child: avatarContainer,
                 )
               : avatarContainer,
          ),
        );
      },
    );
  }
}
