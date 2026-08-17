import '../entities/health_data_type.dart';

abstract interface class HealthDataRepository {
  Future<HealthAvailability> checkAvailability();

  Future<HealthAccessStatus> getAccessStatus(Set<HealthDataType> dataTypes);

  Future<HealthAccessStatus> requestAccess(Set<HealthDataType> dataTypes);

  Future<void> openHealthSettings();
}
