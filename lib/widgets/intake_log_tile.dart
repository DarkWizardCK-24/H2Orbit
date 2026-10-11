import 'package:flutter/material.dart';
import 'package:h2orbit/models/beverage_model.dart';
import 'package:h2orbit/models/water_intake_model.dart';
import 'package:h2orbit/utils/helpers.dart';
import 'package:h2orbit/utils/theme.dart';
import 'package:h2orbit/widgets/glass_container.dart';

/// One logged drink in today's list. Swipe left to delete.
class IntakeLogTile extends StatelessWidget {
  final WaterIntakeModel intake;
  final VoidCallback onDelete;

  const IntakeLogTile({
    super.key,
    required this.intake,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final label = BeverageModel.labelFor(intake.beverageType);

    return Dismissible(
      key: ValueKey(
        'intake_${intake.id}_${intake.timestamp.microsecondsSinceEpoch}',
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppTheme.danger.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        borderRadius: BorderRadius.circular(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.lightCyan.withValues(alpha: 0.2),
              ),
              child: Icon(
                beverageIcon(intake.beverageType),
                color: AppTheme.lightCyan,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Fmt.ml(intake.milliliters),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              Fmt.time(intake.timestamp),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 12.5,
              ),
            ),
            IconButton(
              tooltip: 'Delete entry',
              visualDensity: VisualDensity.compact,
              onPressed: onDelete,
              icon: Icon(
                Icons.close_rounded,
                size: 18,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
