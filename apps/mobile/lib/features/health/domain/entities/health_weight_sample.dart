class HealthWeightSample {
  const HealthWeightSample({
    required this.externalId,
    required this.weightKg,
    required this.measuredAt,
    this.sourceName,
  });

  final String externalId;
  final double weightKg;
  final DateTime measuredAt;
  final String? sourceName;
}
