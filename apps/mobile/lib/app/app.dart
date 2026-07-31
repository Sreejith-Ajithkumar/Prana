import 'package:flutter/material.dart';
import '../features/splash/presentation/splash_screen.dart';

class PranaApp extends StatelessWidget {
  const PranaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prana',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
      ),
      home: const SplashScreen(),
    );
  }
}