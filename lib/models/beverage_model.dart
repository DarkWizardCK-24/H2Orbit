import 'package:flutter/material.dart';

/// A drink preset used by the quick-add buttons and the hydration maths.
class BeverageModel {
  final String type;
  final String name;
  final int milliliters;

  /// How well the drink hydrates compared with plain water (1.0 = water).
  final double hydrationMultiplier;

  /// Caffeine per serving, in mg.
  final int caffeineMg;

  const BeverageModel({
    required this.type,
    required this.name,
    required this.milliliters,
    required this.hydrationMultiplier,
    this.caffeineMg = 0,
  });

  IconData get icon => beverageIcon(type);

  double get hydrationValue => milliliters * hydrationMultiplier;

  /// Presets shown on the home screen.
  static const List<BeverageModel> quickAdd = [
    BeverageModel(
      type: 'water',
      name: 'Glass',
      milliliters: 250,
      hydrationMultiplier: 1.0,
    ),
    BeverageModel(
      type: 'water',
      name: 'Bottle',
      milliliters: 500,
      hydrationMultiplier: 1.0,
    ),
    BeverageModel(
      type: 'juice',
      name: 'Juice',
      milliliters: 200,
      hydrationMultiplier: 0.9,
    ),
    BeverageModel(
      type: 'tea',
      name: 'Tea',
      milliliters: 150,
      hydrationMultiplier: 0.8,
      caffeineMg: 40,
    ),
    BeverageModel(
      type: 'coffee',
      name: 'Coffee',
      milliliters: 150,
      hydrationMultiplier: 0.7,
      caffeineMg: 95,
    ),
    BeverageModel(
      type: 'milk',
      name: 'Milk',
      milliliters: 200,
      hydrationMultiplier: 0.85,
    ),
  ];

  /// Multipliers by drink type (also used for custom amounts and old entries).
  static const Map<String, double> multipliers = {
    'water': 1.0,
    'juice': 0.9,
    'tea': 0.8,
    'coffee': 0.7,
    'milk': 0.85,
    'soda': 0.6,
  };

  /// Approximate caffeine per 100 ml, used to total up the day's caffeine.
  static const Map<String, double> caffeineMgPer100ml = {
    'coffee': 63,
    'tea': 27,
    'soda': 14,
  };

  static double multiplierFor(String type) => multipliers[type] ?? 1.0;

  static String labelFor(String type) {
    if (type.isEmpty) return 'Water';
    return type[0].toUpperCase() + type.substring(1);
  }
}

IconData beverageIcon(String type) {
  switch (type) {
    case 'juice':
      return Icons.wine_bar_rounded;
    case 'tea':
      return Icons.emoji_food_beverage_rounded;
    case 'coffee':
      return Icons.coffee_rounded;
    case 'milk':
      return Icons.local_drink_rounded;
    case 'soda':
      return Icons.local_bar_rounded;
    default:
      return Icons.water_drop_rounded;
  }
}
