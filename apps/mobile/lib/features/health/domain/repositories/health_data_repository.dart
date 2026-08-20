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
