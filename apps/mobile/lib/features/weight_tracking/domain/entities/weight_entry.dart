enum WeightSource { manual, appleHealth, healthConnect, smartScale, unknown }

class WeightEntry {
  const WeightEntry({
    required this.id,
    required this.weightKg,
    required this.measuredAt,
    this.source = WeightSource.manual,
    this.note,
  });

  final String id;
  final double weightKg;
  final DateTime measuredAt;
  final WeightSource source;
  final String? note;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'weightKg': weightKg,
      'measuredAt': measuredAt.toIso8601String(),
      'source': source.name,
      'note': note,
    };
  }

  factory WeightEntry.fromJson(Map<String, dynamic> json) {
    final sourceName = json['source'] as String? ?? WeightSource.unknown.name;

    var source = WeightSource.unknown;

    for (final value in WeightSource.values) {
      if (value.name == sourceName) {
        source = value;
        break;
      }
    }

    return WeightEntry(
      id: json['id'] as String,
      weightKg: (json['weightKg'] as num).toDouble(),
      measuredAt: DateTime.parse(json['measuredAt'] as String),
      source: source,
      note: json['note'] as String?,
    );
  }
  WeightEntry copyWith({
    String? id,
    double? weightKg,
    DateTime? measuredAt,
    WeightSource? source,
    String? note,
    bool clearNote = false,
  }) {
    return WeightEntry(
      id: id ?? this.id,
      weightKg: weightKg ?? this.weightKg,
      measuredAt: measuredAt ?? this.measuredAt,
      source: source ?? this.source,
      note: clearNote ? null : note ?? this.note,
    );
  }
}
