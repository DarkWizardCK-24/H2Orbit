import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:h2orbit/utils/theme.dart';

/// Animated circular progress with the percentage in the middle.
class ProgressRing extends StatefulWidget {
  final double progress;
  final double strokeWidth;
  final bool showLabel;

  const ProgressRing({
    super.key,
    required this.progress,
    this.strokeWidth = 8,
    this.showLabel = true,
  });

  @override
  State<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<ProgressRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 800),
    vsync: this,
  );
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animation = _tween(0, widget.progress);
    _controller.forward();
  }

  Animation<double> _tween(double from, double to) => Tween<double>(
    begin: from,
    end: to,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void didUpdateWidget(ProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.progress - widget.progress).abs() > 0.001) {
      _animation = _tween(_animation.value, widget.progress);
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final value = _animation.value.clamp(0.0, 1.0);
        return CustomPaint(
          painter: ProgressRingPainter(
            progress: value,
            strokeWidth: widget.strokeWidth,
          ),
          child: widget.showLabel
              ? Center(
                  child: Text(
                    '${(value * 100).round()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}

class ProgressRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;

  ProgressRingPainter({required this.progress, this.strokeWidth = 8});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    if (progress <= 0) return;

    const start = -math.pi / 2;
    final sweep = 2 * math.pi * progress;

    // Soft glow under the arc.
    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..color = AppTheme.lightCyan.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Arc with a gradient that follows its own length (bright on the dark
    // ocean background at any progress).
    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: 0,
          endAngle: sweep < 0.01 ? 0.01 : sweep,
          colors: const [AppTheme.lightCyan, Color(0xFFD6FBFF)],
          transform: const GradientRotation(start),
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Bright dot at the tip.
    final end = start + sweep;
    canvas.drawCircle(
      Offset(
        center.dx + radius * math.cos(end),
        center.dy + radius * math.sin(end),
      ),
      strokeWidth / 2 - 1,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(ProgressRingPainter old) =>
      (old.progress - progress).abs() > 0.001 || old.strokeWidth != strokeWidth;
}
