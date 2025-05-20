import './widget_tree.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _theme(),
      home: const WidgetTree(),
    );
  }

  ThemeData _theme() {
    return ThemeData(
      primarySwatch: Colors.brown,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4A3728), // Deep brown
        primary: const Color(0xFF4A3728), // Deep brown
        secondary: const Color(0xFF2E7D32), // Forest green
        tertiary: const Color(0xFF8D6E63), // Light brown
        // background: const Color(0xFFF5F5F5), // Light background
        // surface: const Color(0xFFF5F5F5), // Light background for surface
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF4A3728), // Deep brown
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32), // Forest green
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF8D6E63)), // Light brown
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF8D6E63)), // Light brown
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2), // Forest green
        ),
        labelStyle: const TextStyle(color: Color(0xFF4A3728)), // Deep brown
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: Color(0xFF4A3728), // Deep brown
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(
          color: Color(0xFF4A3728), // Deep brown
          fontSize: 16,
        ),
      ),
    );
  }
}