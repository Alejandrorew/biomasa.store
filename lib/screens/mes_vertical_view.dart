import 'package:flutter/material.dart';
import 'mes_selectio.dart'; // Importa MonthInfo y MonthAvailability

/// Pantalla de selección de mes con un diseño moderno y profesional.
class MesVerticalView extends StatefulWidget {
  final int initialYear;
  final List<MonthInfo> months;
  final void Function(int year, int month) onMonthTap;

  const MesVerticalView({
    Key? key,
    required this.initialYear,
    required this.months,
    required this.onMonthTap,
  }) : super(key: key);

  @override
  _MesVerticalViewState createState() => _MesVerticalViewState();
}

class _MesVerticalViewState extends State<MesVerticalView> {
  late int selectedYear;

  @override
  void initState() {
    super.initState();
    selectedYear = widget.initialYear;
  }

  final List<String> monthNames = [
    '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  @override
  Widget build(BuildContext context) {
    final displayedMonths = widget.months.where((month) {
      return widget.months.indexOf(month) >= 5;
    }).toList();

    return Column(
      children: [
        _YearSelector(
          selectedYear: selectedYear,
          onYearChanged: (year) {
            setState(() {
              selectedYear = year;
            });
          },
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = 2;
              if (constraints.maxWidth > 900) {
                crossAxisCount = 4;
              } else if (constraints.maxWidth > 600) {
                crossAxisCount = 3;
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16.0),
                physics: const BouncingScrollPhysics(),
                itemCount: displayedMonths.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                itemBuilder: (context, index) {
                  final MonthInfo monthInfo = displayedMonths[index];
                  final int originalMonthNumber = widget.months.indexOf(monthInfo) + 1;
                  final bool isAvailable = monthInfo.availability == MonthAvailability.available;

                  return _MonthCard(
                    monthName: monthNames[originalMonthNumber],
                    isAvailable: isAvailable,
                    onTap: () {
                      if (isAvailable) {
                        widget.onMonthTap(selectedYear, originalMonthNumber);
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Widget para el selector de año interactivo.
class _YearSelector extends StatelessWidget {
  final int selectedYear;
  final ValueChanged<int> onYearChanged;

  const _YearSelector({
    Key? key,
    required this.selectedYear,
    required this.onYearChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool canGoPrev = selectedYear > 2025;
    final bool canGoNext = selectedYear < 2025;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: canGoPrev ? theme.colorScheme.primary : theme.disabledColor, size: 30),
            onPressed: canGoPrev ? () => onYearChanged(selectedYear - 1) : null,
            tooltip: 'Año anterior',
          ),
          Text(
            '$selectedYear',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: canGoNext ? theme.colorScheme.primary : theme.disabledColor, size: 30),
            onPressed: canGoNext ? () => onYearChanged(selectedYear + 1) : null,
            tooltip: 'Año siguiente',
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de mes con el diseño de la imagen de referencia.
class _MonthCard extends StatelessWidget {
  final String monthName;
  final bool isAvailable;
  final VoidCallback onTap;

  const _MonthCard({
    Key? key,
    required this.monthName,
    required this.isAvailable,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = isAvailable ? theme.cardColor : theme.cardColor.withOpacity(0.5);
    final textColor = isAvailable ? theme.colorScheme.onSurface : theme.disabledColor;

    return GestureDetector(
      onTap: isAvailable ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isAvailable
              ? [
                  BoxShadow(
                    color: theme.shadowColor,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            isAvailable
                ? Image.asset(
                    'assets/logo_vert.png',
                    height: 50,
                     color: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.7) : null,
                     colorBlendMode: BlendMode.modulate,
                  )
                : Icon(
                    Icons.lock_outline_rounded,
                    color: theme.disabledColor,
                    size: 24,
                  ),
            const SizedBox(height: 8),
            Text(
              monthName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!isAvailable) ...[
              const SizedBox(height: 4),
              Text(
                'Próximamente',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.disabledColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
