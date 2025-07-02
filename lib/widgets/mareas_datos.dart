import 'package:flutter/material.dart';
import '../models/mareas.dart';
import 'package:intl/intl.dart';
import 'dart:collection';

class TideDetailView extends StatelessWidget {
  final List<Marea> mareas;
  final int? selectedIndex;
  final ValueChanged<int>? onSelect;

  const TideDetailView({
    Key? key,
    required this.mareas,
    this.selectedIndex,
    this.onSelect,
  }) : super(key: key);

  // Helper para convertir la hora a un valor numérico para ordenar.
  double _hourToDouble(String hora) {
    if (hora.isEmpty) return 0.0;
    try {
      final h = int.parse(hora.padLeft(4, '0').substring(0, 2));
      final min = int.parse(hora.padLeft(4, '0').substring(2, 4));
      return h + min / 60.0;
    } catch (e) {
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // =========== FIX START ===========
    // Lógica para eliminar duplicados antes de procesar la lista.
    final uniqueMareas = LinkedHashMap<String, Marea>.fromIterable(
      mareas,
      key: (m) => '${(m as Marea).hora}-${m.altura}',
      value: (m) => m as Marea,
    ).values.toList();
    // =========== FIX END ===========
    
    if (uniqueMareas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Text('No hay datos de mareas para este día.', style: theme.textTheme.bodyMedium),
        ),
      );
    }

    // --- Colores Semánticos (independientes del tema para mantener el significado) ---
    const Color bajaBadgeColor = Color(0xFF3B82F6); // Azul para marea baja
    const Color altaBadgeColor = Color(0xFF10B981); // Verde para marea alta
    const Color bajaTrendColor = Color(0xFFEF4444); // Rojo para tendencia baja
    const Color altaTrendColor = altaBadgeColor;    // Verde para tendencia alta

    // Se ordena la lista de mareas (ya sin duplicados) por hora para la visualización.
    final sortedMareas = List<Marea>.from(uniqueMareas)
      ..sort((a, b) => _hourToDouble(a.hora).compareTo(_hourToDouble(b.hora)));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Card(
        color: theme.cardColor,
        elevation: 0, // La sombra la maneja el tema global
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: theme.dividerColor, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: sortedMareas.length,
          separatorBuilder: (_, __) => Divider(color: theme.dividerColor, height: 1.5),
          itemBuilder: (context, index) {
            final m = sortedMareas[index];
            final altura = double.tryParse(m.altura.replaceAll(',', '.')) ?? 0;
            
            // La lógica para determinar si la marea es alta o baja se mantiene.
            final alturasOriginales = uniqueMareas
                .map((m) => double.tryParse(m.altura.replaceAll(',', '.')) ?? 0)
                .toList()
              ..sort();
            final bool isAltaItem = alturasOriginales.length > 2
                ? altura >= alturasOriginales[alturasOriginales.length - 2]
                : altura > 1.5;

            // Selección de colores y textos según el tipo de marea.
            final Color badgeColor = isAltaItem ? altaBadgeColor : bajaBadgeColor;
            final Color trendColor = isAltaItem ? altaTrendColor : bajaTrendColor;
            final String badgeText = isAltaItem ? 'Marea alta' : 'Marea baja';
            final String trendText = isAltaItem ? 'Sube' : 'Baja';
            final IconData trendIcon = isAltaItem ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

            // Formateo de hora.
            String formatHora(String hora) {
              try {
                final padded = hora.padLeft(4, '0');
                final h = int.parse(padded.substring(0, 2));
                final m = int.parse(padded.substring(2));
                final dateTime = DateTime(2024, 1, 1, h, m);
                return DateFormat('h:mm a', 'es_ES').format(dateTime);
              } catch (e) {
                return hora;
              }
            }

            final bool isSelected = index == selectedIndex;

            return GestureDetector(
              onTap: onSelect != null ? () => onSelect!(index) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? trendColor.withOpacity(0.10) : Colors.transparent,
                  border: isSelected ? Border(left: BorderSide(color: trendColor, width: 4)) : null,
                ),
                child: ListTile(
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_filled_rounded,
                        color: theme.textTheme.bodyMedium?.color,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatHora(m.hora),
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  title: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          color: badgeColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${m.altura} m',
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            trendText,
                            style: TextStyle(
                              color: trendColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            trendIcon,
                            color: trendColor,
                            size: 16,
                          ),
                        ],
                      ),
                    ],
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
