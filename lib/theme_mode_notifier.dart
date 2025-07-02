import 'package:flutter/material.dart';

class ThemeModeNotifier extends ValueNotifier<ThemeMode> {
  // Comienza con el tema del sistema por defecto
  ThemeModeNotifier() : super(ThemeMode.system);

  // Cambia entre claro y oscuro explícitamente
  void toggleTheme() {
    value = value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }

  // Métodos para establecer un tema específico
  void setLightMode() {
    value = ThemeMode.light;
  }

  void setDarkMode() {
    value = ThemeMode.dark;
  }

  void setSystemMode() {
    value = ThemeMode.system;
  }
}
