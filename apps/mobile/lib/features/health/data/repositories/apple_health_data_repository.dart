import 'package:health/health.dart' as health_plugin;

import '../../domain/entities/health_activity_sample.dart';
import '../../domain/entities/health_data_type.dart';
import '../../domain/entities/health_weight_sample.dart';
import '../../domain/repositories/health_data_repository.dart';
import '../clients/health_plugin_client.dart';
import '../mappers/health_plugin_type_mapper.dart';
import '../settings/health_settings_launcher.dart';
import '../storage/apple_health_authorization_store.dart';

class AppleHealthDataRepository
    implements HealthWeightDataRepository, HealthActivityDataRepository {
  AppleHealthDataRepository({
    HealthPluginClient? healthClient,
    this.mapper = const HealthPluginTypeMapper(),
    this._authorizationStore,
    HealthSettingsLauncher? settingsLauncher,
  }) : _healthClient = healthClient ?? DefaultHealthPluginClient(),
       _settingsLauncher =
           settingsLauncher ?? const MethodChannelHealthSettingsLauncher();
  final HealthPluginClient _healthClient;
  final HealthPluginTypeMapper mapper;
  AppleHealthAuthorizationStore? _authorizationStore;
  final HealthSettingsLauncher _settingsLauncher;

  bool _configured = false;

  Future<void> _ensureConfigured() async {
    if (_configured) {
      return;
    }

    await _healthClient.configure();
    _configured = true;
  }

  @override
  Future<HealthAvailability> checkAvailability() async {
    await _ensureConfigured();

    // This repository is selected only for iOS by the platform factory.
    // Final device-level HealthKit availability is validated on iOS itself.
    return const HealthAvailability(
      platform: HealthPlatform.appleHealth,
      isAvailable: true,
    );
  }

  @override
  Future<HealthAccessStatus> getAccessStatus(
    Set<HealthDataType> dataTypes,
  ) async {
    if (dataTypes.isEmpty) {
      return HealthAccessStatus.granted;
    }

    final availability = await checkAvailability();

    if (!availability.isAvailable) {
      return HealthAccessStatus.unavailable;
    }

    final hasRequestedAuthorization = await _getAuthorizationStore()
        .hasRequestedAuthorization();

    if (!hasRequestedAuthorization) {
      return HealthAccessStatus.notRequested;
    }

    // HealthKit intentionally does not reveal whether read access to an
    // individual type was granted or denied. After the authorization sheet
    // has been reviewed, the only accurate shared-domain state is unknown.
    return HealthAccessStatus.unknown;
  }

  @override
  Future<HealthAccessStatus> requestAccess(
    Set<HealthDataType> dataTypes,
  ) async {
    if (dataTypes.isEmpty) {
      return HealthAccessStatus.granted;
    }

    final availability = await checkAvailability();

    if (!availability.isAvailable) {
      return HealthAccessStatus.unavailable;
    }

    final pluginTypes = mapper.toPluginTypes(dataTypes);

    final permissions = List<health_plugin.HealthDataAccess>.filled(
      pluginTypes.length,
      health_plugin.HealthDataAccess.READ,
      growable: false,
    );

    final requestCompleted = await _healthClient.requestAuthorization(
      pluginTypes,
      permissions: permissions,
    );

    if (!requestCompleted) {
      return HealthAccessStatus.denied;
    }

    await _getAuthorizationStore().markAuthorizationRequested();

    // A successful HealthKit authorization request means the sheet was
    // processed. It does not reveal which read types were allowed.
    return HealthAccessStatus.unknown;
  }

  AppleHealthAuthorizationStore _getAuthorizationStore() {
    return _authorizationStore ??=
        SharedPreferencesAppleHealthAuthorizationStore();
  }

  @override
  Future<List<HealthWeightSample>> readWeightSamples({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    _validateTimeRange(startTime: startTime, endTime: endTime);

    final dataPoints = await _readDataPoints(
      type: health_plugin.HealthDataType.WEIGHT,
      startTime: startTime,
      endTime: endTime,
    );

    final samples = <HealthWeightSample>[];

    for (final point in dataPoints) {
      final value = point.value;

      if (value is! health_plugin.NumericHealthValue) {
        continue;
      }

      final weightKg = value.numericValue.toDouble();
      final externalId = point.uuid.trim();

      if (!weightKg.isFinite || weightKg <= 0 || externalId.isEmpty) {
        continue;
      }

      samples.add(
        HealthWeightSample(
          externalId: externalId,
          weightKg: weightKg,
          measuredAt: point.dateFrom,
          sourceName: _sourceName(point),
        ),
      );
    }

    samples.sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

    return samples;
  }

  @override
  Future<List<HealthStepsSample>> readStepSamples({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    _validateTimeRange(startTime: startTime, endTime: endTime);

    final dataPoints = await _readDataPoints(
      type: health_plugin.HealthDataType.STEPS,
      startTime: startTime,
      endTime: endTime,
    );

    final samples = <HealthStepsSample>[];

    for (final point in dataPoints) {
      final value = point.value;

      if (value is! health_plugin.NumericHealthValue) {
        continue;
      }

      final numericSteps = value.numericValue.toDouble();
      final externalId = point.uuid.trim();

      if (!numericSteps.isFinite ||
          numericSteps < 0 ||
          externalId.isEmpty ||
          point.dateTo.isBefore(point.dateFrom)) {
        continue;
      }

      samples.add(
        HealthStepsSample(
          externalId: externalId,
          steps: numericSteps.round(),
          startTime: point.dateFrom,
          endTime: point.dateTo,
          sourceName: _sourceName(point),
        ),
      );
    }

    samples.sort((a, b) => a.startTime.compareTo(b.startTime));

    return samples;
  }

  @override
  Future<List<HealthActiveEnergySample>> readActiveEnergySamples({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    _validateTimeRange(startTime: startTime, endTime: endTime);

    final dataPoints = await _readDataPoints(
      type: health_plugin.HealthDataType.ACTIVE_ENERGY_BURNED,
      startTime: startTime,
      endTime: endTime,
    );

    final samples = <HealthActiveEnergySample>[];

    for (final point in dataPoints) {
      final value = point.value;

      if (value is! health_plugin.NumericHealthValue) {
        continue;
      }

      final kilocalories = value.numericValue.toDouble();
      final externalId = point.uuid.trim();

      if (!kilocalories.isFinite ||
          kilocalories < 0 ||
          externalId.isEmpty ||
          point.dateTo.isBefore(point.dateFrom)) {
        continue;
      }

      samples.add(
        HealthActiveEnergySample(
          externalId: externalId,
          kilocalories: kilocalories,
          startTime: point.dateFrom,
          endTime: point.dateTo,
          sourceName: _sourceName(point),
        ),
      );
    }

    samples.sort((a, b) => a.startTime.compareTo(b.startTime));

    return samples;
  }

  @override
  Future<List<HealthWorkoutSample>> readWorkoutSamples({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    _validateTimeRange(startTime: startTime, endTime: endTime);

    final dataPoints = await _readDataPoints(
      type: health_plugin.HealthDataType.WORKOUT,
      startTime: startTime,
      endTime: endTime,
    );

    final samples = <HealthWorkoutSample>[];

    for (final point in dataPoints) {
      final value = point.value;
      final externalId = point.uuid.trim();

      if (value is! health_plugin.WorkoutHealthValue ||
          externalId.isEmpty ||
          !point.dateFrom.isBefore(point.dateTo)) {
        continue;
      }

      samples.add(
        HealthWorkoutSample(
          externalId: externalId,
          kind: _mapWorkoutKind(value.workoutActivityType),
          startTime: point.dateFrom,
          endTime: point.dateTo,
          sourceName: _sourceName(point),
        ),
      );
    }

    samples.sort((a, b) => a.startTime.compareTo(b.startTime));

    return samples;
  }

  Future<List<health_plugin.HealthDataPoint>> _readDataPoints({
    required health_plugin.HealthDataType type,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    await _ensureConfigured();

    final dataPoints = await _healthClient.getHealthDataFromTypes(
      types: [type],
      startTime: startTime,
      endTime: endTime,
    );

    return dataPoints
        .where((point) => point.type == type)
        .toList(growable: false);
  }

  void _validateTimeRange({
    required DateTime startTime,
    required DateTime endTime,
  }) {
    if (!startTime.isBefore(endTime)) {
      throw ArgumentError('startTime must be before endTime.');
    }
  }

  String? _sourceName(health_plugin.HealthDataPoint point) {
    final sourceName = point.sourceName.trim();

    return sourceName.isEmpty ? null : sourceName;
  }

  HealthWorkoutKind _mapWorkoutKind(
    health_plugin.HealthWorkoutActivityType type,
  ) {
    if (const {
      health_plugin.HealthWorkoutActivityType.WALKING,
      health_plugin.HealthWorkoutActivityType.WALKING_TREADMILL,
    }.contains(type)) {
      return HealthWorkoutKind.walking;
    }

    if (const {
      health_plugin.HealthWorkoutActivityType.RUNNING,
      health_plugin.HealthWorkoutActivityType.RUNNING_TREADMILL,
    }.contains(type)) {
      return HealthWorkoutKind.running;
    }

    if (const {
      health_plugin.HealthWorkoutActivityType.BIKING,
      health_plugin.HealthWorkoutActivityType.BIKING_STATIONARY,
      health_plugin.HealthWorkoutActivityType.HAND_CYCLING,
    }.contains(type)) {
      return HealthWorkoutKind.cycling;
    }

    if (const {
      health_plugin.HealthWorkoutActivityType.SWIMMING,
      health_plugin.HealthWorkoutActivityType.SWIMMING_OPEN_WATER,
      health_plugin.HealthWorkoutActivityType.SWIMMING_POOL,
    }.contains(type)) {
      return HealthWorkoutKind.swimming;
    }

    if (const {
      health_plugin.HealthWorkoutActivityType.STRENGTH_TRAINING,
      health_plugin.HealthWorkoutActivityType.WEIGHTLIFTING,
      health_plugin.HealthWorkoutActivityType.FUNCTIONAL_STRENGTH_TRAINING,
      health_plugin.HealthWorkoutActivityType.TRADITIONAL_STRENGTH_TRAINING,
      health_plugin.HealthWorkoutActivityType.CALISTHENICS,
    }.contains(type)) {
      return HealthWorkoutKind.strengthTraining;
    }

    return HealthWorkoutKind.other;
  }

  @override
  Future<void> openHealthSettings() {
    return _settingsLauncher.openHealthSettings();
  }
}
