import 'package:flutter/material.dart';
import 'package:h2orbit/models/analytics_model.dart';
import 'package:h2orbit/utils/helpers.dart';
import 'package:h2orbit/utils/theme.dart';

/// Bars per day with a dashed line at the daily goal.
///
/// Bars that reach the goal turn green and today is outlined. With
/// [compact] it shows many slim bars (used for the 30-day trend).
class GoalBarChart extends StatelessWidget {
  final List<DayTotal> days;
  final int goalMl;
  final bool compact;
  final double height;

  const GoalBarChart({
    super.key,
    required this.days,
    required this.goalMl,
    this.compact = false,
    this.height = 190,
  });

  @override
  Widget build(BuildContext context) {
    final maxMl = days.fold<int>(goalMl, (m, d) => d.ml > m ? d.ml : m);
    final scale = maxMl * 1.12;
    final labelHeight = compact ? 0.0 : 22.0;
    final valueHeight = compact ? 0.0 : 16.0;
    final plotHeight = height - labelHeight - valueHeight;

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          // Goal line.
          Positioned.fill(
            top: valueHeight,
            bottom: labelHeight,
            child: CustomPaint(
              painter: _GoalLinePainter(fraction: goalMl / scale),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final d in days)
                Expanded(
                  child: Semantics(
                    label:
                        '${Fmt.weekday(d.day)}: ${Fmt.liters(d.ml, decimals: 2)}',
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 1 : 6,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (!compact)
                            SizedBox(
                              height: valueHeight,
                              child: d.ml > 0
                                  ? FittedBox(
                                      child: Text(
                                        Fmt.liters(d.ml),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          SizedBox(
                            height: plotHeight,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: _Bar(
                                heightFraction: d.ml / scale,
                                plotHeight: plotHeight,
                                reachedGoal: d.ml >= goalMl && goalMl > 0,
                                isToday: d.isToday,
                                isFuture: d.isFuture,
                                compact: compact,
                              ),
                            ),
                          ),
                          if (!compact)
                            SizedBox(
                              height: labelHeight,
                              child: Center(
                                child: Text(
                                  Fmt.weekday(d.day).substring(0, 3),
                                  style: TextStyle(
                                    color: d.isToday
                                        ? AppTheme.lightCyan
                                        : Colors.white.withValues(alpha: 0.75),
                                    fontSize: 12,
                                    fontWeight: d.isToday
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double heightFraction;
  final double plotHeight;
  final bool reachedGoal;
  final bool isToday;
  final bool isFuture;
  final bool compact;

  const _Bar({
    required this.heightFraction,
    required this.plotHeight,
    required this.reachedGoal,
    required this.isToday,
    required this.isFuture,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final minHeight = isFuture ? 0.0 : (compact ? 2.0 : 4.0);
    final barHeight = (heightFraction * plotHeight).clamp(
      minHeight,
      plotHeight,
    );

    final colors = reachedGoal
        ? const [Color(0xFF2E9E5B), AppTheme.success]
        : const [AppTheme.oceanBlue, AppTheme.lightCyan];

    return TweenAnimationBuilder<double>(
      tween: Tween(end: barHeight.toDouble()),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, h, _) => Container(
        height: h,
        constraints: BoxConstraints(maxWidth: compact ? 8 : 34),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(compact ? 3 : 9),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: colors,
          ),
          border: isToday
              ? Border.all(color: Colors.white, width: compact ? 1 : 1.5)
              : null,
        ),
      ),
    );
  }
}

class _GoalLinePainter extends CustomPainter {
  final double fraction;

  _GoalLinePainter({required this.fraction});

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * (1 - fraction.clamp(0.0, 1.0));
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 1.2;
    const dash = 5.0;
    const gap = 4.0;
    for (double x = 0; x < size.width; x += dash + gap) {
      canvas.drawLine(Offset(x, y), Offset(x + dash, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GoalLinePainter old) => old.fraction != fraction;
}
