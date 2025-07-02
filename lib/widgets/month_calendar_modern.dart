import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para feedback háptico

class MonthCalendarModern extends StatelessWidget {
  final String month;
  final int year;
  final int? selectedDay;
  final int daysInMonth;
  final int firstWeekday;
  final void Function(int) onDayTap;
  final Color accent;
  final Color navy;

  const MonthCalendarModern({
    Key? key,
    required this.month,
    required this.year,
    required this.selectedDay,
    required this.daysInMonth,
    required this.firstWeekday,
    required this.onDayTap,
    required this.accent,
    required this.navy,
  }) : super(key: key);

  bool _isToday(int day, int month, int year) {
    final now = DateTime.now();
    return now.day == day && now.month == month && now.year == year;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> dayWidgets = [];
    const daysOfWeek = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];
    dayWidgets.add(
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: daysOfWeek
            .map((d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: TextStyle(
                        color: navy.withOpacity(0.5),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
    dayWidgets.add(const SizedBox(height: 8));

    List<Widget> rows = [];
    int day = 1;
    int totalCells = daysInMonth + firstWeekday;
    int weeks = (totalCells / 7).ceil();

    for (int w = 0; w < weeks; w++) {
      List<Widget> weekRow = [];
      for (int d = 0; d < 7; d++) {
        int cellIndex = w * 7 + d;
        if (cellIndex < firstWeekday || day > daysInMonth) {
          weekRow.add(const Expanded(child: SizedBox()));
        } else {
          final currentDay = day;
          final isSelected = currentDay == selectedDay;
          final isToday = _isToday(currentDay, _getMonthNumber(month), year);

          weekRow.add(
            Expanded(
              child: _AnimatedDayCell(
                day: currentDay,
                isSelected: isSelected,
                isToday: isToday,
                accent: accent,
                navy: navy,
                onTap: () async {
                  HapticFeedback.lightImpact();
                  onDayTap(currentDay);
                },
                onLongPress: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Detalles del día $currentDay'),
                      duration: const Duration(milliseconds: 900),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
          );
          day++;
        }
      }
      rows.add(Row(children: weekRow));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Encabezado mes y año eliminado
        const SizedBox(height: 8),
        // Calendario
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ...dayWidgets,
            ...rows,
          ],
        ),
      ],
    );
  }

  int _getMonthNumber(String monthName) {
    const months = [
      "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
      "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"
    ];
    return months.indexOf(monthName) + 1;
  }
}

class _AnimatedDayCell extends StatefulWidget {
  final int day;
  final bool isSelected;
  final bool isToday;
  final Color accent;
  final Color navy;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _AnimatedDayCell({
    Key? key,
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.accent,
    required this.navy,
    required this.onTap,
    required this.onLongPress,
  }) : super(key: key);

  @override
  State<_AnimatedDayCell> createState() => _AnimatedDayCellState();
}

class _AnimatedDayCellState extends State<_AnimatedDayCell>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.12)
        .chain(CurveTween(curve: Curves.elasticOut))
        .animate(_controller);
    _glowAnim = Tween<double>(begin: 0.0, end: 12.0)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_controller);

    if (widget.isSelected) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(_AnimatedDayCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.forward(from: 0.0);
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _controller.reverse();
    }
  }

  // ===================================================================
  // START OF FIX: Se detiene el controlador de animación antes de desecharlo.
  // ===================================================================
  @override
  void dispose() {
    _controller.stop(); // Detiene cualquier animación en curso.
    _controller.dispose();
    super.dispose();
  }
  // ===================================================================
  // END OF FIX
  // ===================================================================

  @override
  Widget build(BuildContext context) {
    final bool showTodayIndicator = widget.isToday && !widget.isSelected;

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Container(
        width: 48, // Aumentar el tamaño
        height: 48,
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glow animado para el día seleccionado
                    if (widget.isSelected)
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: widget.accent.withOpacity(0.35),
                              blurRadius: _glowAnim.value,
                              spreadRadius: 1.5,
                            ),
                          ],
                        ),
                      ),
                    // Indicador de día actual (borde animado)
                    if (showTodayIndicator)
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.accent.withOpacity(0.7),
                            width: 2.2,
                          ),
                        ),
                      ),
                    // Círculo de selección con animación de fondo y rebote
                    ScaleTransition(
                      scale: _scaleAnim,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        width: 36,
                        height: 36,
                        decoration: widget.isSelected
                            ? BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    widget.accent.withOpacity(0.95),
                                    widget.accent.withOpacity(0.80),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.accent.withOpacity(0.18),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              )
                            : null,
                        child: Center(
                          child: Text(
                            '${widget.day}',
                            style: TextStyle(
                              color: widget.isSelected
                                  ? Colors.white
                                  : widget.navy.withOpacity(0.85),
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
