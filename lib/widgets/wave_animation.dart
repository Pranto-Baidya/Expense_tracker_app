import 'dart:math';
import 'package:flutter/material.dart';

class WaterWaveAnimation extends StatefulWidget {
  final double percentage; // 0.0 to 1.0
  final List<Color> gradientColors;
  final Widget child;

  const WaterWaveAnimation({
    required this.percentage,
    required this.gradientColors,
    required this.child,
    super.key,
  });

  @override
  State<WaterWaveAnimation> createState() => _WaterWaveAnimationState();
}

class _WaterWaveAnimationState extends State<WaterWaveAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return CustomPaint(
          painter: RealisticWavePainter(
            animationValue: _controller.value,
            percentage: widget.percentage,
            gradientColors: widget.gradientColors,
          ),
          child: widget.child,
        );
      },
    );
  }
}

class RealisticWavePainter extends CustomPainter {
  final double animationValue;
  final double percentage;
  final List<Color> gradientColors;

  RealisticWavePainter({
    required this.animationValue,
    required this.percentage,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final waterLevel = size.height * (1 - percentage);

    final waveHeight1 = 4.0; // minimal wave
    final waveHeight2 = 2.0; // even smaller for realism

    final waveLength1 = size.width * 1.2; // long waves
    final waveLength2 = size.width * 0.8;

    final path = Path()..moveTo(0, size.height)..lineTo(0, waterLevel);

    for (double x = 0; x <= size.width; x++) {
      double y = waterLevel +
          sin((x / waveLength1 * 2 * pi) + animationValue * 2 * pi) * waveHeight1 +
          sin((x / waveLength2 * 2 * pi) + animationValue * 4 * pi) * waveHeight2;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        gradientColors.first.withOpacity(0.4),
        gradientColors.last.withOpacity(0.8),
      ],
    );

    final paint = Paint()..shader =
    gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, paint);

    // Second smoother wave for depth
    final path2 = Path()..moveTo(0, size.height)..lineTo(0, waterLevel);

    for (double x = 0; x <= size.width; x++) {
      double y = waterLevel +
          sin((x / waveLength1 * 2 * pi) + animationValue * 2 * pi + pi / 2) * (waveHeight1 * 0.6);
      path2.lineTo(x, y);
    }

    path2.lineTo(size.width, size.height);
    path2.close();

    final paint2 = Paint()
      ..shader =
      gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.softLight;

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant RealisticWavePainter oldDelegate) =>
      oldDelegate.animationValue != animationValue ||
          oldDelegate.percentage != percentage;
}
