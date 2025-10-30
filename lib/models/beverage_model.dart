class BeverageModel {
  final String type;
  final String name;
  final int milliliters;
  final double hydrationMultiplier;
  final int caffeineContent; // in mg
  final String iconName;

  BeverageModel({
    required this.type,
    required this.name,
    required this.milliliters,
    required this.hydrationMultiplier,
    this.caffeineContent = 0,
    required this.iconName,
  });

  // Calculate effective hydration value
  double get effectiveHydration {
    double baseHydration = milliliters * hydrationMultiplier;

    // Subtract caffeine offset (1.5ml per mg of caffeine)
    double caffeineOffset = caffeineContent * 1.5;

    return (baseHydration - caffeineOffset).clamp(0, milliliters.toDouble());
  }

  static List<BeverageModel> getDefaultBeverages() {
    return [
      BeverageModel(
        type: 'water',
        name: 'Water',
        milliliters: 250,
        hydrationMultiplier: 1.0,
        caffeineContent: 0,
        iconName: 'glass_water',
      ),
      BeverageModel(
        type: 'water',
        name: 'Large Water',
        milliliters: 500,
        hydrationMultiplier: 1.0,
        caffeineContent: 0,
        iconName: 'glass_water',
      ),
      BeverageModel(
        type: 'juice',
        name: 'Fruit Juice',
        milliliters: 200,
        hydrationMultiplier: 0.9,
        caffeineContent: 0,
        iconName: 'wine_glass',
      ),
      BeverageModel(
        type: 'tea',
        name: 'Green Tea',
        milliliters: 150,
        hydrationMultiplier: 0.85,
        caffeineContent: 25,
        iconName: 'mug_hot',
      ),
      BeverageModel(
        type: 'tea',
        name: 'Black Tea',
        milliliters: 150,
        hydrationMultiplier: 0.8,
        caffeineContent: 40,
        iconName: 'mug_hot',
      ),
      BeverageModel(
        type: 'coffee',
        name: 'Coffee',
        milliliters: 150,
        hydrationMultiplier: 0.7,
        caffeineContent: 95,
        iconName: 'mug_saucer',
      ),
      BeverageModel(
        type: 'coffee',
        name: 'Espresso',
        milliliters: 30,
        hydrationMultiplier: 0.6,
        caffeineContent: 63,
        iconName: 'mug_saucer',
      ),
      BeverageModel(
        type: 'milk',
        name: 'Milk',
        milliliters: 200,
        hydrationMultiplier: 0.85,
        caffeineContent: 0,
        iconName: 'glass',
      ),
      BeverageModel(
        type: 'smoothie',
        name: 'Smoothie',
        milliliters: 300,
        hydrationMultiplier: 0.8,
        caffeineContent: 0,
        iconName: 'blender',
      ),
      BeverageModel(
        type: 'sports',
        name: 'Sports Drink',
        milliliters: 250,
        hydrationMultiplier: 0.9,
        caffeineContent: 0,
        iconName: 'bottle',
      ),
      BeverageModel(
        type: 'soda',
        name: 'Soda',
        milliliters: 250,
        hydrationMultiplier: 0.6,
        caffeineContent: 35,
        iconName: 'bottle',
      ),
      BeverageModel(
        type: 'energy',
        name: 'Energy Drink',
        milliliters: 250,
        hydrationMultiplier: 0.5,
        caffeineContent: 80,
        iconName: 'bolt',
      ),
    ];
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'name': name,
      'milliliters': milliliters,
      'hydrationMultiplier': hydrationMultiplier,
      'caffeineContent': caffeineContent,
      'iconName': iconName,
    };
  }

  factory BeverageModel.fromMap(Map<String, dynamic> map) {
    return BeverageModel(
      type: map['type'] ?? 'water',
      name: map['name'] ?? 'Water',
      milliliters: map['milliliters'] ?? 250,
      hydrationMultiplier: (map['hydrationMultiplier'] ?? 1.0).toDouble(),
      caffeineContent: map['caffeineContent'] ?? 0,
      iconName: map['iconName'] ?? 'glass_water',
    );
  }
}
