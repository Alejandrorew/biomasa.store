import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/mareas.dart';
import 'dart:math';

/// TideChart ahora muestra una gráfica del ciclo de mareas para todo el día
/// y puede cambiar a un "Modo Enfocado" para un evento de marea individual,
/// incluyendo una cabecera con detalles de la marea seleccionada.
class TideChart extends StatefulWidget {
  final List<Marea> mareas;
  final DateTime selectedDate;
  final int? selectedTideIndex;

  const TideChart({
    Key? key,
    required this.mareas,
    required this.selectedDate,
    this.selectedTideIndex,
  }) : super(key: key);

  @override
  _TideChartState createState() => _TideChartState();
}

class _TideChartState extends State<TideChart> {
  // Helpers para convertir la hora y la altura a formato double.
  double _hourToDouble(String hora) {
    if (hora.isEmpty) return 0.0;
    final h = int.parse(hora.padLeft(4, '0').substring(0, 2));
    final min = int.parse(hora.padLeft(4, '0').substring(2, 4));
    return h + min / 60.0;
  }

  double _heightToDouble(String altura) {
    if (altura.isEmpty) return 0.0;
    return double.tryParse(altura.replaceAll(',', '.')) ?? 0.0;
  }

  /// Genera la curva para la vista de día completo.
  List<FlSpot> _generateFullDaySpots(List<Marea> mareas) {
    if (mareas.isEmpty) return [];
    if (mareas.length < 2) {
      return _generateFocusedCurve(mareas.first);
    }

    final List<FlSpot> tidePoints = mareas
        .map((m) => FlSpot(_hourToDouble(m.hora), _heightToDouble(m.altura)))
        .toList();
    tidePoints.sort((a, b) => a.x.compareTo(b.x));

    final List<FlSpot> extendedTidePoints = List.from(tidePoints);

    final double minHeight = tidePoints.map((p) => p.y).reduce(min);
    final double maxHeight = tidePoints.map((p) => p.y).reduce(max);

    final firstPoint = tidePoints.first;
    final prevPointY = (maxHeight + minHeight) - firstPoint.y;
    extendedTidePoints.insert(
        0, FlSpot(firstPoint.x - 6.21, prevPointY.clamp(minHeight, maxHeight)));

    final lastPoint = tidePoints.last;
    final nextPointY = (maxHeight + minHeight) - lastPoint.y;
    extendedTidePoints.add(
        FlSpot(lastPoint.x + 6.21, nextPointY.clamp(minHeight, maxHeight)));

    final List<FlSpot> fullDaySpots = [];
    const step = 0.25;

    for (int i = 0; i < extendedTidePoints.length - 1; i++) {
      final p1 = extendedTidePoints[i];
      final p2 = extendedTidePoints[i + 1];
      for (double x = p1.x; x < p2.x; x += step) {
        final double halfHeight = (p1.y + p2.y) / 2;
        final double amplitude = (p1.y - p2.y) / 2;
        final double progress = (x - p1.x) / (p2.x - p1.x);
        final double y = halfHeight + amplitude * cos(pi * progress);
        fullDaySpots.add(FlSpot(x, y));
      }
    }
    fullDaySpots.add(extendedTidePoints.last);
    return fullDaySpots;
  }

  /// Genera una curva Gaussiana (de campana) para el "Modo Enfocado".
  List<FlSpot> _generateFocusedCurve(Marea marea) {
    final double peakHour = _hourToDouble(marea.hora);
    final double peakHeight = _heightToDouble(marea.altura);
    final List<FlSpot> spots = [];

    const double c = 1.5;

    for (double dx = -3; dx <= 3; dx += 0.2) {
      final double x = peakHour + dx;
      final double y = peakHeight * exp(-pow(dx, 2) / (2 * pow(c, 2)));
      spots.add(FlSpot(x, max(0, y)));
    }
    return spots;
  }

  /// Construye la cabecera que se muestra en la parte superior del gráfico en modo enfocado.
  Widget _buildFocusedHeader(Marea marea, List<Marea> sortedMareasByHeight) {
    final bool isHighTide = sortedMareasByHeight.indexOf(marea) < 2;
    final formattedTime =
        '${marea.hora.padLeft(4, '0').substring(0, 2)}:${marea.hora.padLeft(4, '0').substring(2, 4)}';
    final chartBgColor = const Color(0xFF0B1623); // Color de fondo del gráfico

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            chartBgColor,
            chartBgColor.withOpacity(0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.25, 0.9],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 52),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formattedTime,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.waves_rounded, color: Colors.white.withOpacity(0.7), size: 20),
              const SizedBox(width: 10),
              Text(
                '${marea.altura.replaceAll(',', '.')} m',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isHighTide ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                color: isHighTide
                    ? Colors.cyanAccent.withOpacity(0.7)
                    : Colors.orangeAccent.withOpacity(0.7),
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isFocusedMode = widget.selectedTideIndex != null;
    Marea? focusedMarea;
    List<Marea> sortedMareasByTime = List.from(widget.mareas)
      ..sort((a, b) => _hourToDouble(a.hora).compareTo(_hourToDouble(b.hora)));

    List<Marea> sortedMareasByHeight = List.from(widget.mareas)
      ..sort((a, b) => _heightToDouble(b.altura).compareTo(_heightToDouble(a.altura)));

    if (isFocusedMode && widget.selectedTideIndex! < sortedMareasByTime.length) {
      focusedMarea = sortedMareasByTime[widget.selectedTideIndex!];
    }

    final List<FlSpot> chartSpots = isFocusedMode && focusedMarea != null
        ? _generateFocusedCurve(focusedMarea)
        : _generateFullDaySpots(widget.mareas);

    if (chartSpots.isEmpty) {
      return Container(height: 250);
    }

    final Color bg = const Color(0xFF0B1623);
    final Color curve = const Color(0xFF2563EB);
    final Color grid = Colors.white.withOpacity(0.10);
    final Color nowLineColor = Colors.redAccent;
    final Color selectedLineColor = Colors.amber;

    double minX, maxX, minY, maxY;
    FlSpot? mainSpot;

    if (isFocusedMode && focusedMarea != null) {
      mainSpot = FlSpot(
          _hourToDouble(focusedMarea.hora), _heightToDouble(focusedMarea.altura));
      minX = mainSpot.x - 3;
      maxX = mainSpot.x + 3;
      minY = 0;
      maxY = (mainSpot.y * 1.5).clamp(3.0, 6.0);
    } else {
      minX = 0;
      maxX = 24;
      minY = 0;
      maxY = widget.mareas.isEmpty
          ? 3
          : widget.mareas.map((m) => _heightToDouble(m.altura)).reduce(max);
      maxY = (maxY * 1.2).ceilToDouble();
    }

    // ===================================================================
    // START OF CHANGE: Altura del gráfico proporcional y limitada
    // ===================================================================
    final screenHeight = MediaQuery.of(context).size.height;
    // Se calcula una altura proporcional, pero con límites (clamp) para evitar
    // que el gráfico sea demasiado grande en pantallas altas o demasiado pequeño
    // en pantallas con poca altura (ej. modo landscape).
    final chartHeight = (screenHeight * 0.28).clamp(220.0, 300.0);

    return Container(
      height: chartHeight, // <-- Altura ahora es adaptativa
      clipBehavior: Clip.hardEdge,
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(22)),
      // ===================================================================
      // END OF CHANGE
      // ===================================================================
      child: Stack(
        children: [
          // El Gráfico
          Padding(
            padding: EdgeInsets.only(top: isFocusedMode ? 50 : 20, right: 20, bottom: 10),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: LineChart(
                key: ValueKey(isFocusedMode
                    ? 'focused_${widget.selectedTideIndex}'
                    : 'full_view'),
                LineChartData(
                  lineTouchData: const LineTouchData(enabled: false),
                  clipData: FlClipData.all(),
                  minX: minX,
                  maxX: maxX,
                  minY: minY,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 0.5,
                    verticalInterval: isFocusedMode ? 1 : 4,
                    getDrawingHorizontalLine: (value) =>
                        FlLine(color: grid, strokeWidth: 1),
                    getDrawingVerticalLine: (value) =>
                        FlLine(color: grid, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: isFocusedMode ? 1 : 4,
                        getTitlesWidget: (value, meta) {
                          if (value <= meta.min + 0.1 ||
                              value >= meta.max - 0.1) {
                            return Container();
                          }
                          final timeOfDay = TimeOfDay(
                              hour: value.toInt(),
                              minute: ((value - value.toInt()) * 60).round());
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 8.0,
                            child: Text(timeOfDay.format(context),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                )),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 0.5,
                        getTitlesWidget: (value, meta) {
                          if (value <= meta.min || value >= meta.max) {
                            return Container();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(left: 4.0),
                            child: Text('${value.toStringAsFixed(1)}m',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.left),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.transparent),
                  ),
                  extraLinesData: ExtraLinesData(
                    verticalLines: [
                      if (!isFocusedMode &&
                          DateUtils.isSameDay(widget.selectedDate, DateTime.now()))
                        VerticalLine(
                            x: DateTime.now().hour + DateTime.now().minute / 60.0,
                            color: nowLineColor,
                            strokeWidth: 2,
                            dashArray: [8, 4]),
                      if (isFocusedMode && mainSpot != null)
                        VerticalLine(
                            x: mainSpot.x,
                            color: selectedLineColor,
                            strokeWidth: 2),
                    ],
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartSpots,
                      isCurved: true,
                      color: curve,
                      barWidth: 4,
                      belowBarData:
                          BarAreaData(show: true, color: curve.withOpacity(0.18)),
                      dotData: FlDotData(
                        show: true,
                        checkToShowDot: (spot, barData) {
                          if (isFocusedMode && mainSpot != null) {
                            return (spot.x - mainSpot.x).abs() < 0.01;
                          }
                          return sortedMareasByTime.any((m) =>
                              (_hourToDouble(m.hora) - spot.x).abs() < 0.1);
                        },
                        getDotPainter: (spot, percent, bar, index) {
                          bool isSelected =
                              mainSpot != null && (spot.x - mainSpot.x).abs() < 0.1;
                          return FlDotCirclePainter(
                            radius: isSelected ? 8 : 5,
                            color: isSelected ? selectedLineColor : Colors.white,
                            strokeWidth: 2,
                            strokeColor: curve,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isFocusedMode && focusedMarea != null)
            Positioned.fill(
              top: 0,
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.topCenter,
                child: _buildFocusedHeader(focusedMarea, sortedMareasByHeight),
              ),
            ),
        ],
      ),
    );
  }
}
