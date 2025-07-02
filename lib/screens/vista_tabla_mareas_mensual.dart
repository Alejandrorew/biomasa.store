import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/mareas.dart';
import 'dart:ui';
import 'dart:math';

// Modelo para agrupar las mareas por día.
class MareasPorDia {
  final String diaSemana;
  final int diaMes;
  final List<Marea> mareas;

  MareasPorDia({
    required this.diaSemana,
    required this.diaMes,
    required this.mareas,
  });
}

class VistaTablaMareasMensual extends StatelessWidget {
  final String puerto;
  final String mes;
  final int anio;
  final List<Marea> mareasDelMes;

  const VistaTablaMareasMensual({
    Key? key,
    required this.puerto,
    required this.mes,
    required this.anio,
    required this.mareasDelMes,
    // Se aceptan los parámetros anteriores como opcionales para evitar errores de compilación,
    // pero no se utilizan. El widget usará los colores del tema actual.
    Color? accentColor,
    Color? navyColor,
  }) : super(key: key);

  List<MareasPorDia> _agruparMareasPorDia() {
    final Map<int, MareasPorDia> mapaDias = {};
    final diasSemana = DateFormat.E('es_ES');

    for (var marea in mareasDelMes) {
      try {
        if (marea.dia.isEmpty) continue;
        final diaMes = int.tryParse(marea.dia);
        if (diaMes == null) continue;

        final numeroMes = _numeroDelMes(mes);
        if (numeroMes == 0) {
          if (kDebugMode) {
            print("Mes inválido proporcionado: '$mes'. Saltando entrada de marea.");
          }
          continue;
        }

        final fecha = DateTime(anio, numeroMes, diaMes);
        final diaSemanaStr = diasSemana.format(fecha).toUpperCase().replaceAll('.', '');

        if (mapaDias.containsKey(diaMes)) {
          if (!mapaDias[diaMes]!.mareas.any((m) => m.hora == marea.hora && m.altura == marea.altura)) {
            mapaDias[diaMes]!.mareas.add(marea);
          }
        } else {
          mapaDias[diaMes] = MareasPorDia(
            diaSemana: diaSemanaStr,
            diaMes: diaMes,
            mareas: [marea],
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print("Error procesando dato de marea para el día ${marea.dia}: $e");
        }
        continue;
      }
    }

    final listaOrdenada = mapaDias.values.toList()
      ..sort((a, b) => a.diaMes.compareTo(b.diaMes));

    for (var dia in listaOrdenada) {
      dia.mareas.sort((a, b) {
        final horaA = int.tryParse(a.hora.padLeft(4, '0')) ?? 0;
        final horaB = int.tryParse(b.hora.padLeft(4, '0')) ?? 0;
        return horaA.compareTo(horaB);
      });
    }

    return listaOrdenada;
  }

  int _numeroDelMes(String nombreMes) {
    const meses = {
      "enero": 1, "febrero": 2, "marzo": 3, "abril": 4, "mayo": 5, "junio": 6,
      "julio": 7, "agosto": 8, "septiembre": 9, "octubre": 10, "noviembre": 11, "diciembre": 12
    };
    return meses[nombreMes.toLowerCase()] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mareasAgrupadas = _agruparMareasPorDia();
    
    final puntoMedio = (mareasAgrupadas.length / 2).ceil();
    final primeraMitad = mareasAgrupadas.sublist(0, puntoMedio);
    final segundaMitad = mareasAgrupadas.sublist(puntoMedio);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              _buildHeader(context, theme),
              Divider(color: theme.dividerColor, height: 1),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                  child: mareasAgrupadas.isEmpty
                      ? Center(
                          child: Text(
                            'No hay datos de mareas para este mes.',
                            style: TextStyle(color: theme.colorScheme.onSurface),
                            ),
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildColumnWithDays(primeraMitad, theme),
                            ),
                            VerticalDivider(width: 12, thickness: 1, color: theme.dividerColor),
                            Expanded(
                              child: _buildColumnWithDays(segundaMitad, theme),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColumnWithDays(List<MareasPorDia> dias, ThemeData theme) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        _buildColumnHeader(theme),
        const SizedBox(height: 4),
        ...dias.map((dia) => _DayInfoCell(diaData: dia, theme: theme)).toList(),
      ],
    );
  }

  Widget _buildColumnHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 35.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(
            "HORA",
            style: GoogleFonts.robotoMono(fontSize: 12, color: theme.textTheme.bodyMedium?.color, fontWeight: FontWeight.bold),
          ),
          Text(
            "[m]",
            style: GoogleFonts.robotoMono(fontSize: 12, color: theme.textTheme.bodyMedium?.color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${mes.toUpperCase()} $anio",
                  style: GoogleFonts.inter(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        puerto,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: theme.colorScheme.onSurface, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _DayInfoCell extends StatelessWidget {
  final MareasPorDia diaData;
  final ThemeData theme;

  const _DayInfoCell({
    Key? key,
    required this.diaData,
    required this.theme,
  }) : super(key: key);

  String _formatHora(String hora) {
    return hora.padLeft(4, '0');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 35,
            child: Column(
              children: [
                Text(
                  diaData.diaMes.toString(),
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold, fontSize: 14, color: theme.colorScheme.onSurface),
                ),
                Text(
                  diaData.diaSemana.substring(0, 2),
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodyMedium?.color),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: diaData.mareas.map((marea) {
                if (marea.hora == '-' || marea.altura == '-') return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        _formatHora(marea.hora),
                        style: GoogleFonts.robotoMono(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                      ),
                      Text(
                        marea.altura,
                        style: GoogleFonts.robotoMono(fontSize: 13, color: theme.colorScheme.onSurface),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
