import 'package:flutter/material.dart';

class Marea {
  final String dia;
  final String hora;
  final String altura;

  Marea({
    required this.dia,
    required this.hora,
    required this.altura,
  });

  factory Marea.fromFirestore(Map<String, dynamic> data) {
    // --- LÓGICA FINAL Y CORRECTA ---

    // 1. Lee el campo 'Dia' de Firestore (ej: "VIERNES 6").
    final diaRaw = data['Dia']?.toString() ?? '';

    // 2. Usa una expresión regular para extraer SÓLO los dígitos del string.
    //    Esto convierte "VIERNES 6" en "6".
    final diaMatch = RegExp(r'\d+').firstMatch(diaRaw);
    final dia = diaMatch != null ? diaMatch.group(0) ?? '' : '';

    // 3. Lee los otros campos.
    final hora = data['Hora']?.toString() ?? '-';
    final altura = data['Altura']?.toString() ?? '-';

    // 4. Crea el objeto Marea con el día ya limpio.
    return Marea(
      dia: dia,
      hora: hora,
      altura: altura,
    );
  }
}
