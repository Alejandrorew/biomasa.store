import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import './mes_selectio.dart';
import '../services/mareas_service.dart';
import '../models/mareas.dart';
import '../theme.dart'; // Importar el theme global

// --- CONSTANTES Y ENUMS ---
const int maxFavoritePorts = 2;
enum TideStatus { rising, falling, stable, loading }

// --- MODELO ---
class FavoritePort {
  final String id;
  final String name;
  final String? code;
  final String? country;
  // Añadimos los campos que faltaban del archivo original
  final String? currentTide;
  final String? nextTide;
  final String? nextTideTime;
  final double? tideLevel;


  FavoritePort({
    required this.id,
    required this.name,
    this.code,
    this.country,
    this.currentTide,
    this.nextTide,
    this.nextTideTime,
    this.tideLevel,
  });

  factory FavoritePort.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FavoritePort(
      id: doc.id,
      name: data['name'] ?? '',
      code: data['code'],
      country: data['country'],
      currentTide: data['currentTide'],
      nextTide: data['nextTide'],
      nextTideTime: data['nextTideTime'],
      tideLevel: (data['tideLevel'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'code': code,
      'country': country,
      'currentTide': currentTide,
      'nextTide': nextTide,
      'nextTideTime': nextTideTime,
      'tideLevel': tideLevel,
    };
  }
}

// --- WIDGET PRINCIPAL ---
class FavoritePortsSection extends StatefulWidget {
  const FavoritePortsSection({Key? key}) : super(key: key);

  @override
  State<FavoritePortsSection> createState() => _FavoritePortsSectionState();
}

class _FavoritePortsSectionState extends State<FavoritePortsSection> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<FavoritePort> _favoritePorts = [];
  bool _loading = true;
  StreamSubscription<QuerySnapshot>? _favoritesSubscription;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void dispose() {
    _favoritesSubscription?.cancel();
    super.dispose();
  }

  void _navigateToPortDetails(String portName) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => MesSelection(initialNotifier: ValueNotifier<String>(portName))));
  }

  Future<void> _loadFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    _favoritesSubscription = FirebaseFirestore.instance
        .collection('users').doc(user.uid).collection('favorites')
        .limit(maxFavoritePorts)
        .snapshots().listen((snapshot) {
      if (!mounted) return;
      final serverPorts = snapshot.docs.map((doc) => FavoritePort.fromFirestore(doc)).toList();
      _updateAnimatedList(serverPorts);
      if(mounted) setState(() => _loading = false);
    }, onError: (error) {
      if (mounted) setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar favoritos: $error'), backgroundColor: Colors.redAccent));
    });
  }
  
  void _updateAnimatedList(List<FavoritePort> latestFirestorePorts) {
    for (int i = _favoritePorts.length - 1; i >= 0; i--) {
      final oldPort = _favoritePorts[i];
      if (!latestFirestorePorts.any((newPort) => newPort.id == oldPort.id)) {
        final removedPort = _favoritePorts.removeAt(i);
        _listKey.currentState?.removeItem(i, (context, animation) => _buildAnimatedItem(removedPort, context, animation), duration: const Duration(milliseconds: 500));
      }
    }

    for (int i=0; i < latestFirestorePorts.length; i++) {
      final newPort = latestFirestorePorts[i];
      if (!_favoritePorts.any((p) => p.id == newPort.id)) {
          _favoritePorts.insert(i, newPort);
          _listKey.currentState?.insertItem(i, duration: const Duration(milliseconds: 500));
      }
    }
  }
  
  Future<void> _removeFavorite(String portId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('favorites').doc(portId).delete();
  }

  Widget _buildAnimatedItem(FavoritePort port, BuildContext context, Animation<double> animation) {
    // El color de borrado es semántico, no necesita cambiar con el tema.
    const deleteColor = Color(0xFFEF4444);

    return FadeTransition(
      opacity: animation,
      child: SizeTransition(
        sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Dismissible(
              key: ValueKey(port.id),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => _removeFavorite(port.id),
              background: Container(
                padding: const EdgeInsets.only(right: 20.0),
                decoration: BoxDecoration(color: deleteColor, borderRadius: BorderRadius.circular(24)),
                alignment: Alignment.centerRight,
                child: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 30),
              ),
              child: GestureDetector(
                onTap: () => _navigateToPortDetails(port.name),
                child: RealtimeFavoritePortCard(port: port),
              ),
            ),
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme),
        const SizedBox(height: 20),
        if (_loading)
          Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
        else if (_favoritePorts.isEmpty)
          _buildEmptyState(theme)
        else
          AnimatedList(
            key: _listKey,
            initialItemCount: _favoritePorts.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index, animation) {
              final port = _favoritePorts[index];
              return _buildAnimatedItem(port, context, animation);
            },
          ),
      ],
    );
  }

  Widget _buildSectionHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('Puertos Favoritos', style: theme.textTheme.headlineSmall),
        IconButton(
          icon: Icon(Icons.refresh_rounded, color: theme.colorScheme.primary, size: 26),
          tooltip: 'Recargar favoritos',
          onPressed: () async {
            if (_loading) return;
            setState(() => _loading = true);
            await _favoritesSubscription?.cancel();
            _favoritePorts.clear();
            _loadFavorites();
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    // Color de acento para la estrella, puede ser del tema o uno específico.
    const accentColor = Color(0xFFFF9F0A);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: theme.shadowColor, blurRadius: 10, offset: const Offset(0, 4))
                ]
              ),
              child: Column(
                children: [
                  const Icon(Icons.star_border_rounded, size: 48, color: accentColor),
                  const SizedBox(height: 16),
                  Text(
                    '¡Aún no hay favoritos!', 
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Añade hasta 2 puertos. Desliza para eliminar.', 
                    style: theme.textTheme.bodyMedium, 
                    textAlign: TextAlign.center
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class RealtimeFavoritePortCard extends StatefulWidget {
  final FavoritePort port;
  const RealtimeFavoritePortCard({Key? key, required this.port}) : super(key: key);

  @override
  _RealtimeFavoritePortCardState createState() => _RealtimeFavoritePortCardState();
}

class _RealtimeFavoritePortCardState extends State<RealtimeFavoritePortCard> {
  TideStatus _status = TideStatus.loading;
  String _nextTideInfo = '';

  @override
  void initState() {
    super.initState();
    _fetchRealtimeTideData();
  }

  // --- Lógica de datos (sin cambios) ---
  double _hourToDouble(String hora) {
    if (hora.isEmpty) return 0.0;
    try {
      final h = int.parse(hora.padLeft(4, '0').substring(0, 2));
      final min = int.parse(hora.padLeft(4, '0').substring(2, 4));
      return h + min / 60.0;
    } catch (e) { return 0.0; }
  }

  String _formatNextTideInfo(Marea marea, bool esPleamar) {
    String horaFormateada;
    try {
        String horaRaw = marea.hora.padLeft(4, '0');
        final time24 = DateFormat("HHmm").parse(horaRaw);
        horaFormateada = DateFormat("HH:mm").format(time24);
    } catch (e) {
      horaFormateada = marea.hora.length >= 4 ? '${marea.hora.padLeft(4, '0').substring(0, 2)}:${marea.hora.padLeft(4, '0').substring(2, 4)}' : marea.hora;
    }
    String alturaFormateada = marea.altura.replaceAll(',', '.');
    return '${esPleamar ? "Pleamar" : "Bajamar"} a la(s) $horaFormateada (${alturaFormateada} m)';
  }

  Future<void> _fetchRealtimeTideData() async {
    if (!mounted) return;
    setState(() => _status = TideStatus.loading);

    final mareasService = MareasService();
    final now = DateTime.now();
    final diaHoy = DateFormat('EEEE d', 'es_ES').format(now).toUpperCase();
    final mesHoy = DateFormat('MMMM', 'es_ES').format(now).toLowerCase();
    
    try {
      final mareasDelDia = await mareasService.obtenerMareasPorDiaYPuerto(diaHoy, widget.port.name, mesHoy);
      mareasDelDia.sort((a, b) => _hourToDouble(a.hora).compareTo(_hourToDouble(b.hora)));

      if (!mounted) return;

      Marea? proximaMarea;
      for (final marea in mareasDelDia) {
        String horaRaw = marea.hora.padLeft(4, '0');
        final hora = int.tryParse(horaRaw.substring(0, 2)) ?? 0;
        final minuto = int.tryParse(horaRaw.substring(2, 4)) ?? 0;
        final fechaMarea = DateTime(now.year, now.month, now.day, hora, minuto);

        if (fechaMarea.isAfter(now)) {
          proximaMarea = marea;
          break;
        }
      }

      List<Marea> listaDeReferencia = mareasDelDia;

      if (proximaMarea == null) {
        final tomorrow = now.add(const Duration(days: 1));
        final diaManana = DateFormat('EEEE d', 'es_ES').format(tomorrow).toUpperCase();
        final mesManana = DateFormat('MMMM', 'es_ES').format(tomorrow).toLowerCase();
        
        final mareasDelManana = await mareasService.obtenerMareasPorDiaYPuerto(diaManana, widget.port.name, mesManana);
        mareasDelManana.sort((a, b) => _hourToDouble(a.hora).compareTo(_hourToDouble(b.hora)));

        if (!mounted) return;
        if (mareasDelManana.isNotEmpty) {
          proximaMarea = mareasDelManana.first;
          listaDeReferencia = mareasDelManana;
        }
      }
      
      if (proximaMarea != null) {
        final index = listaDeReferencia.indexWhere((m) => m.hora == proximaMarea!.hora);
        bool esPleamar; 
        if (index > 0) {
          esPleamar = (double.tryParse(proximaMarea.altura.replaceAll(',', '.')) ?? 0.0) > (double.tryParse(listaDeReferencia[index - 1].altura.replaceAll(',', '.')) ?? 0.0);
        } else if (listaDeReferencia.length > 1){
           esPleamar = (double.tryParse(proximaMarea.altura.replaceAll(',', '.')) ?? 0.0) < (double.tryParse(listaDeReferencia[index + 1].altura.replaceAll(',', '.')) ?? 0.0);
        } else {
          esPleamar = (double.tryParse(proximaMarea.altura.replaceAll(',', '.')) ?? 0.0) > 1.5;
        }
        
        if (!mounted) return;
        setState(() {
          _status = esPleamar ? TideStatus.rising : TideStatus.falling;
          _nextTideInfo = _formatNextTideInfo(proximaMarea!, !esPleamar); // La imagen muestra "Bajamar", así que el estado es "Bajando". La próxima es la contraria.
        });
      } else {
        if (!mounted) return;
        setState(() {
          _status = TideStatus.stable;
          _nextTideInfo = 'No hay datos disponibles.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = TideStatus.stable;
        _nextTideInfo = 'Error al cargar datos.';
      });
    }
  }
  
  // --- Métodos de UI (adaptados al tema) ---
  Color _getTideStatusColor() {
    // Estos colores son semánticos (indican estado) y no necesitan cambiar entre temas.
    switch (_status) {
      case TideStatus.rising: return const Color(0xFF30D158); // Verde para subiendo
      case TideStatus.falling: return const Color(0xFFEF4444); // Rojo para bajando
      default: return Colors.grey;
    }
  }

  IconData _getTideStatusIcon() {
    switch (_status) {
      case TideStatus.rising: return Icons.arrow_circle_up_rounded;
      case TideStatus.falling: return Icons.arrow_circle_down_rounded;
      default: return Icons.hourglass_empty_rounded;
    }
  }
  
  String _getTideStatusText() {
    switch (_status) {
      case TideStatus.rising: return 'Subiendo';
      case TideStatus.falling: return 'Bajando';
      case TideStatus.loading: return 'Cargando...';
      default: return 'Estable';
    }
  }
  
  Widget _buildLoadingShimmer(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[200]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24)
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
                Container(width: 24, height: 24, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                const SizedBox(width: 12),
                Container(width: 150, height: 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
              ],
            ),
            const SizedBox(height: 16),
            Container(width: 100, height: 20, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 4),
            Container(width: 200, height: 16, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getTideStatusColor();
    final statusTextColor = _status == TideStatus.loading ? theme.textTheme.bodyMedium?.color : statusColor;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: theme.shadowColor, blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.0),
        child: Stack(
          children: [
            Positioned(
              bottom: 0, right: 0, left: 0, height: 80,
              child: ClipPath(
                clipper: WaveClipper(),
                child: Container(
                  decoration: BoxDecoration(
                     gradient: LinearGradient(
                      colors: [statusColor.withOpacity(0.3), statusColor.withOpacity(0.1)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    )
                  ),
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _status == TideStatus.loading
                  ? _buildLoadingShimmer(theme)
                  : Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.port.name, 
                                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.chevron_right_rounded, color: theme.textTheme.bodySmall?.color, size: 28),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(children: [
                            Icon(_getTideStatusIcon(), color: statusTextColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _getTideStatusText(), 
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: statusTextColor)
                            ),
                          ]),
                          const SizedBox(height: 4),
                          Text(_nextTideInfo, style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.moveTo(0, size.height * 0.6);
    var firstControlPoint = Offset(size.width / 4, size.height * 0.3);
    var firstEndPoint = Offset(size.width / 2.2, size.height * 0.65);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy, firstEndPoint.dx, firstEndPoint.dy);
    var secondControlPoint = Offset(size.width * (3/4), size.height);
    var secondEndPoint = Offset(size.width, size.height * 0.7);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy, secondEndPoint.dx, secondEndPoint.dy);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
