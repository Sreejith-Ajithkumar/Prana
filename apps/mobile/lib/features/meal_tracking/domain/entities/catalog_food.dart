class CatalogFood {
  const CatalogFood({
    required this.id,
    required this.name,
    required this.servingDescription,
    required this.servingQuantity,
    required this.servingUnit,
    required this.calories,
    required this.proteinGrams,
    required this.carbohydrateGrams,
    required this.fatGrams,
  });

  final String id;
  final String name;

  /// Human-readable serving, such as "1 cup" or "100 g".
  final String servingDescription;

  final double servingQuantity;
  final String servingUnit;

  final double calories;
  final double proteinGrams;
  final double carbohydrateGrams;
  final double fatGrams;
}
