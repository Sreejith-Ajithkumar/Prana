import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/onboarding/presentation/controllers/onboarding_controller.dart';
import '../features/onboarding/presentation/controllers/onboarding_scope.dart';
import '../features/onboarding/presentation/screens/date_of_birth_screen.dart';
import '../features/onboarding/presentation/screens/name_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_intro_screen.dart';
import '../features/onboarding/presentation/screens/sex_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/onboarding/presentation/screens/height_screen.dart';
import '../features/onboarding/presentation/screens/weight_screen.dart';
import '../features/onboarding/presentation/screens/goal_weight_screen.dart';

final OnboardingController onboardingController = OnboardingController();

Widget _withOnboardingScope(Widget child) {
  return OnboardingScope(
    controller: onboardingController,
    child: child,
  );
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'welcome',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) {
        return _withOnboardingScope(
          const OnboardingIntroScreen(),
        );
      },
    ),
    GoRoute(
      path: '/onboarding/name',
      name: 'onboarding-name',
      builder: (context, state) {
        return _withOnboardingScope(
          const NameScreen(),
        );
      },
    ),
    GoRoute(
      path: '/onboarding/sex',
      name: 'onboarding-sex',
      builder: (context, state) {
        return _withOnboardingScope(
          const SexScreen(),
        );
      },
    ),
    GoRoute(
      path: '/onboarding/birthday',
      name: 'onboarding-birthday',
      builder: (context, state) {
        return _withOnboardingScope(
          const DateOfBirthScreen(),
        );
      },
    ),
    GoRoute(
      path: '/onboarding/height',
      name: 'onboarding-height',
      builder: (context, state) {
        return _withOnboardingScope(
          const HeightScreen(),
        );
      },
    ),
    GoRoute(
      path: '/onboarding/weight',
      name: 'onboarding-weight',
      builder: (context, state) {
        return _withOnboardingScope(
          const WeightScreen(),
        );
      },
    ),
    GoRoute(
      path: '/onboarding/goal-weight',
      name: 'onboarding-goal-weight',
      builder: (context, state) {
        return _withOnboardingScope(
          const GoalWeightScreen(),
        );
      },
    ),
    GoRoute(
      path: '/dashboard',
      name: 'dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
  ],
  errorBuilder: (context, state) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 56,
                ),
                const SizedBox(height: 16),
                Text(
                  'Page not found',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  state.error?.toString() ??
                      'The page you requested is unavailable.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Return home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  },
);