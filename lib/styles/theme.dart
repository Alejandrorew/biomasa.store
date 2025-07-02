import 'package:flutter/material.dart';

/// Colores comunes
class AppColors {
  static const Color navyDark = Color(0xFF00244A); // Fondo principal
  static const Color cardBg = Color(0xFFFFFFFF);   // Fondo de tarjetas/campos
  static const Color blue = Color(0xFF005282);     // Íconos, acentos, enlaces
  static const Color gray = Color(0xFF757575);     // Texto secundario
  static const Color error = Color(0xFFD32F2F);    // Mensajes de error
}

/// Estilos comunes
class AppStyles {
  /// Estilo para botones elevados
  static ButtonStyle elevatedButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.blue,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      fontFamily: 'Inter',
    ),
    elevation: 2,
  );

  /// Decoración para campos de texto
  static InputDecoration textFieldDecoration({
    required String label,
    required IconData icon,
    String? helperText,
    Color? helperColor,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.gray),
      helperText: helperText,
      helperStyle: TextStyle(
        color: helperColor ?? AppColors.gray,
        fontSize: 12,
        fontFamily: 'Inter',
      ),
      filled: true,
      fillColor: AppColors.cardBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.gray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.blue, width: 2),
      ),
    );
  }
}