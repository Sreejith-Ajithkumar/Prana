import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/features/health/domain/entities/health_data_type.dart';
import 'package:mobile/features/health/domain/repositories/health_data_repository.dart';
import 'package:mobile/features/health/presentation/health_wearables_screen.dart';

void main() {
  group('HealthWearablesScreen', () {
    testWidgets('shows connected state when health access is granted', (
      tester,
    ) async {
      final repository = FakeHealthDataRepository(
        accessStatus: HealthAccessStatus.granted,
      );

      await tester.pumpWidget(
        MaterialApp(home: HealthWearablesScreen(repository: repository)),
      );

      await tester.pumpAndSettle();

      expect(find.text('Health & wearables'), findsOneWidget);

      expect(find.text('Connected'), findsOneWidget);

      expect(find.text('Body weight'), findsOneWidget);

      expect(find.text('Steps'), findsOneWidget);

      expect(find.text('Active energy'), findsOneWidget);

      expect(find.text('Workouts'), findsOneWidget);
    });

    testWidgets('requests health access when connect is tapped', (
      tester,
    ) async {
      final repository = FakeHealthDataRepository(
        accessStatus: HealthAccessStatus.denied,
        requestedStatus: HealthAccessStatus.granted,
      );

      await tester.pumpWidget(
        MaterialApp(home: HealthWearablesScreen(repository: repository)),
      );

      await tester.pumpAndSettle();

      expect(find.text('Access needed'), findsOneWidget);

      await tester.tap(find.text('Connect Health Connect'));

      await tester.pumpAndSettle();

      expect(repository.requestAccessCalls, 1);

      expect(find.text('Connected'), findsOneWidget);
    });

    testWidgets('opens health settings from manage access', (tester) async {
      final repository = FakeHealthDataRepository(
        accessStatus: HealthAccessStatus.granted,
      );

      await tester.pumpWidget(
        MaterialApp(home: HealthWearablesScreen(repository: repository)),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Manage access'));

      await tester.pumpAndSettle();

      expect(repository.openSettingsCalls, 1);
    });

    testWidgets('shows unavailable state without connect controls', (
      tester,
    ) async {
      final repository = FakeHealthDataRepository(
        available: false,
        accessStatus: HealthAccessStatus.unavailable,
      );

      await tester.pumpWidget(
        MaterialApp(home: HealthWearablesScreen(repository: repository)),
      );

      await tester.pumpAndSettle();

      expect(find.text('Unavailable'), findsOneWidget);

      expect(find.text('Connect Health Connect'), findsNothing);

      expect(find.text('Manage access'), findsNothing);
    });
  });
}

class FakeHealthDataRepository implements HealthDataRepository {
  FakeHealthDataRepository({
    this.available = true,
    this.accessStatus = HealthAccessStatus.denied,
    HealthAccessStatus? requestedStatus,
  }) : requestedStatus = requestedStatus ?? accessStatus;

  final bool available;

  HealthAccessStatus accessStatus;
  final HealthAccessStatus requestedStatus;

  int requestAccessCalls = 0;
  int openSettingsCalls = 0;

  @override
  Future<HealthAvailability> checkAvailability() async {
    return HealthAvailability(
      platform: HealthPlatform.healthConnect,
      isAvailable: available,
    );
  }

  @override
  Future<HealthAccessStatus> getAccessStatus(
    Set<HealthDataType> dataTypes,
  ) async {
    if (!available) {
      return HealthAccessStatus.unavailable;
    }

    return accessStatus;
  }

  @override
  Future<HealthAccessStatus> requestAccess(
    Set<HealthDataType> dataTypes,
  ) async {
    requestAccessCalls++;
    accessStatus = requestedStatus;
    return accessStatus;
  }

  @override
  Future<void> openHealthSettings() async {
    openSettingsCalls++;
  }
}
