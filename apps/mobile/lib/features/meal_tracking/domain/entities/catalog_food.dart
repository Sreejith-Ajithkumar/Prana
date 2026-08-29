enum CatalogFoodSource { localCatalog, custom, externalCatalog, aiSuggestion }

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
    this.source = CatalogFoodSource.localCatalog,
    this.providerId = 'prana-local',
    this.brand,
    this.barcode,
  });

  /// Provider-native identifier for this food.
  ///
  /// It does not need to be globally unique by itself. Use [identityKey]
  /// when Prana needs a stable identity across multiple food providers.
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

  /// Where the food record originated.
  final CatalogFoodSource source;

  /// Stable identifier for the provider that supplied this record.
  ///
  /// Examples in future phases may include a custom-food store or an
  /// external food database. The local Prana catalog uses `prana-local`.
  final String providerId;

  /// Optional brand/manufacturer name for packaged foods.
  final String? brand;

  /// Optional UPC/EAN-style barcode value when one is available.
  final String? barcode;

  /// Provider-aware identity used for deduplication and future persistence.
  String get identityKey => '${source.name}:$providerId:$id';
}
