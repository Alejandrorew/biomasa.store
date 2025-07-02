import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/month_calendar_modern.dart';
import '../models/mareas.dart';
import '../widgets/tide_chart.dart';
import '../widgets/mareas_datos.dart';
import 'mes_selectio.dart'; // Importa MonthInfo
import 'package:shimmer/shimmer.dart';

class MesHorizontalView extends StatefulWidget {
  final List<MonthInfo> months;
  final int selectedMonth;
  final int selectedDay;
  final int selectedYear;
  final List<Marea> mareasDelDia;
  final int? selectedTideIndex;
  final void Function(int) onTideSelect;
  final void Function(int) onDayTap;
  final VoidCallback onShowTable;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isFavorite;
  final bool isFavoriteLoading;
  final VoidCallback onToggleFavorite;
  final bool isLoading;

  const MesHorizontalView({
    Key? key,
    required this.months,
    required this.selectedMonth,
    required this.selectedDay,
    required this.selectedYear,
    required this.mareasDelDia,
    required this.selectedTideIndex,
    required this.onDayTap,
    required this.onTideSelect,
    required this.onShowTable,
    this.startDate,
    this.endDate,
    required this.isFavorite,
    required this.isFavoriteLoading,
    required this.onToggleFavorite,
    required this.isLoading,
  }) : super(key: key);

  @override
  State<MesHorizontalView> createState() => _MesHorizontalViewState();
}

class _MesHorizontalViewState extends State<MesHorizontalView> {
  Widget _buildFavoriteLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildShimmerContent() {
      final theme = Theme.of(context);
      final baseColor = theme.brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[300]!;
      final highlightColor = theme.brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[100]!;

      return Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar Shimmer
            Card(
                color: theme.cardColor,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: List.generate(7, (index) => Container(width: 30, height: 15, color: baseColor)),
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(6, (weekIndex) =>
                        Row(
                          children: List.generate(7, (dayIndex) =>
                            Expanded(child: Container(margin: const EdgeInsets.all(4), decoration: BoxDecoration(color: baseColor, shape: BoxShape.circle), height: 48)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12.0),
            // Tide Chart and Details Shimmer
            Container(height: 250, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(22))),
            const SizedBox(height: 20.0),
            Card(
                color: theme.cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: List.generate(4, (index) =>
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [Container(width: 22, height: 22, decoration: BoxDecoration(color: baseColor, shape: BoxShape.circle)), const SizedBox(width: 8), Container(width: 80, height: 16, color: baseColor)]),
                          Container(width: 90, height: 24, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(12))),
                          Container(width: 60, height: 16, color: baseColor),
                        ],
                      ),
                    ),
                  ),
                ),
            ),
          ],
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final validMareas = widget.mareasDelDia
        .where((marea) => marea.hora != "-" && marea.altura != "-")
        .toList();

    final currentMonthInfo = widget.months.isNotEmpty && widget.selectedMonth > 0
        ? widget.months[widget.selectedMonth - 1]
        : null;

    if (currentMonthInfo == null) {
      return _buildShimmerContent();
    }
    
    final spanishMonthName = currentMonthInfo.name;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                '$spanishMonthName ${widget.selectedYear}',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: widget.onShowTable,
              icon: Icon(Icons.table_chart_rounded, size: 20, color: theme.colorScheme.primary),
              label: Text(
                'Datos del mes',
                style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              ),
            ),
            widget.isFavoriteLoading
              ? _buildFavoriteLoadingIndicator()
              : IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                    child: Icon(
                      widget.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                      key: ValueKey<bool>(widget.isFavorite),
                      color: widget.isFavorite ? const Color(0xFFFFC107) : theme.disabledColor,
                      size: 28,
                    ),
                  ),
                  onPressed: widget.onToggleFavorite,
                  tooltip: widget.isFavorite ? 'Quitar de favoritos' : 'Marcar como favorito',
                ),
          ],
        ),
        const SizedBox(height: 8.0),
        if (widget.isLoading)
          _buildShimmerContent()
        else
          Column(
            children: [
              Card(
                color: theme.cardColor,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 0, // Las sombras ya están en el tema
                shadowColor: theme.shadowColor,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: theme.dividerColor, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                  child: MonthCalendarModern(
                    month: currentMonthInfo.name,
                    year: widget.selectedYear,
                    selectedDay: widget.selectedDay,
                    daysInMonth: currentMonthInfo.days,
                    firstWeekday: currentMonthInfo.firstWeekday,
                    onDayTap: widget.onDayTap,
                    accent: theme.colorScheme.primary,
                    navy: theme.colorScheme.secondary,
                  ),
                ),
              ),
              const SizedBox(height: 12.0),
              validMareas.isNotEmpty
                ? Column(
                    children: [
                      TideChart(
                        mareas: validMareas,
                        selectedDate: DateTime(widget.selectedYear, widget.selectedMonth, widget.selectedDay),
                        selectedTideIndex: widget.selectedTideIndex,
                      ),
                      const SizedBox(height: 20.0),
                      TideDetailView(
                        mareas: validMareas,
                        selectedIndex: widget.selectedTideIndex,
                        onSelect: widget.onTideSelect,
                      ),
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'No hay datos de mareas disponibles para este día.',
                        style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
            ],
          )
      ],
    );
  }
}
