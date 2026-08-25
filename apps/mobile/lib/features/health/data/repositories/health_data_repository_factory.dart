import 'package:flutter/foundation.dart';

import '../../domain/entities/health_data_type.dart';
import '../../domain/repositories/health_data_repository.dart';
import 'apple_health_data_repository.dart';
import 'health_connect_data_repository.dart';

HealthDataRepository createHealthDataRepository({TargetPlatform? platform}) {
  final resolvedPlatform = platform ?? defaultTargetPlatform;

  return switch (resolvedPlatform) {
    TargetPlatform.android => HealthConnectDataRepository(),
    TargetPlatform.iOS => AppleHealthDataRepository(),
    _ => const UnsupportedHealthDataRepository(),
  };
}

class UnsupportedHealthDataRepository implements HealthDataRepository {
  const UnsupportedHealthDataRepository();

  @override
  Future<HealthAvailability> checkAvailability() async {
    return const HealthAvailability(
      platform: HealthPlatform.unsupported,
      isAvailable: false,
    );
  }

  @override
  Future<HealthAccessStatus> getAccessStatus(
    Set<HealthDataType> dataTypes,
  ) async {
    return HealthAccessStatus.unavailable;
  }

  @override
  Future<HealthAccessStatus> requestAccess(
    Set<HealthDataType> dataTypes,
  ) async {
    return HealthAccessStatus.unavailable;
  }

  @override
  Future<void> openHealthSettings() async {}
}
