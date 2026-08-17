enum HealthPlatform { appleHealth, healthConnect, unsupported }

enum HealthDataType { bodyWeight, steps, activeEnergyBurned, workout }

enum HealthAccessStatus {
  unknown,
  unavailable,
  notRequested,
  partiallyGranted,
  granted,
  denied,
}

class HealthAvailability {
  const HealthAvailability({required this.platform, required this.isAvailable});

  final HealthPlatform platform;
  final bool isAvailable;
}
