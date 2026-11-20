import 'package:flutter/material.dart';
import 'presentation/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const QuejappApp());
}

class QuejappApp extends StatelessWidget {
  const QuejappApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuejaAPP TransCaribe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF0592A), // Naranja TransCaribe ajustado
          primary: const Color(0xFFF0592A),
        ),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFF0592A), width: 2),
          ),
        ),
      ),
      home:  HomeScreen(), // Solo declaras home una vez
    );
  }
}