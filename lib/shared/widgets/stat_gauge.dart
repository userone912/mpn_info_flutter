import 'package:flutter/material.dart';

class StatGauge extends StatelessWidget {
  final double value; // 0.0 - 100.0
  final double size;
  final Duration animationDuration;

  const StatGauge({
    Key? key,
    required this.value,
    this.size = 300,
    this.animationDuration = const Duration(milliseconds: 1500),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: animationDuration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        // Mimic dialer.cpp logic
        // mMinimum = 0, mMaximum = 120, mValue = value
        // angle = clamp(-130, ((mMinimum + mValue) * 260.0 / (mMaximum - mMinimum) - 130), 133)
        const double min = 0;
        const double max = 120;
        double v = animatedValue.clamp(min, max);
        double angleDeg = ((min + v) * 260.0 / (max - min) - 130);
        angleDeg = angleDeg.clamp(-130, 133);
        double angleRad = angleDeg * 3.141592653589793 / 180.0;

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Dial background
              Positioned(
                left: 0,
                top: 0,
                child: Image.asset(
                  'assets/images/dial-background.png',
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                ),
              ),
              // Needle: pivot at dial center, base of needle at dial center
              // Overlay (mimic Qt overlayRect) -- semi-transparent
              Positioned(
                left: size * 0.11,
                top: size * 0.11,
                child: Opacity(
                  opacity: 0.5, // Semi-transparent overlay
                  child: Image.asset(
                    'assets/images/dial-overlay.png',
                    width: size * 0.7048,
                    height: size * 0.5,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              // Needle shadow: offset to the right, parallel to needle
              Center(
                child: Transform.rotate(
                  angle: angleRad,
                  alignment: Alignment.center,
                  child: Transform.translate(
                    offset: Offset(size * 0.03, -size * 0.05), // right offset for shadow
                    child: Image.asset(
                      'assets/images/dial-needle-shadow.png',
                      width: size * 0.045,
                      height: size * 0.38,
                      fit: BoxFit.contain,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                ),
              ),
              // Needle: pivot at dial center, base of needle at dial center
              Center(
                child: Transform.rotate(
                  angle: angleRad,
                  alignment: Alignment.center,
                  child: Transform.translate(
                    offset: Offset(0, -size * 0.09,
                    ), // move needle up by 9% of gauge size
                    child: Image.asset(
                      'assets/images/dial-needle.png',
                      width: size * 0.04,
                      height: size * 0.38,
                      fit: BoxFit.contain,
                      alignment:
                          Alignment.topCenter, // base of needle at dial center
                    ),
                  ),
                ),
              ),
              Positioned(
                left: size * 0.11,
                top: size * 0.11,
                child: Opacity(
                  opacity: 1, // Hide overlay for debugging
                  child: Image.asset(
                    'assets/images/dial-overlay.png',
                    width: size * 0.7048,
                    height: size * 0.5,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              // Percentage text
              Positioned(
                bottom: size * 0.16,
                child: Text(
                  '${animatedValue.toStringAsFixed(2)}%',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    shadows: [Shadow(color: Colors.white, blurRadius: 4)],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
