import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Paleta de colores profesional y centralizada
class AppColors {
  // Paleta para el modo claro
  static const Color lightPrimary = Color(0xFF426A8C); // Un azul más amigable
  static const Color lightSecondary = Color(0xFF233A59); // Navy para contraste
  static const Color lightBackground = Color(0xFFF2F6FC); // Fondo muy claro, casi blanco
  static const Color lightCard = Colors.white;
  static const Color lightText = Color(0xFF1A202C);
  static const Color lightSubtext = Color(0xFF64748B);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // Paleta para el modo oscuro
  static const Color darkPrimary = Color(0xFF60A5FA); // Un azul vibrante para acentos
  static const Color darkSecondary = Color(0xFF94A3B8); // Un gris azulado claro
  static const Color darkBackground = Color(0xFF0F172A); // Fondo oscuro profundo (casi negro)
  static const Color darkCard = Color(0xFF1E293B); // Color de tarjeta ligeramente más claro
  static const Color darkText = Color(0xFFF8FAFC);
  static const Color darkSubtext = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF334155);
}

// Función base para el texto para mantener la consistencia
TextTheme _buildTextTheme(TextTheme base, Color textColor, Color subtextColor) {
  return base.copyWith(
    displayLarge: GoogleFonts.inter(textStyle: base.displayLarge?.copyWith(color: textColor, fontWeight: FontWeight.bold)),
    displayMedium: GoogleFonts.inter(textStyle: base.displayMedium?.copyWith(color: textColor, fontWeight: FontWeight.bold)),
    displaySmall: GoogleFonts.inter(textStyle: base.displaySmall?.copyWith(color: textColor, fontWeight: FontWeight.bold)),
    headlineLarge: GoogleFonts.inter(textStyle: base.headlineLarge?.copyWith(color: textColor, fontWeight: FontWeight.w600)),
    headlineMedium: GoogleFonts.inter(textStyle: base.headlineMedium?.copyWith(color: textColor, fontWeight: FontWeight.w600)),
    headlineSmall: GoogleFonts.inter(textStyle: base.headlineSmall?.copyWith(color: textColor, fontWeight: FontWeight.w600)),
    titleLarge: GoogleFonts.inter(textStyle: base.titleLarge?.copyWith(color: textColor, fontWeight: FontWeight.w600)),
    titleMedium: GoogleFonts.inter(textStyle: base.titleMedium?.copyWith(color: textColor)),
    titleSmall: GoogleFonts.inter(textStyle: base.titleSmall?.copyWith(color: textColor)),
    bodyLarge: GoogleFonts.inter(textStyle: base.bodyLarge?.copyWith(color: textColor)),
    bodyMedium: GoogleFonts.inter(textStyle: base.bodyMedium?.copyWith(color: subtextColor)), // Color de subtexto para bodyMedium
    bodySmall: GoogleFonts.inter(textStyle: base.bodySmall?.copyWith(color: subtextColor)),
    labelLarge: GoogleFonts.inter(textStyle: base.labelLarge?.copyWith(color: textColor, fontWeight: FontWeight.bold)),
    labelMedium: GoogleFonts.inter(textStyle: base.labelMedium?.copyWith(color: textColor)),
    labelSmall: GoogleFonts.inter(textStyle: base.labelSmall?.copyWith(color: textColor)),
  ).apply(
    bodyColor: textColor,
    displayColor: textColor,
  );
}


// Tema claro
final ThemeData appLightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: AppColors.lightBackground,
  cardColor: AppColors.lightCard,
  dividerColor: AppColors.lightBorder,
  shadowColor: Colors.black.withOpacity(0.05),
  colorScheme: const ColorScheme.light(
    primary: AppColors.lightPrimary,
    secondary: AppColors.lightSecondary,
    background: AppColors.lightBackground,
    surface: AppColors.lightCard,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onBackground: AppColors.lightText,
    onSurface: AppColors.lightText,
    error: Colors.redAccent,
    onError: Colors.white,
    brightness: Brightness.light,
  ),
  textTheme: _buildTextTheme(ThemeData.light().textTheme, AppColors.lightText, AppColors.lightSubtext),
  iconTheme: const IconThemeData(color: AppColors.lightPrimary),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.lightBackground,
    elevation: 0,
    iconTheme: IconThemeData(color: AppColors.lightPrimary),
  ),
);

// Tema oscuro
final ThemeData appDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.darkBackground,
  cardColor: AppColors.darkCard,
  dividerColor: AppColors.darkBorder,
  shadowColor: Colors.black.withOpacity(0.2),
  colorScheme: const ColorScheme.dark(
    primary: AppColors.darkPrimary,
    secondary: AppColors.darkSecondary,
    background: AppColors.darkBackground,
    surface: AppColors.darkCard,
    onPrimary: AppColors.darkBackground,
    onSecondary: AppColors.darkBackground,
    onBackground: AppColors.darkText,
    onSurface: AppColors.darkText,
    error: Colors.redAccent,
    onError: Colors.white,
    brightness: Brightness.dark,
  ),
  textTheme: _buildTextTheme(ThemeData.dark().textTheme, AppColors.darkText, AppColors.darkSubtext),
  iconTheme: const IconThemeData(color: AppColors.darkPrimary),
    appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.darkBackground,
    elevation: 0,
    iconTheme: IconThemeData(color: AppColors.darkPrimary),
  ),
);
