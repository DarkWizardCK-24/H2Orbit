import 'package:flutter/material.dart';
import 'package:h2orbit/models/beverage_model.dart';
import 'package:h2orbit/utils/helpers.dart';
import 'package:h2orbit/utils/theme.dart';
import 'package:h2orbit/widgets/animated_button.dart';

typedef CustomDrink = ({int ml, String type});

/// Bottom sheet for logging an amount and drink that isn't a quick-add preset.
Future<CustomDrink?> showCustomDrinkSheet(BuildContext context) {
  return showModalBottomSheet<CustomDrink>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _CustomDrinkSheet(),
  );
}

class _CustomDrinkSheet extends StatefulWidget {
  const _CustomDrinkSheet();

  @override
  State<_CustomDrinkSheet> createState() => _CustomDrinkSheetState();
}

class _CustomDrinkSheetState extends State<_CustomDrinkSheet> {
  static const _types = ['water', 'juice', 'tea', 'coffee', 'milk'];
  int _ml = 250;
  String _type = 'water';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Add a custom amount',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type in _types)
                  ChoiceChip(
                    avatar: Icon(
                      beverageIcon(type),
                      size: 18,
                      color: _type == type
                          ? AppTheme.darkBackground
                          : Colors.white70,
                    ),
                    label: Text(BeverageModel.labelFor(type)),
                    selected: _type == type,
                    showCheckmark: false,
                    selectedColor: AppTheme.lightCyan,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    side: BorderSide.none,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _type == type
                          ? AppTheme.darkBackground
                          : Colors.white,
                    ),
                    onSelected: (_) => setState(() => _type = type),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                '$_ml ml',
                style: const TextStyle(
                  color: AppTheme.lightCyan,
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Center(
              child: Text(
                'about ${Fmt.glasses(_ml)} glasses',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
              ),
            ),
            Slider(
              value: _ml.toDouble(),
              min: 50,
              max: 1000,
              divisions: 19,
              label: '$_ml ml',
              onChanged: (v) => setState(() => _ml = v.round()),
            ),
            const SizedBox(height: 12),
            AnimatedButton(
              text: 'Add drink',
              icon: Icons.add_rounded,
              onPressed: () => Navigator.pop(context, (ml: _ml, type: _type)),
            ),
          ],
        ),
      ),
    );
  }
}
