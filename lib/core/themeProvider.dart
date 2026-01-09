import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thisjowi/core/appTheme.dart';

enum ThemeModeOption { system, light, dark }

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  
  ThemeModeOption _themeMode = ThemeModeOption.system;
  ThemeModeOption get themeMode => _themeMode;
  
  ThemeProvider() {
    _loadThemeFromPrefs();
  }
  
  /// Carga el tema guardado desde SharedPreferences
  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey);
    
    print('🎨 Theme loaded from prefs: $savedTheme');
    
    if (savedTheme != null) {
      _themeMode = ThemeModeOption.values.firstWhere(
        (e) => e.name == savedTheme,
        orElse: () => ThemeModeOption.system,
      );
      print('🎨 Theme mode set to: $_themeMode');
      print('🎨 Flutter ThemeMode will be: $flutterThemeMode');
      notifyListeners();
    } else {
      print('🎨 No saved theme, using system default');
      print('🎨 Flutter ThemeMode will be: $flutterThemeMode');
    }
  }
  
  /// Resetea al tema del sistema (elimina preferencia guardada)
  Future<void> resetToSystem() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_themeKey);
    _themeMode = ThemeModeOption.system;
    print('🎨 Theme reset to system');
    notifyListeners();
  }
  
  /// Guarda el tema en SharedPreferences
  Future<void> _saveThemeToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, _themeMode.name);
  }
  
  /// Cambia el modo de tema
  Future<void> setThemeMode(ThemeModeOption mode) async {
    _themeMode = mode;
    await _saveThemeToPrefs();
    notifyListeners();
  }
  
  /// Alterna entre claro y oscuro (ignora system)
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeModeOption.dark) {
      await setThemeMode(ThemeModeOption.light);
    } else {
      await setThemeMode(ThemeModeOption.dark);
    }
  }
  
  /// Obtiene el ThemeMode de Flutter
  ThemeMode get flutterThemeMode {
    switch (_themeMode) {
      case ThemeModeOption.light:
        return ThemeMode.light;
      case ThemeModeOption.dark:
        return ThemeMode.dark;
      case ThemeModeOption.system:
        return ThemeMode.system;
    }
  }
  
  /// Obtiene el tema claro
  ThemeData get lightTheme => AppTheme.getLightTheme();
  
  /// Obtiene el tema oscuro
  ThemeData get darkTheme => AppTheme.getDarkTheme();
  
  /// Verifica si está en modo oscuro basado en el contexto
  bool isDarkMode(BuildContext context) {
    if (_themeMode == ThemeModeOption.system) {
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeModeOption.dark;
  }
  
  /// Actualiza el estilo de la barra de estado según el tema
  void updateSystemUI(BuildContext context) {
    final isDark = isDarkMode(context);
    
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: isDark 
          ? AppTheme.darkBottomNavBar 
          : AppTheme.lightBottomNavBar,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));
  }
  
  /// Obtiene el texto del modo actual
  String getThemeModeText() {
    switch (_themeMode) {
      case ThemeModeOption.system:
        return 'Sistema';
      case ThemeModeOption.light:
        return 'Claro';
      case ThemeModeOption.dark:
        return 'Oscuro';
    }
  }
  
  /// Obtiene el icono del modo actual
  IconData getThemeModeIcon() {
    switch (_themeMode) {
      case ThemeModeOption.system:
        return Icons.brightness_auto;
      case ThemeModeOption.light:
        return Icons.light_mode;
      case ThemeModeOption.dark:
        return Icons.dark_mode;
    }
  }
}
