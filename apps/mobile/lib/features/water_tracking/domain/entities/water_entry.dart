class WaterEntry {
  const WaterEntry({
    required this.id,
    required this.amountMl,
    required this.loggedAt,
  });

  final String id;
  final double amountMl;
  final DateTime loggedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amountMl': amountMl,
      'loggedAt': loggedAt.toIso8601String(),
    };
  }

  factory WaterEntry.fromJson(Map<String, dynamic> json) {
    return WaterEntry(
      id: json['id'] as String,
      amountMl: (json['amountMl'] as num).toDouble(),
      loggedAt: DateTime.parse(json['loggedAt'] as String),
    );
  }
}
