import '../entities/health_activity_sample.dart';
import '../entities/health_data_type.dart';
import '../entities/health_weight_sample.dart';

abstract interface class HealthDataRepository {
  Future<HealthAvailability> checkAvailability();

  Future<HealthAccessStatus> getAccessStatus(Set<HealthDataType> dataTypes);

  Future<HealthAccessStatus> requestAccess(Set<HealthDataType> dataTypes);

  Future<void> openHealthSettings();
}

abstract interface class HealthWeightDataRepository
    implements HealthDataRepository {
  Future<List<HealthWeightSample>> readWeightSamples({
    required DateTime startTime,
    required DateTime endTime,
  });
}

abstract interface class HealthActivityDataRepository
    implements HealthDataRepository {
  Future<List<HealthStepsSample>> readStepSamples({
    required DateTime startTime,
    required DateTime endTime,
  });

  Future<List<HealthActiveEnergySample>> readActiveEnergySamples({
    required DateTime startTime,
    required DateTime endTime,
  });

  Future<List<HealthWorkoutSample>> readWorkoutSamples({
    required DateTime startTime,
    required DateTime endTime,
  });
}
