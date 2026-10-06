import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() => runApp(const LifeLedgerApp());

class AppColors {
  static const ink = Color(0xFF0E4D4A);     // deep teal
  static const paper = Color(0xFFF5F7F4);
  static const saffron = Color(0xFFE8A33D); // money / action
  static const alert = Color(0xFFB3261E);
}

class LifeLedgerApp extends StatelessWidget {
  const LifeLedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LifeLedger',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.ink,
          primary: AppColors.ink,
          secondary: AppColors.saffron,
          error: AppColors.alert,
        ),
        scaffoldBackgroundColor: AppColors.paper,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.paper,
          foregroundColor: AppColors.ink,
          elevation: 0,
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.ink,
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
