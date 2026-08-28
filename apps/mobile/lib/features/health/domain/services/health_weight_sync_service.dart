import '../../../weight_tracking/domain/entities/weight_entry.dart';
import '../../../weight_tracking/domain/repositories/weight_entry_store.dart';
import '../entities/health_data_type.dart';
import '../entities/health_weight_sample.dart';
import '../repositories/health_data_repository.dart';

enum HealthWeightSyncStatus { synced, unavailable, accessNeeded }

class HealthWeightSyncResult {
  const HealthWeightSyncResult({
    required this.status,
    this.platform = HealthPlatform.unsupported,
    this.fetchedCount = 0,
    this.importedCount = 0,
    this.updatedCount = 0,
    this.skippedCount = 0,
  });

  final HealthWeightSyncStatus status;
  final HealthPlatform platform;
  final int fetchedCount;
  final int importedCount;
  final int updatedCount;
  final int skippedCount;

  bool get hasChanges => importedCount > 0 || updatedCount > 0;
}

class HealthWeightSyncService {
  const HealthWeightSyncService(this._healthRepository, this._weightStore);

  static const Duration defaultLookback = Duration(days: 30);

  final HealthWeightDataRepository _healthRepository;
  final WeightEntryStore _weightStore;

  Future<HealthWeightSyncResult> sync({
    DateTime? now,
    Duration lookback = defaultLookback,
  }) async {
    if (lookback <= Duration.zero) {
      throw ArgumentError.value(
        lookback,
        'lookback',
        'Lookback must be greater than zero.',
      );
    }

    final availability = await _healthRepository.checkAvailability();

    if (!availability.isAvailable ||
        !_isSupportedPlatform(availability.platform)) {
      return HealthWeightSyncResult(
        status: HealthWeightSyncStatus.unavailable,
        platform: availability.platform,
      );
    }

    final accessStatus = await _healthRepository.getAccessStatus(const {
      HealthDataType.bodyWeight,
    });

    if (!_canReadWeight(
      platform: availability.platform,
      accessStatus: accessStatus,
    )) {
      return HealthWeightSyncResult(
        status: HealthWeightSyncStatus.accessNeeded,
        platform: availability.platform,
      );
    }

    final syncEnd = now ?? DateTime.now();
    final syncStart = syncEnd.subtract(lookback);

    final samples = await _healthRepository.readWeightSamples(
      startTime: syncStart,
      endTime: syncEnd,
    );

    final existingEntries = await _weightStore.loadEntries();
    final mergedEntries = List<WeightEntry>.from(existingEntries);

    final indexById = <String, int>{
      for (var index = 0; index < mergedEntries.length; index++)
        mergedEntries[index].id: index,
    };

    final uniqueSamples = <String, HealthWeightSample>{};
    var skippedCount = 0;

    for (final sample in samples) {
      final externalId = sample.externalId.trim();

      if (externalId.isEmpty ||
          !sample.weightKg.isFinite ||
          sample.weightKg <= 0) {
        skippedCount++;
        continue;
      }

      if (uniqueSamples.containsKey(externalId)) {
        skippedCount++;
      }

      uniqueSamples[externalId] = sample;
    }

    final importConfig = _importConfigFor(availability.platform);

    var importedCount = 0;
    var updatedCount = 0;

    for (final entry in uniqueSamples.entries) {
      final externalId = entry.key;
      final sample = entry.value;
      final entryId = '${importConfig.entryIdPrefix}$externalId';

      final importedEntry = WeightEntry(
        id: entryId,
        weightKg: sample.weightKg,
        measuredAt: sample.measuredAt,
        source: importConfig.weightSource,
      );

      final existingIndex = indexById[entryId];

      if (existingIndex == null) {
        indexById[entryId] = mergedEntries.length;
        mergedEntries.add(importedEntry);
        importedCount++;
        continue;
      }

      final existing = mergedEntries[existingIndex];

      if (existing.source != importConfig.weightSource) {
        skippedCount++;
        continue;
      }

      final unchanged =
          existing.weightKg == importedEntry.weightKg &&
          existing.measuredAt == importedEntry.measuredAt;

      if (unchanged) {
        skippedCount++;
        continue;
      }

      mergedEntries[existingIndex] = importedEntry;
      updatedCount++;
    }

    if (importedCount > 0 || updatedCount > 0) {
      await _weightStore.saveEntries(mergedEntries);
    }

    return HealthWeightSyncResult(
      status: HealthWeightSyncStatus.synced,
      platform: availability.platform,
      fetchedCount: samples.length,
      importedCount: importedCount,
      updatedCount: updatedCount,
      skippedCount: skippedCount,
    );
  }

  bool _isSupportedPlatform(HealthPlatform platform) {
    return platform == HealthPlatform.healthConnect ||
        platform == HealthPlatform.appleHealth;
  }

  bool _canReadWeight({
    required HealthPlatform platform,
    required HealthAccessStatus accessStatus,
  }) {
    if (accessStatus == HealthAccessStatus.granted) {
      return true;
    }

    return platform == HealthPlatform.appleHealth &&
        accessStatus == HealthAccessStatus.unknown;
  }

  _HealthWeightImportConfig _importConfigFor(HealthPlatform platform) {
    return switch (platform) {
      HealthPlatform.healthConnect => const _HealthWeightImportConfig(
        entryIdPrefix: 'health-connect:',
        weightSource: WeightSource.healthConnect,
      ),
      HealthPlatform.appleHealth => const _HealthWeightImportConfig(
        entryIdPrefix: 'apple-health:',
        weightSource: WeightSource.appleHealth,
      ),
      HealthPlatform.unsupported => throw StateError(
        'Unsupported health platform cannot import weight.',
      ),
    };
  }
}

class _HealthWeightImportConfig {
  const _HealthWeightImportConfig({
    required this.entryIdPrefix,
    required this.weightSource,
  });

  final String entryIdPrefix;
  final WeightSource weightSource;
}
