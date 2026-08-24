import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/features/dashboard/presentation/dashboard_screen.dart';
import 'package:mobile/features/health/domain/services/health_daily_activity_summary_service.dart';
import 'package:mobile/features/health/domain/services/health_today_activity_service.dart';

void main() {
  group('DashboardActivityCard', () {
    testWidgets('shows loading state', (tester) async {
      await tester.pumpWidget(
        _buildCard(isLoading: true, result: null, hasError: false),
      );

      expect(
        find.text('Loading activity from Health Connect...'),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows ready activity summary with connected metrics', (
      tester,
    ) async {
      const summary = HealthDailyActivitySummary(
        steps: 7842,
        activeEnergyKcal: 425.6,
        workoutCount: 1,
        workoutDuration: Duration(minutes: 42),
      );

      await tester.pumpWidget(
        _buildCard(
          isLoading: false,
          result: const HealthTodayActivityResult(
            status: HealthTodayActivityStatus.ready,
            summary: summary,
            hasStepsAccess: true,
            hasActiveEnergyAccess: true,
            hasWorkoutAccess: true,
          ),
          hasError: false,
        ),
      );

      expect(find.text('7,842'), findsOneWidget);
      expect(find.text('426 kcal'), findsOneWidget);
      expect(find.text('1 workout'), findsOneWidget);
      expect(find.text('42 min'), findsOneWidget);
      expect(find.text('Connected'), findsNWidgets(4));
      expect(find.text('Not connected'), findsNothing);
      expect(
        find.text(
          'Active energy is informational and does not change your '
          'nutrition target.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows empty activity state when all access is connected', (
      tester,
    ) async {
      const summary = HealthDailyActivitySummary(
        steps: 0,
        activeEnergyKcal: 0,
        workoutCount: 0,
        workoutDuration: Duration.zero,
      );

      await tester.pumpWidget(
        _buildCard(
          isLoading: false,
          result: const HealthTodayActivityResult(
            status: HealthTodayActivityStatus.ready,
            summary: summary,
            hasStepsAccess: true,
            hasActiveEnergyAccess: true,
            hasWorkoutAccess: true,
          ),
          hasError: false,
        ),
      );

      expect(find.text('No activity recorded today yet'), findsOneWidget);
    });

    testWidgets('shows manage access action when no activity access exists', (
      tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        _buildCard(
          isLoading: false,
          result: const HealthTodayActivityResult(
            status: HealthTodayActivityStatus.accessNeeded,
          ),
          hasError: false,
          onManageAccess: () {
            tapped = true;
          },
        ),
      );

      expect(find.text('Connect activity data'), findsOneWidget);
      expect(find.text('Manage Health access'), findsOneWidget);

      await tester.tap(find.text('Manage Health access'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('shows connected and disconnected metrics for partial access', (
      tester,
    ) async {
      const summary = HealthDailyActivitySummary(
        steps: 6400,
        activeEnergyKcal: 0,
        workoutCount: 0,
        workoutDuration: Duration.zero,
      );

      await tester.pumpWidget(
        _buildCard(
          isLoading: false,
          result: const HealthTodayActivityResult(
            status: HealthTodayActivityStatus.ready,
            summary: summary,
            hasStepsAccess: true,
            hasActiveEnergyAccess: false,
            hasWorkoutAccess: false,
          ),
          hasError: false,
        ),
      );

      expect(find.text('6,400'), findsOneWidget);
      expect(find.text('Connected'), findsOneWidget);
      expect(find.text('Not connected'), findsNWidgets(3));
      expect(
        find.text(
          'Some activity permissions are off. Connected metrics '
          'still update normally.',
        ),
        findsOneWidget,
      );
      expect(find.text('Manage Health access'), findsOneWidget);
    });

    testWidgets('partial access manage action is tappable', (tester) async {
      var tapped = false;

      const summary = HealthDailyActivitySummary(
        steps: 1200,
        activeEnergyKcal: 0,
        workoutCount: 0,
        workoutDuration: Duration.zero,
      );

      await tester.pumpWidget(
        _buildCard(
          isLoading: false,
          result: const HealthTodayActivityResult(
            status: HealthTodayActivityStatus.ready,
            summary: summary,
            hasStepsAccess: true,
            hasActiveEnergyAccess: false,
            hasWorkoutAccess: false,
          ),
          hasError: false,
          onManageAccess: () {
            tapped = true;
          },
        ),
      );

      await tester.tap(find.text('Manage Health access'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('shows unavailable state', (tester) async {
      await tester.pumpWidget(
        _buildCard(
          isLoading: false,
          result: const HealthTodayActivityResult(
            status: HealthTodayActivityStatus.unavailable,
          ),
          hasError: false,
        ),
      );

      expect(find.text('Health activity unavailable'), findsOneWidget);
    });

    testWidgets('shows retry action after activity load error', (tester) async {
      var retried = false;

      await tester.pumpWidget(
        _buildCard(
          isLoading: false,
          result: null,
          hasError: true,
          onRetry: () {
            retried = true;
          },
        ),
      );

      expect(find.text('Activity could not be refreshed'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(retried, isTrue);
    });
  });
}

Widget _buildCard({
  required bool isLoading,
  required HealthTodayActivityResult? result,
  required bool hasError,
  VoidCallback? onManageAccess,
  VoidCallback? onRetry,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: DashboardActivityCard(
          isLoading: isLoading,
          result: result,
          hasError: hasError,
          onManageAccess: onManageAccess ?? () {},
          onRetry: onRetry ?? () {},
        ),
      ),
    ),
  );
}
