import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

class VisitorApp extends StatelessWidget {
  const VisitorApp({
    super.key,
    required this.isDemo,
    this.apiUrl = '',
    this.onConfigure,
  });
  final bool isDemo;
  final String apiUrl;
  final Future<void> Function(String)? onConfigure;
  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xff175c51));
    return MaterialApp(
      title: 'Sumadhura Visitor Desk',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xfff5f7f6),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xfff5f7f6),
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: HomeScreen(
        isDemo: isDemo,
        apiUrl: apiUrl,
        onConfigure: onConfigure,
      ),
    );
  }
}
