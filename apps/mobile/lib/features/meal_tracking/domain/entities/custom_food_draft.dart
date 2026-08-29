import 'catalog_food.dart';

class CustomFoodDraft {
  const CustomFoodDraft({
    required this.name,
    required this.servingQuantity,
    required this.servingUnit,
    required this.calories,
    required this.proteinGrams,
    required this.carbohydrateGrams,
    required this.fatGrams,
    this.brand,
  });

  final String name;
  final String? brand;
  final double servingQuantity;
  final String servingUnit;
  final double calories;
  final double proteinGrams;
  final double carbohydrateGrams;
  final double fatGrams;

  String get servingDescription {
    return '${_formatNumber(servingQuantity)} ${servingUnit.trim()}';
  }

  void validate() {
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'Food name is required.');
    }

    if (!servingQuantity.isFinite || servingQuantity <= 0) {
      throw ArgumentError.value(
        servingQuantity,
        'servingQuantity',
        'Serving quantity must be greater than zero.',
      );
    }

    if (servingUnit.trim().isEmpty) {
      throw ArgumentError.value(
        servingUnit,
        'servingUnit',
        'Serving unit is required.',
      );
    }

    if (!calories.isFinite || calories <= 0) {
      throw ArgumentError.value(
        calories,
        'calories',
        'Calories must be greater than zero.',
      );
    }

    _validateNonNegative(proteinGrams, 'proteinGrams');
    _validateNonNegative(carbohydrateGrams, 'carbohydrateGrams');
    _validateNonNegative(fatGrams, 'fatGrams');
  }

  CatalogFood toCatalogFood({required String id}) {
    validate();

    final normalizedBrand = brand?.trim();

    return CatalogFood(
      id: id,
      name: name.trim(),
      brand: normalizedBrand == null || normalizedBrand.isEmpty
          ? null
          : normalizedBrand,
      servingDescription: servingDescription,
      servingQuantity: servingQuantity,
      servingUnit: servingUnit.trim(),
      calories: calories,
      proteinGrams: proteinGrams,
      carbohydrateGrams: carbohydrateGrams,
      fatGrams: fatGrams,
      source: CatalogFoodSource.custom,
      providerId: 'prana-custom',
    );
  }

  static void _validateNonNegative(double value, String fieldName) {
    if (!value.isFinite || value < 0) {
      throw ArgumentError.value(
        value,
        fieldName,
        '$fieldName cannot be negative.',
      );
    }
  }

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
  }
}
