import 'package:health/health.dart' as health_plugin;

import '../../domain/entities/health_data_type.dart';

class HealthPluginTypeMapper {
  const HealthPluginTypeMapper();

  health_plugin.HealthDataType toPluginType(HealthDataType type) {
    return switch (type) {
      HealthDataType.bodyWeight => health_plugin.HealthDataType.WEIGHT,

      HealthDataType.steps => health_plugin.HealthDataType.STEPS,

      HealthDataType.activeEnergyBurned =>
        health_plugin.HealthDataType.ACTIVE_ENERGY_BURNED,

      HealthDataType.workout => health_plugin.HealthDataType.WORKOUT,
    };
  }

  List<health_plugin.HealthDataType> toPluginTypes(
    Iterable<HealthDataType> types,
  ) {
    return types.map(toPluginType).toList(growable: false);
  }
}
