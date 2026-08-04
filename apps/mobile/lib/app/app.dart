import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'router.dart';

class PranaApp extends StatelessWidget {
  const PranaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Prana',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
