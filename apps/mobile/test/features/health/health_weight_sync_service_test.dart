import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/health/domain/entities/health_data_type.dart';
import 'package:mobile/features/health/domain/entities/health_weight_sample.dart';
import 'package:mobile/features/health/domain/repositories/health_data_repository.dart';
import 'package:mobile/features/health/domain/services/health_weight_sync_service.dart';
import 'package:mobile/features/weight_tracking/domain/entities/weight_entry.dart';
import 'package:mobile/features/weight_tracking/domain/repositories/weight_entry_store.dart';

void main() {
  group('HealthWeightSyncService', () {
    test('returns unavailable without reading health data', () async {
      final healthRepository = FakeHealthWeightDataRepository(available: false);

      final weightStore = FakeWeightEntryStore();
      final service = HealthWeightSyncService(healthRepository, weightStore);

      final result = await service.sync(now: DateTime(2026, 8, 19));

      expect(result.status, HealthWeightSyncStatus.unavailable);
      expect(result.platform, HealthPlatform.healthConnect);
      expect(healthRepository.readCalls, 0);
      expect(weightStore.saveCalls, 0);
    });

    test('returns access needed without reading weight', () async {
      final healthRepository = FakeHealthWeightDataRepository(
        accessStatus: HealthAccessStatus.denied,
      );

      final service = HealthWeightSyncService(
        healthRepository,
        FakeWeightEntryStore(),
      );

      final result = await service.sync(now: DateTime(2026, 8, 19));

      expect(result.status, HealthWeightSyncStatus.accessNeeded);
      expect(healthRepository.readCalls, 0);
    });

    test('imports Health Connect weight into weight history', () async {
      final measuredAt = DateTime(2026, 8, 18, 7, 30);

      final healthRepository = FakeHealthWeightDataRepository(
        samples: [
          HealthWeightSample(
            externalId: 'weight-123',
            weightKg: 63.4,
            measuredAt: measuredAt,
            sourceName: 'Smart Scale',
          ),
        ],
      );

      final weightStore = FakeWeightEntryStore();
      final service = HealthWeightSyncService(healthRepository, weightStore);

      final result = await service.sync(now: DateTime(2026, 8, 19));

      expect(result.status, HealthWeightSyncStatus.synced);
      expect(result.platform, HealthPlatform.healthConnect);
      expect(result.fetchedCount, 1);
      expect(result.importedCount, 1);
      expect(result.updatedCount, 0);

      final imported = weightStore.entries.single;

      expect(imported.id, 'health-connect:weight-123');
      expect(imported.weightKg, 63.4);
      expect(imported.measuredAt, measuredAt);
      expect(imported.source, WeightSource.healthConnect);
    });

    test('imports Apple Health weight with Apple-specific identity', () async {
      final measuredAt = DateTime(2026, 8, 27, 8, 15);

      final healthRepository = FakeHealthWeightDataRepository(
        platform: HealthPlatform.appleHealth,
        accessStatus: HealthAccessStatus.unknown,
        samples: [
          HealthWeightSample(
            externalId: 'apple-weight-1',
            weightKg: 62.8,
            measuredAt: measuredAt,
            sourceName: 'Apple Health',
          ),
        ],
      );

      final weightStore = FakeWeightEntryStore();
      final service = HealthWeightSyncService(healthRepository, weightStore);

      final result = await service.sync(now: DateTime(2026, 8, 28));

      expect(result.status, HealthWeightSyncStatus.synced);
      expect(result.platform, HealthPlatform.appleHealth);
      expect(result.importedCount, 1);

      final imported = weightStore.entries.single;

      expect(imported.id, 'apple-health:apple-weight-1');
      expect(imported.weightKg, 62.8);
      expect(imported.measuredAt, measuredAt);
      expect(imported.source, WeightSource.appleHealth);
    });

    test(
      'does not read Apple Health weight before authorization is reviewed',
      () async {
        final healthRepository = FakeHealthWeightDataRepository(
          platform: HealthPlatform.appleHealth,
          accessStatus: HealthAccessStatus.notRequested,
        );

        final service = HealthWeightSyncService(
          healthRepository,
          FakeWeightEntryStore(),
        );

        final result = await service.sync(now: DateTime(2026, 8, 28));

        expect(result.status, HealthWeightSyncStatus.accessNeeded);
        expect(result.platform, HealthPlatform.appleHealth);
        expect(healthRepository.readCalls, 0);
      },
    );

    test(
      'repeated Health Connect sync does not duplicate imported weight',
      () async {
        final sample = HealthWeightSample(
          externalId: 'weight-123',
          weightKg: 63.4,
          measuredAt: DateTime(2026, 8, 18, 7, 30),
        );

        final healthRepository = FakeHealthWeightDataRepository(
          samples: [sample],
        );
        final weightStore = FakeWeightEntryStore();
        final service = HealthWeightSyncService(healthRepository, weightStore);

        await service.sync(now: DateTime(2026, 8, 19));
        final secondResult = await service.sync(now: DateTime(2026, 8, 19));

        expect(weightStore.entries, hasLength(1));
        expect(secondResult.importedCount, 0);
        expect(secondResult.updatedCount, 0);
        expect(secondResult.skippedCount, 1);
        expect(weightStore.saveCalls, 1);
      },
    );

    test(
      'repeated Apple Health sync does not duplicate imported weight',
      () async {
        final sample = HealthWeightSample(
          externalId: 'apple-weight-1',
          weightKg: 62.8,
          measuredAt: DateTime(2026, 8, 27, 8, 15),
        );

        final healthRepository = FakeHealthWeightDataRepository(
          platform: HealthPlatform.appleHealth,
          accessStatus: HealthAccessStatus.unknown,
          samples: [sample],
        );
        final weightStore = FakeWeightEntryStore();
        final service = HealthWeightSyncService(healthRepository, weightStore);

        await service.sync(now: DateTime(2026, 8, 28));
        final secondResult = await service.sync(now: DateTime(2026, 8, 28));

        expect(weightStore.entries, hasLength(1));
        expect(secondResult.importedCount, 0);
        expect(secondResult.updatedCount, 0);
        expect(secondResult.skippedCount, 1);
        expect(weightStore.saveCalls, 1);
      },
    );

    test(
      'updates an existing Health Connect entry with the same external id',
      () async {
        final weightStore = FakeWeightEntryStore(
          entries: [
            WeightEntry(
              id: 'health-connect:weight-123',
              weightKg: 64,
              measuredAt: DateTime(2026, 8, 18, 7),
              source: WeightSource.healthConnect,
            ),
          ],
        );

        final healthRepository = FakeHealthWeightDataRepository(
          samples: [
            HealthWeightSample(
              externalId: 'weight-123',
              weightKg: 63.6,
              measuredAt: DateTime(2026, 8, 18, 7, 30),
            ),
          ],
        );

        final service = HealthWeightSyncService(healthRepository, weightStore);

        final result = await service.sync(now: DateTime(2026, 8, 19));

        expect(result.importedCount, 0);
        expect(result.updatedCount, 1);
        expect(weightStore.entries, hasLength(1));
        expect(weightStore.entries.single.weightKg, 63.6);
      },
    );

    test(
      'updates an existing Apple Health entry with the same external id',
      () async {
        final weightStore = FakeWeightEntryStore(
          entries: [
            WeightEntry(
              id: 'apple-health:apple-weight-1',
              weightKg: 63.1,
              measuredAt: DateTime(2026, 8, 27, 7),
              source: WeightSource.appleHealth,
            ),
          ],
        );

        final healthRepository = FakeHealthWeightDataRepository(
          platform: HealthPlatform.appleHealth,
          accessStatus: HealthAccessStatus.unknown,
          samples: [
            HealthWeightSample(
              externalId: 'apple-weight-1',
              weightKg: 62.9,
              measuredAt: DateTime(2026, 8, 27, 7, 20),
            ),
          ],
        );

        final service = HealthWeightSyncService(healthRepository, weightStore);

        final result = await service.sync(now: DateTime(2026, 8, 28));

        expect(result.importedCount, 0);
        expect(result.updatedCount, 1);
        expect(weightStore.entries, hasLength(1));
        expect(weightStore.entries.single.weightKg, 62.9);
      },
    );

    test('preserves manual weight entries', () async {
      final manualEntry = WeightEntry(
        id: 'manual-1',
        weightKg: 64.2,
        measuredAt: DateTime(2026, 8, 17),
        source: WeightSource.manual,
      );

      final weightStore = FakeWeightEntryStore(entries: [manualEntry]);

      final healthRepository = FakeHealthWeightDataRepository(
        samples: [
          HealthWeightSample(
            externalId: 'weight-123',
            weightKg: 63.8,
            measuredAt: DateTime(2026, 8, 18),
          ),
        ],
      );

      final service = HealthWeightSyncService(healthRepository, weightStore);

      await service.sync(now: DateTime(2026, 8, 19));

      expect(weightStore.entries, hasLength(2));
      expect(
        weightStore.entries.any(
          (entry) =>
              entry.id == manualEntry.id && entry.source == WeightSource.manual,
        ),
        isTrue,
      );
    });

    test('keeps Health Connect and Apple Health records distinct', () async {
      final weightStore = FakeWeightEntryStore(
        entries: [
          WeightEntry(
            id: 'health-connect:shared-id',
            weightKg: 64,
            measuredAt: DateTime(2026, 8, 27, 7),
            source: WeightSource.healthConnect,
          ),
        ],
      );

      final healthRepository = FakeHealthWeightDataRepository(
        platform: HealthPlatform.appleHealth,
        accessStatus: HealthAccessStatus.unknown,
        samples: [
          HealthWeightSample(
            externalId: 'shared-id',
            weightKg: 63.8,
            measuredAt: DateTime(2026, 8, 27, 8),
          ),
        ],
      );

      final service = HealthWeightSyncService(healthRepository, weightStore);

      final result = await service.sync(now: DateTime(2026, 8, 28));

      expect(result.importedCount, 1);
      expect(weightStore.entries, hasLength(2));

      expect(
        weightStore.entries.any(
          (entry) =>
              entry.id == 'health-connect:shared-id' &&
              entry.source == WeightSource.healthConnect,
        ),
        isTrue,
      );

      expect(
        weightStore.entries.any(
          (entry) =>
              entry.id == 'apple-health:shared-id' &&
              entry.source == WeightSource.appleHealth,
        ),
        isTrue,
      );
    });

    test('uses a 30 day default sync window', () async {
      final healthRepository = FakeHealthWeightDataRepository();

      final service = HealthWeightSyncService(
        healthRepository,
        FakeWeightEntryStore(),
      );

      final now = DateTime(2026, 8, 19, 12);

      await service.sync(now: now);

      expect(healthRepository.lastEndTime, now);
      expect(
        healthRepository.lastStartTime,
        now.subtract(const Duration(days: 30)),
      );
    });
  });
}

class FakeHealthWeightDataRepository implements HealthWeightDataRepository {
  FakeHealthWeightDataRepository({
    this.available = true,
    this.platform = HealthPlatform.healthConnect,
    this.accessStatus = HealthAccessStatus.granted,
    List<HealthWeightSample>? samples,
  }) : samples = samples ?? <HealthWeightSample>[];

  final bool available;
  final HealthPlatform platform;
  final HealthAccessStatus accessStatus;
  final List<HealthWeightSample> samples;

  int readCalls = 0;

  DateTime? lastStartTime;
  DateTime? lastEndTime;

  @override
  Future<HealthAvailability> checkAvailability() async {
    return HealthAvailability(platform: platform, isAvailable: available);
  }

  @override
  Future<HealthAccessStatus> getAccessStatus(
    Set<HealthDataType> dataTypes,
  ) async {
    return available ? accessStatus : HealthAccessStatus.unavailable;
  }

  @override
  Future<HealthAccessStatus> requestAccess(
    Set<HealthDataType> dataTypes,
  ) async {
    return accessStatus;
  }

  @override
  Future<List<HealthWeightSample>> readWeightSamples({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    readCalls++;
    lastStartTime = startTime;
    lastEndTime = endTime;

    return List<HealthWeightSample>.from(samples);
  }

  @override
  Future<void> openHealthSettings() async {}
}

class FakeWeightEntryStore implements WeightEntryStore {
  FakeWeightEntryStore({List<WeightEntry>? entries})
    : entries = List<WeightEntry>.from(entries ?? const []);

  List<WeightEntry> entries;

  int saveCalls = 0;

  @override
  Future<List<WeightEntry>> loadEntries() async {
    return List<WeightEntry>.from(entries);
  }

  @override
  Future<void> saveEntries(List<WeightEntry> entries) async {
    saveCalls++;

    this.entries = List<WeightEntry>.from(entries)
      ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
  }
}
