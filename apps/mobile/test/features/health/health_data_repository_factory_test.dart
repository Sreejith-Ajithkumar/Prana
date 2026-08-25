import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/features/health/data/repositories/apple_health_data_repository.dart';
import 'package:mobile/features/health/data/repositories/health_connect_data_repository.dart';
import 'package:mobile/features/health/data/repositories/health_data_repository_factory.dart';
import 'package:mobile/features/health/domain/entities/health_data_type.dart';

void main() {
  group('createHealthDataRepository', () {
    test('selects Health Connect on Android', () {
      final repository = createHealthDataRepository(
        platform: TargetPlatform.android,
      );

      expect(repository, isA<HealthConnectDataRepository>());
    });

    test('selects Apple Health on iOS', () {
      final repository = createHealthDataRepository(
        platform: TargetPlatform.iOS,
      );

      expect(repository, isA<AppleHealthDataRepository>());
    });

    test('returns unavailable repository on unsupported platforms', () async {
      final repository = createHealthDataRepository(
        platform: TargetPlatform.windows,
      );

      final availability = await repository.checkAvailability();

      expect(availability.platform, HealthPlatform.unsupported);
      expect(availability.isAvailable, isFalse);
    });
  });
}
