import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:h2orbit/utils/theme.dart';

class WaterWaveAnimation extends StatelessWidget {
  final double progress;
  final AnimationController controller;

  const WaterWaveAnimation({
    super.key,
    required this.progress,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppTheme.deepCyan.withOpacity(0.25),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Wave animation
            AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: WavePainter(
                    progress: progress.clamp(0.0, 1.0),
                    animationValue: controller.value,
                  ),
                  size: Size.infinite,
                );
              },
            ),
            
            // Percentage text with shadow
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${(progress.clamp(0.0, 1.0) * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    shadows: [
                      Shadow(
                        color: Colors.black38,
                        offset: Offset(2, 2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  final double progress;
  final double animationValue;

  WavePainter({
    required this.progress,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.lightCyan.withOpacity(0.6),
          AppTheme.oceanBlue.withOpacity(0.8),
          AppTheme.deepCyan.withOpacity(0.9),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..style = PaintingStyle.fill;

    final path = Path();
    final waveHeight = 8.0;
    final waveLength = size.width / 1.5;
    final waterLevel = size.height * (1 - progress.clamp(0.0, 1.0));

    // Start path from left
    path.moveTo(0, waterLevel);

    // Create wave effect
    for (double x = 0; x <= size.width; x += 1) {
      final y1 = waterLevel +
          waveHeight *
              math.sin(
                (x / waveLength * 2 * math.pi) + (animationValue * 2 * math.pi),
              );
      
      final y2 = waterLevel +
          waveHeight *
              0.5 *
              math.sin(
                (x / waveLength * 3 * math.pi) -
                    (animationValue * 1.5 * math.pi),
              );
      
      path.lineTo(x, y1 + y2);
    }

    // Complete the path
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Add shimmer effect on top of water
    if (progress > 0.05) {
      final shimmerPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.3),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromLTWH(
            0,
            waterLevel - 20,
            size.width,
            20,
          ),
        )
        ..style = PaintingStyle.fill;

      final shimmerPath = Path();
      shimmerPath.moveTo(0, waterLevel);

      for (double x = 0; x <= size.width; x += 1) {
        final y = waterLevel +
            waveHeight *
                math.sin(
                  (x / waveLength * 2 * math.pi) +
                      (animationValue * 2 * math.pi),
                );
        shimmerPath.lineTo(x, y);
      }

      shimmerPath.lineTo(size.width, waterLevel - 20);
      shimmerPath.lineTo(0, waterLevel - 20);
      shimmerPath.close();

      canvas.drawPath(shimmerPath, shimmerPaint);
    }
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.animationValue != animationValue;
  }
}