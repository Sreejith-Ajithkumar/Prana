import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../profile/data/profile_storage.dart';

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  @override
  void initState() {
    super.initState();
    _openInitialScreen();
  }

  Future<void> _openInitialScreen() async {
    final hasProfile = await ProfileStorage.instance.hasCompletedOnboarding();

    if (!mounted) {
      return;
    }

    if (hasProfile) {
      context.go('/dashboard');
    } else {
      context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
