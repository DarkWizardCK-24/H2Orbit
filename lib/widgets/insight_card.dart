import 'package:flutter/material.dart';
import 'package:h2orbit/services/ai_prediction_service.dart';
import 'package:h2orbit/utils/theme.dart';
import 'package:h2orbit/widgets/glass_container.dart';

/// A tip from the hydration coach (or any icon + title + text insight).
class InsightCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color accent;

  const InsightCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.accent = AppTheme.lightCyan,
  });

  factory InsightCard.fromTip(CoachTip tip, {Key? key}) {
    final accent = switch (tip.kind) {
      TipKind.success => AppTheme.success,
      TipKind.warning => AppTheme.warning,
      TipKind.info => AppTheme.lightCyan,
    };
    return InsightCard(
      key: key,
      icon: tip.icon,
      title: tip.title,
      description: tip.message,
      accent: accent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.2),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
