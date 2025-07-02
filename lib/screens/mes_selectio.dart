import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import 'package:shimmer/shimmer.dart';

import 'mes_vertical_view.dart';
import 'mes_horizontal_view.dart';
import '../widgets/port_selector_sheet.dart';
import '../services/mareas_service.dart';
import '../models/mareas.dart';
import 'vista_tabla_mareas_mensual.dart';
import 'favorite_ports_section.dart' hide AppColors;
import 'register_screen.dart';


// Widget shimmer para la tabla mensual adaptado al tema
class TablaMensualShimmer extends StatelessWidget {
  const TablaMensualShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = theme.brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[100]!;
    
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
          child: Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
                  child: Row(
                    children: [
                      Container(width: 120, height: 24, color: baseColor),
                      const SizedBox(width: 16),
                      Container(width: 100, height: 18, color: baseColor),
                    ],
                  ),
                ),
                Divider(color: theme.dividerColor, height: 1),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                    child: Row(
                      children: [
                        // Columna izquierda
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: List.generate(16, (i) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [Container(width: 24, height: 18, color: baseColor), const SizedBox(width: 8), Container(width: 40, height: 18, color: baseColor), const SizedBox(width: 8), Container(width: 32, height: 18, color: baseColor)]))))),
                        const VerticalDivider(width: 12, thickness: 1),
                        // Columna derecha
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: List.generate(15, (i) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [Container(width: 24, height: 18, color: baseColor), const SizedBox(width: 8), Container(width: 40, height: 18, color: baseColor), const SizedBox(width: 8), Container(width: 32, height: 18, color: baseColor)]))))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum MonthAvailability { available, inactive, partial, unknown }

class MonthInfo {
  final String name;
  final int days;
  final int firstWeekday;
  final MonthAvailability availability;

  MonthInfo({
    required this.name,
    required this.days,
    required this.firstWeekday,
    required this.availability,
  });
}

class MesSelection extends StatefulWidget {
  final ValueNotifier<String>? initialNotifier;
  const MesSelection({Key? key, this.initialNotifier}) : super(key: key);

  @override
  _MesSelectionState createState() => _MesSelectionState();
}

class _MesSelectionState extends State<MesSelection> with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isFavorite = false;
  bool _isFavoriteLoading = true;

  late ValueNotifier<String> _selectedPortNotifier;
  late ScrollController _scrollController;

  ValueNotifier<String> get selectedPortNotifier => _selectedPortNotifier;

  int selectedMonth = 0;
  int selectedDay = 0;
  int selectedYear = 2025;
  bool isHorizontalMode = false;
  List<Marea> _mareasDelDia = [];

  int? selectedTideIndex;

  bool _isChangingMonth = false;

  final List<MonthInfo> months = [
    MonthInfo(name: "Enero", days: 31, firstWeekday: 3, availability: MonthAvailability.inactive),
    MonthInfo(name: "Febrero", days: 28, firstWeekday: 6, availability: MonthAvailability.inactive),
    MonthInfo(name: "Marzo", days: 31, firstWeekday: 6, availability: MonthAvailability.inactive),
    MonthInfo(name: "Abril", days: 30, firstWeekday: 2, availability: MonthAvailability.inactive),
    MonthInfo(name: "Mayo", days: 31, firstWeekday: 4, availability: MonthAvailability.inactive),
    MonthInfo(name: "Junio", days: 30, firstWeekday: 0, availability: MonthAvailability.available),
    MonthInfo(name: "Julio", days: 31, firstWeekday: 2, availability: MonthAvailability.available),
    MonthInfo(name: "Agosto", days: 31, firstWeekday: 5, availability: MonthAvailability.available),
    MonthInfo(name: "Septiembre", days: 30, firstWeekday: 1, availability: MonthAvailability.inactive),
    MonthInfo(name: "Octubre", days: 31, firstWeekday: 3, availability: MonthAvailability.inactive),
    MonthInfo(name: "Noviembre", days: 30, firstWeekday: 6, availability: MonthAvailability.inactive),
    MonthInfo(name: "Diciembre", days: 31, firstWeekday: 1, availability: MonthAvailability.inactive),
  ];

  List<MonthInfo> get _filteredMonths => months.where((month) =>
      month.availability != MonthAvailability.unknown && months.indexOf(month) >= 5
  ).toList();

  @override
  void initState() {
    super.initState();
    _selectedPortNotifier = widget.initialNotifier ?? ValueNotifier<String>("Puerto Guayaquil");
    _scrollController = ScrollController();
    _selectedPortNotifier.addListener(_onPortChanged);
    _checkIfFavorite();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _selectedPortNotifier.removeListener(_onPortChanged);
    if (widget.initialNotifier == null) {
      _selectedPortNotifier.dispose();
    }
    super.dispose();
  }

  void _onPortChanged() {
    _checkIfFavorite();
    if (selectedMonth != 0 && selectedDay != 0) {
      _loadMareasDelDia(showLoader: true, monthToLoad: selectedMonth, dayToLoad: selectedDay);
    }
  }

  Future<void> _checkIfFavorite() async {
    if (!mounted) return;
    setState(() => _isFavoriteLoading = true);
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isFavoriteLoading = false);
      return;
    }

    try {
      final query = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .where('name', isEqualTo: _selectedPortNotifier.value)
          .limit(1)
          .get();

      if (mounted) {
        setState(() {
          isFavorite = query.docs.isNotEmpty;
          _isFavoriteLoading = false;
        });
      }
    } catch (e) {
      developer.log("Error al verificar el estado de favorito: $e", name: 'MesSelection');
      if (mounted) setState(() => _isFavoriteLoading = false);
    }
  }

  Future<void> _toggleFavorite() async {
    final theme = Theme.of(context);
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Debes iniciar sesión para guardar favoritos."),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }

    final portName = _selectedPortNotifier.value;
    if (!mounted) return;
    setState(() => _isFavoriteLoading = true);

    try {
      final favCollection = _firestore.collection('users').doc(user.uid).collection('favorites');

      if (isFavorite) {
        final querySnapshot = await favCollection.where('name', isEqualTo: portName).get();
        for (var doc in querySnapshot.docs) {
          await doc.reference.delete();
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('"$portName" eliminado de tus favoritos.'),
            backgroundColor: theme.colorScheme.secondary,
          ));
          setState(() => isFavorite = false);
        }
      } else {
        final favoritesSnapshot = await favCollection.get();
        final favoriteCount = favoritesSnapshot.size;

        if (favoriteCount >= maxFavoritePorts) {
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext dialogContext) {
                final dialogTheme = Theme.of(dialogContext);
                return AlertDialog(
                  backgroundColor: dialogTheme.cardColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  title: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.amber.shade700, size: 28),
                      const SizedBox(width: 12),
                      Flexible(child: Text('Límite de Favoritos', style: dialogTheme.textTheme.headlineSmall)),
                    ],
                  ),
                  content: Text(
                    'Solo puedes tener un máximo de $maxFavoritePorts puertos favoritos. Para agregar uno nuevo, elimina uno existente.',
                    style: dialogTheme.textTheme.bodyMedium,
                  ),
                  actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: Text('Cancelar', style: TextStyle(color: dialogTheme.colorScheme.secondary)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: dialogTheme.colorScheme.primary,
                        foregroundColor: dialogTheme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Entendido'),
                    ),
                  ],
                );
              },
            );
          }
        } else {
          final newFavoritePort = FavoritePort(id: '', name: portName, country: 'Ecuador', code: null, currentTide: null, nextTide: null, nextTideTime: null, tideLevel: null);
          await favCollection.add(newFavoritePort.toFirestore());
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('"$portName" agregado a tus favoritos.'),
              backgroundColor: theme.colorScheme.primary,
            ));
            setState(() => isFavorite = true);
          }
        }
      }
    } catch (e) {
       developer.log("Error al actualizar favoritos: $e", name: 'MesSelection');
       if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ocurrió un error.'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isFavoriteLoading = false);
    }
  }

  @override
  void didUpdateWidget(covariant MesSelection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (selectedMonth != 0 && isHorizontalMode) {
      _scrollToSelectedMonth();
    }
  }

  void _scrollToSelectedMonth() {
    final int selectedIndex = _filteredMonths.indexWhere((monthInfo) => months.indexOf(monthInfo) + 1 == selectedMonth);
    if (selectedIndex != -1 && _scrollController.hasClients) {
      _scrollController.animateTo(selectedIndex * 88.0, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  Future<void> _showPortSelector() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PortSelectorSheet(ports: ["Puerto Guayaquil", "Bahía de Caráquez", "Puerto Bolívar"]),
    );
    if (selected != null && selected != selectedPortNotifier.value) {
      selectedPortNotifier.value = selected;
      if (selectedMonth != 0 && selectedDay != 0) {
        _loadMareasDelDia(showLoader: true, monthToLoad: selectedMonth, dayToLoad: selectedDay);
      }
    }
  }

  String _getSpanishMonth(String month) => month.toLowerCase();

  Future<void> _loadMareasDelDia({bool showLoader = false, required int monthToLoad, required int dayToLoad, bool changeViewOnLoad = false}) async {
    if (monthToLoad <= 0 || dayToLoad <= 0 || monthToLoad > months.length) return;

    final currentMonthInfo = months[monthToLoad - 1];
    if (currentMonthInfo.availability == MonthAvailability.inactive) {
      if(mounted) setState(() { _mareasDelDia = []; selectedTideIndex = null; _isChangingMonth = false; });
      return;
    }

    if (showLoader && mounted) {
      setState(() { _isChangingMonth = true; if (changeViewOnLoad) isHorizontalMode = true; });
    }

    try {
      final nombreDia = _getNombreDia(selectedYear, monthToLoad, dayToLoad);
      final diaFirestore = "$nombreDia $dayToLoad".toUpperCase();
      final mes = _getSpanishMonth(months[monthToLoad - 1].name);
      final mareas = await MareasService().obtenerMareasPorDiaYPuerto(diaFirestore, selectedPortNotifier.value, mes);
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;
      setState(() {
        selectedMonth = monthToLoad;
        selectedDay = dayToLoad;
        _mareasDelDia = mareas;
        selectedTideIndex = null;
        if (changeViewOnLoad) WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelectedMonth());
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar mareas: ${e.toString().replaceFirst("Exception: ", "")}'), backgroundColor: Colors.redAccent));
    } finally {
      if (showLoader && mounted) setState(() => _isChangingMonth = false);
    }
  }

  void _mostrarTablaMensual() async {
    if (selectedMonth == 0) return;
    
    final theme = Theme.of(context); // Obtener el tema actual

    showDialog(context: context, barrierDismissible: false, builder: (BuildContext context) => const TablaMensualShimmer());

    try {
      final mes = _getSpanishMonth(months[selectedMonth - 1].name);
      final mareas = await MareasService().obtenerMareasDelMes(selectedPortNotifier.value, mes);
      Navigator.pop(context); // Close shimmer
      if (mareas.isEmpty) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay datos disponibles para este mes.')));
        return;
      }
      if(mounted) {
        showDialog(
          context: context, 
          builder: (context) => VistaTablaMareasMensual(
            puerto: selectedPortNotifier.value, 
            mes: mes, 
            anio: selectedYear, 
            mareasDelMes: mareas,
            // *** FIX: Passing theme colors to the widget constructor ***
            accentColor: theme.colorScheme.primary,
            navyColor: theme.colorScheme.secondary,
          )
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close shimmer on error
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar datos del mes: $e')));
    }
  }

  String _getNombreDia(int year, int month, int day) {
    final dias = ["LUNES", "MARTES", "MIÉRCOLES", "JUEVES", "VIERNES", "SÁBADO", "DOMINGO"];
    return dias[DateTime(year, month, day).weekday - 1];
  }

  void _showInactiveMonthDialog(String monthName) {
    final theme = Theme.of(context);
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Datos no disponibles",
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) => Center(child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20)),
          child: Material(color: Colors.transparent, child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 40),
              const SizedBox(height: 16),
              Text('Datos no disponibles', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('Los datos para ${monthName.toLowerCase()} estarán disponibles próximamente.', textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: theme.colorScheme.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                child: const Text('Entendido'),
              ),
            ],
          )),
        ),
      )),
    );
  }
  
  // --- BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(theme),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: ScaleTransition(scale: Tween<double>(begin: 0.95, end: 1.0).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)), child: child)),
                child: _isChangingMonth
                    ? (isHorizontalMode ? SingleChildScrollView(key: const ValueKey('h_shimmer'), child: _buildHorizontalViewShimmer()) : _buildVerticalViewShimmer())
                    : (isHorizontalMode ? _buildHorizontalView() : _buildVerticalView()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS BUILDERS ---
  Widget _buildAppBar(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: theme.shadowColor, blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(isHorizontalMode ? Icons.arrow_back_ios_new_rounded : Icons.arrow_back_rounded, color: theme.colorScheme.primary),
            onPressed: () {
              if (isHorizontalMode) {
                setState(() { isHorizontalMode = false; selectedMonth = 0; selectedDay = 0; _mareasDelDia = []; selectedTideIndex = null; });
              } else {
                Navigator.of(context).maybePop();
              }
            },
            tooltip: "Regresar",
          ),
          Expanded(
            child: GestureDetector(
              onTap: _showPortSelector,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on, color: theme.colorScheme.primary, size: 22),
                  const SizedBox(width: 8),
                  Flexible(
                    child: ValueListenableBuilder<String>(
                      valueListenable: selectedPortNotifier,
                      builder: (context, value, _) => Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(onPressed: _showPortSelector, icon: Icon(Icons.sync_rounded, color: theme.colorScheme.primary), tooltip: 'Cambiar Puerto'),
        ],
      ),
    );
  }

  Widget _buildVerticalView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: MesVerticalView(
        key: const ValueKey<String>('vertical_view'),
        initialYear: selectedYear,
        months: months,
        onMonthTap: (year, monthNum) {
          setState(() { selectedYear = year; });
          int dayToSelect = 1;
          final now = DateTime.now();
          if (year == now.year && monthNum == now.month) {
            dayToSelect = now.day;
          }
          _loadMareasDelDia(
            showLoader: true,
            monthToLoad: monthNum,
            dayToLoad: dayToSelect,
            changeViewOnLoad: true,
          );
        },
      ),
    );
  }

  Widget _buildHorizontalView() {
    return SingleChildScrollView(
      key: ValueKey<int>(selectedMonth),
      child: Column(
        children: [
          _buildHorizontalMonthScroller(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: MesHorizontalView(
              months: months,
              selectedMonth: selectedMonth,
              selectedDay: selectedDay,
              selectedYear: selectedYear,
              mareasDelDia: _mareasDelDia,
              selectedTideIndex: selectedTideIndex,
              onTideSelect: (int index) => setState(() => selectedTideIndex = (selectedTideIndex == index) ? null : index),
              onDayTap: (day) => _loadMareasDelDia(showLoader: false, monthToLoad: selectedMonth, dayToLoad: day),
              onShowTable: _mostrarTablaMensual,
              isFavorite: isFavorite,
              isFavoriteLoading: _isFavoriteLoading,
              isLoading: _isChangingMonth,
              onToggleFavorite: _toggleFavorite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalMonthScroller() {
    final theme = Theme.of(context);
    return Container(
      height: 56,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: theme.shadowColor, blurRadius: 10, offset: const Offset(0, 4))]),
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: _filteredMonths.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final monthInfo = _filteredMonths[i];
          final originalIndex = months.indexOf(monthInfo);
          final bool isSelected = selectedMonth == originalIndex + 1;
          final bool isInactive = monthInfo.availability == MonthAvailability.inactive;

          return GestureDetector(
            onTap: _isChangingMonth || isInactive ? null : () {
              final newMonth = originalIndex + 1;
              if (newMonth != selectedMonth) _loadMareasDelDia(showLoader: true, monthToLoad: newMonth, dayToLoad: 1);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 80,
              decoration: BoxDecoration(color: isSelected ? theme.colorScheme.primary : Colors.transparent, borderRadius: BorderRadius.circular(28)),
              alignment: Alignment.center,
              child: Text(
                monthInfo.name.substring(0, 3).toUpperCase(),
                style: TextStyle(
                  color: isInactive ? theme.disabledColor : (isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- SHIMMER WIDGETS ---
  Widget _buildHorizontalViewShimmer() {
    final theme = Theme.of(context);
    final baseColor = theme.brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = theme.brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        children: [
          _buildHorizontalMonthScroller(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 150, height: 24, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(4))),
                    const Spacer(),
                    Container(width: 80, height: 30, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(12))),
                    const SizedBox(width: 8),
                    Container(width: 36, height: 36, decoration: BoxDecoration(color: baseColor, shape: BoxShape.circle)),
                  ],
                ),
                const SizedBox(height: 8.0),
                _buildCalendarShimmer(),
                const SizedBox(height: 12.0),
                _buildTideShimmer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalViewShimmer() {
    final theme = Theme.of(context);
    final baseColor = theme.brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = theme.brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[100]!;
    
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(width: 30, height: 30, decoration: BoxDecoration(color: baseColor, shape: BoxShape.circle)),
                Container(width: 100, height: 24, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(4))),
                Container(width: 30, height: 30, decoration: BoxDecoration(color: baseColor, shape: BoxShape.circle)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 6,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 1.2),
                itemBuilder: (context, index) => Container(height: 120, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(20))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarShimmer() {
    final theme = Theme.of(context);
    final baseColor = theme.brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[300]!;
    
    return Card(
      color: theme.cardColor,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 0,
      shadowColor: theme.shadowColor,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: theme.dividerColor, width: 1)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: List.generate(7, (index) => Expanded(child: Center(child: Container(width: 30, height: 15, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(4))))))),
            const SizedBox(height: 8),
            Column(children: List.generate(6, (weekIndex) => Row(children: List.generate(7, (dayIndex) => Expanded(child: Container(width: 48, height: 48, margin: const EdgeInsets.all(4), decoration: BoxDecoration(color: baseColor, shape: BoxShape.circle))))))),
          ],
        ),
      ),
    );
  }

  Widget _buildTideShimmer() {
    final theme = Theme.of(context);
    final baseColor = theme.brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[300]!;
    
    return Column(
      children: [
        Container(height: 250, clipBehavior: Clip.hardEdge, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(22))),
        const SizedBox(height: 20.0),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Card(
            color: theme.cardColor,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: theme.dividerColor, width: 1.5)),
            clipBehavior: Clip.antiAlias,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: 4,
              separatorBuilder: (_, __) => Divider(color: theme.dividerColor, height: 1.5),
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 22, height: 22, decoration: BoxDecoration(color: baseColor, shape: BoxShape.circle)), const SizedBox(width: 8), Container(width: 80, height: 16, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(4)))]),
                      Container(width: 90, height: 24, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(12))),
                      Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [Container(width: 60, height: 16, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(4))), const SizedBox(height: 4), Row(children: [Container(width: 40, height: 12, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(4))), const SizedBox(width: 4), Container(width: 16, height: 16, decoration: BoxDecoration(color: baseColor, shape: BoxShape.circle))])]),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
