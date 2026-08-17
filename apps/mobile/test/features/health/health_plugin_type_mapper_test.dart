import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart' as health_plugin;

import 'package:mobile/features/health/data/mappers/health_plugin_type_mapper.dart';
import 'package:mobile/features/health/domain/entities/health_data_type.dart';

void main() {
  const mapper = HealthPluginTypeMapper();

  group('HealthPluginTypeMapper', () {
    test('maps body weight', () {
      expect(
        mapper.toPluginType(HealthDataType.bodyWeight),
        health_plugin.HealthDataType.WEIGHT,
      );
    });

    test('maps steps', () {
      expect(
        mapper.toPluginType(HealthDataType.steps),
        health_plugin.HealthDataType.STEPS,
      );
    });

    test('maps active energy burned', () {
      expect(
        mapper.toPluginType(HealthDataType.activeEnergyBurned),
        health_plugin.HealthDataType.ACTIVE_ENERGY_BURNED,
      );
    });

    test('maps workout', () {
      expect(
        mapper.toPluginType(HealthDataType.workout),
        health_plugin.HealthDataType.WORKOUT,
      );
    });

    test('maps all initial Sprint 7 types', () {
      final mapped = mapper.toPluginTypes(HealthDataType.values);

      expect(mapped, [
        health_plugin.HealthDataType.WEIGHT,
        health_plugin.HealthDataType.STEPS,
        health_plugin.HealthDataType.ACTIVE_ENERGY_BURNED,
        health_plugin.HealthDataType.WORKOUT,
      ]);
    });
  });
}
