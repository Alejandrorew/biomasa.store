import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:another_flushbar/flushbar.dart';
import '../widgets/port_selector_sheet.dart';
import 'mes_selectio.dart';
import 'settings_section.dart';
import 'favorite_ports_section.dart';

class HomeScreen extends StatefulWidget {
  final String? successMessage;

  const HomeScreen({Key? key, this.successMessage}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Muestra un mensaje de éxito si se proporciona uno (ej. después del registro)
    // Usar addPostFrameCallback asegura que el contexto esté disponible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.successMessage != null && mounted) {
        _showSuccessFlushbar();
      }
    });
  }

  /// Muestra una barra de notificación (Flushbar) con un estilo profesional
  /// que se adapta al tema actual (claro/oscuro).
  void _showSuccessFlushbar() {
    final theme = Theme.of(context);
    Flushbar(
      messageText: Text(
        "¡Cuenta creada exitosamente!",
        style: TextStyle(
          color: theme.colorScheme.onSurface, // Color de texto adaptable
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      icon: Icon(
        Icons.check_circle_outline_rounded,
        color: theme.colorScheme.primary, // Color de ícono adaptable
      ),
      backgroundColor: theme.cardColor, // Color de fondo adaptable
      borderRadius: BorderRadius.circular(16),
      margin: const EdgeInsets.all(20),
      duration: const Duration(seconds: 4),
      flushbarPosition: FlushbarPosition.TOP,
      animationDuration: const Duration(milliseconds: 500),
      boxShadows: [
        BoxShadow(
          color: theme.shadowColor, // Color de sombra adaptable
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeInCubic,
    ).show(context);
  }

  /// Devuelve un saludo personalizado según la hora del día.
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Buenos días";
    if (hour < 18) return "Buenas tardes";
    return "Buenas noches";
  }

  /// Navega a la pantalla de configuración.
  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsSection()),
    );
  }

  /// Maneja la acción de búsqueda, mostrando el modal para seleccionar un puerto.
  void _handleSearchTap() async {
    final selectedPort = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // El color lo define el widget del modal
      builder: (context) => const PortSelectorSheet(
        ports: [
          "Bahía de Caráquez", "Puerto Guayaquil", "Puerto Bolívar",
          "Puerto Manta", "Puerto Esmeraldas", "Puerto La Libertad",
          "Puerto Salinas", "Puerto Balao",
        ],
      ),
    );
    if (selectedPort != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MesSelection(
            // Pasa el puerto seleccionado a la siguiente pantalla
            initialNotifier: ValueNotifier<String>(selectedPort),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    // Obtiene el primer nombre del usuario para un saludo más personal.
    final userName = user?.displayName?.split(' ').first ?? "Usuario";
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      // Usa el color de fondo del tema actual.
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: (screenHeight * 0.29).clamp(250.0, 340.0),
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            surfaceTintColor: Colors.transparent, // Evita tinte de color en scroll
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                // SOLUCIÓN: Envolver la columna en un SingleChildScrollView
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(), // El scroll principal ya lo maneja CustomScrollView
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      // Eliminamos MainAxisAlignment.spaceEvenly para que el contenido fluya naturalmente
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getGreeting(),
                                    // Usa el estilo de texto del tema.
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  Text(
                                    userName,
                                    // Usa un estilo de texto más grande del tema.
                                    style: theme.textTheme.displaySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: _navigateToSettings,
                              child: Icon(
                                Icons.settings_outlined,
                                // Usa el color de ícono del tema.
                                color: theme.iconTheme.color,
                                size: 30,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Construye los cards usando el tema actual.
                        _buildInfoCard(theme),
                        const SizedBox(height: 12),
                        _buildSearchCard(theme),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SizedBox(height: 16),
                  // Esta sección también necesitará usar colores del tema.
                  FavoritePortsSection(),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Center(
                child: Opacity(
                  opacity: 0.6,
                  child: Image.asset(
                    'assets/logo_cir.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                    // Aplica un filtro de color solo en modo oscuro para mejorar la visibilidad.
                    color: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.5) : null,
                    colorBlendMode: BlendMode.modulate,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el card de información usando propiedades del tema.
  Widget _buildInfoCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.cardColor, // Color de fondo del card desde el tema
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor, // Color de la sombra desde el tema
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Los datos de mareas y fases de lunas son del libro "Tablas de mareas y datos astronómicos del Sol y la Luna" del INOCAR.',
              style: theme.textTheme.bodySmall, // Estilo de texto desde el tema
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el card de búsqueda que también respeta el tema.
  Widget _buildSearchCard(ThemeData theme) {
    return GestureDetector(
      onTap: _handleSearchTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: theme.cardColor, // Color de fondo del card desde el tema
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor, // Color de la sombra desde el tema
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: theme.colorScheme.primary, size: 24),
            const SizedBox(width: 16),
            Text(
              'Buscar puertos...',
              // Usa el estilo de texto del tema y ajusta la opacidad para un look más sutil.
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 16,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8)
              ),
            ),
          ],
        ),
      ),
    );
  }
}
