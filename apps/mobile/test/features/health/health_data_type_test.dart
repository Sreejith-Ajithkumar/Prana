import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/features/health/domain/entities/health_data_type.dart';

void main() {
  group('HealthDataType', () {
    test('contains the initial Sprint 7 health signals', () {
      expect(
        HealthDataType.values,
        containsAll(const [
          HealthDataType.bodyWeight,
          HealthDataType.steps,
          HealthDataType.activeEnergyBurned,
          HealthDataType.workout,
        ]),
      );
    });
  });

  group('HealthAvailability', () {
    test('represents an available Health Connect platform', () {
      const availability = HealthAvailability(
        platform: HealthPlatform.healthConnect,
        isAvailable: true,
      );

      expect(availability.platform, HealthPlatform.healthConnect);

      expect(availability.isAvailable, isTrue);
    });

    test('represents an unavailable platform', () {
      const availability = HealthAvailability(
        platform: HealthPlatform.unsupported,
        isAvailable: false,
      );

      expect(availability.platform, HealthPlatform.unsupported);

      expect(availability.isAvailable, isFalse);
    });
  });
}
