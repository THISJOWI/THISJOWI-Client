import 'package:flutter/material.dart';

/// Helper para obtener colores del tema actual de forma segura.
/// Usa Theme.of(context) para respetar el modo claro/oscuro.
class ThemeColors {
  static Color background(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  static Color text(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  static Color surface(BuildContext context) {
    return Theme.of(context).cardColor;
  }

  static Color bottomNavBar(BuildContext context) {
    return Theme.of(context).bottomNavigationBarTheme.backgroundColor 
        ?? Theme.of(context).scaffoldBackgroundColor;
  }

  static Color primary(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  static Color secondary(BuildContext context) {
    return Theme.of(context).colorScheme.secondary;
  }

  static Color accent(BuildContext context) {
    return Theme.of(context).colorScheme.tertiary;
  }
}
