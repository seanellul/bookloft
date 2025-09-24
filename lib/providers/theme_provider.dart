import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'selected_theme';

  Color _primaryColor = Colors.green;
  String _themeName = 'Green';

  Color get primaryColor => _primaryColor;
  String get themeName => _themeName;

  // Predefined color schemes
  static const Map<String, Color> colorSchemes = {
    'Green': Colors.green,
    'Blue': Colors.blue,
    'Purple': Colors.purple,
    'Orange': Colors.orange,
    'Teal': Colors.teal,
    'Indigo': Colors.indigo,
    'Pink': Colors.pink,
    'Red': Colors.red,
    'Black': Colors.black,
    'Dark Blue': Color(0xFF1A237E), // Deep dark blue
  };

  static List<String> get availableThemes => colorSchemes.keys.toList();

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey);
    if (savedTheme != null && colorSchemes.containsKey(savedTheme)) {
      _themeName = savedTheme;
      _primaryColor = colorSchemes[savedTheme]!;
      notifyListeners();
    }
  }

  Future<void> setTheme(String themeName) async {
    if (colorSchemes.containsKey(themeName)) {
      _themeName = themeName;
      _primaryColor = colorSchemes[themeName]!;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, themeName);

      notifyListeners();
    }
  }

  ColorScheme getColorScheme(BuildContext context) {
    // Determine if this should be a dark theme
    final isDarkTheme = _primaryColor == Colors.black ||
        _primaryColor == const Color(0xFF1A237E);

    return ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: isDarkTheme ? Brightness.dark : Brightness.light,
    );
  }
}
