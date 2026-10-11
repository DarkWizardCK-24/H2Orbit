import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:h2orbit/utils/theme.dart';
import 'package:h2orbit/widgets/progress_ring.dart';

/// A glass of water that fills up as the day's goal is reached, wrapped in a
/// progress ring. Waves keep moving unless the user turned animations off.
class WaterOrb extends StatefulWidget {
  /// 0.0 - 1.0
  final double progress;
  final double size;
  final String caption;

  const WaterOrb({
    super.key,
    required this.progress,
    this.size = 200,
    this.caption = 'of daily goal',
  });

  @override
  State<WaterOrb> createState() => _WaterOrbState();
}

class _WaterOrbState extends State<WaterOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waves = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      _waves.stop();
    } else if (!_waves.isAnimating) {
      _waves.repeat();
    }
  }

  @override
  void dispose() {
    _waves.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.progress.clamp(0.0, 1.0);
    final ringInset = widget.size * 0.085;

    return Semantics(
      label: 'Daily progress',
      value: '${(progress * 100).round()} percent',
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: ProgressRing(
                progress: progress,
                strokeWidth: widget.size * 0.05,
                showLabel: false,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(ringInset + widget.size * 0.05),
              child: ClipOval(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(
                      color: AppTheme.deepCyan.withValues(alpha: 0.45),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween(end: progress),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (context, level, _) => AnimatedBuilder(
                        animation: _waves,
                        builder: (context, _) => CustomPaint(
                          painter: WavePainter(
                            progress: level,
                            animationValue: _waves.value,
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(progress * 100).round()}%',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: widget.size * 0.22,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                              shadows: const [
                                Shadow(
                                  color: Colors.black38,
                                  offset: Offset(0, 2),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            widget.caption,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: widget.size * 0.065,
                              fontWeight: FontWeight.w500,
                              shadows: const [
                                Shadow(color: Colors.black38, blurRadius: 6),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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

  WavePainter({required this.progress, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final level = progress.clamp(0.0, 1.0);
    final waveHeight = 6.0 * (1 - (level - 0.5).abs()).clamp(0.3, 1.0);
    final waveLength = size.width / 1.3;
    final waterLevel = size.height * (1 - level);

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.lightCyan.withValues(alpha: 0.75),
          AppTheme.oceanBlue.withValues(alpha: 0.9),
          AppTheme.waveBlue.withValues(alpha: 0.95),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    double surface(double x, {double phase = 0, double amp = 1}) =>
        waterLevel +
        waveHeight *
            amp *
            math.sin(
              x / waveLength * 2 * math.pi +
                  animationValue * 2 * math.pi +
                  phase,
            );

    // Back wave (lighter), then the main wave on top for depth.
    final back = Path()..moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 2) {
      back.lineTo(x, surface(x, phase: math.pi / 2, amp: 0.8));
    }
    back
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(
      back,
      Paint()..color = AppTheme.lightCyan.withValues(alpha: 0.35),
    );

    final front = Path()..moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 2) {
      front.lineTo(x, surface(x));
    }
    front
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(front, paint);
  }

  @override
  bool shouldRepaint(WavePainter old) =>
      old.progress != progress || old.animationValue != animationValue;
}
