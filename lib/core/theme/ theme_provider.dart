import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  // Charger le thème depuis les préférences
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      notifyListeners();
    } catch (e) {
      print('⚠️ Erreur chargement thème: $e');
      _isDarkMode = false;
      notifyListeners();
    }
  }

  // Toggle le thème
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', _isDarkMode);
    } catch (e) {
      print('⚠️ Erreur sauvegarde thème: $e');
    }
    notifyListeners();
  }

  // Theme clair
  ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: Color(0xFF2F80ED),
      scaffoldBackgroundColor: Color(0xFFF5F7FA),
      
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF2F80ED)),
        titleTextStyle: TextStyle(
          color: Color(0xFF1A1A1A),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Cards
      cardColor: Colors.white,

      // Text
      textTheme: TextTheme(
        displayLarge: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: Color(0xFF1A1A1A)),
        bodyMedium: TextStyle(color: Color(0xFF4A4A4A)),
        bodySmall: TextStyle(color: Color(0xFF7A7A7A)),
      ),

      // Icon
      iconTheme: IconThemeData(color: Color(0xFF2F80ED)),

      colorScheme: ColorScheme.light(
        primary: Color(0xFF2F80ED),
        secondary: Color(0xFF58CC02),
        surface: Colors.white,
        error: Color(0xFFFF4B4B),
      ),
    );
  }

  // Theme sombre (style Duolingo)
  ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: Color(0xFF58CC02),
      scaffoldBackgroundColor: Color(0xFF1A1F36),
      
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF1A1F36),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Cards
      cardColor: Color(0xFF2B3252),

      // Text
      textTheme: TextTheme(
        displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Color(0xFFB0B0B0)),
        bodySmall: TextStyle(color: Color(0xFF808080)),
      ),

      // Icon
      iconTheme: IconThemeData(color: Color(0xFF58CC02)),

      colorScheme: ColorScheme.dark(
        primary: Color(0xFF58CC02),
        secondary: Color(0xFF1CB0F6),
        surface: Color(0xFF2B3252),
        error: Color(0xFFFF4B4B),
      ),
    );
  }
}