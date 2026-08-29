class RecentFoodReference {
  const RecentFoodReference({required this.identityKey, required this.usedAt});

  final String identityKey;
  final DateTime usedAt;

  Map<String, dynamic> toJson() {
    return {
      'identityKey': identityKey,
      'usedAt': usedAt.toUtc().toIso8601String(),
    };
  }

  factory RecentFoodReference.fromJson(Map<String, dynamic> json) {
    return RecentFoodReference(
      identityKey: json['identityKey'] as String,
      usedAt: DateTime.parse(json['usedAt'] as String).toUtc(),
    );
  }
}
