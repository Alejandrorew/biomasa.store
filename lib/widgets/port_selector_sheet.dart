import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/services.dart';

// --- Widget del Modal de Búsqueda (Sheet) con Diseño Profesional ---
class PortSelectorSheet extends StatefulWidget {
  final List<String> ports;
  final List<String> recentPorts;

  const PortSelectorSheet({
    Key? key,
    required this.ports,
    this.recentPorts = const [],
  }) : super(key: key);

  @override
  State<PortSelectorSheet> createState() => _PortSelectorSheetState();
}

class _PortSelectorSheetState extends State<PortSelectorSheet> {
  late final TextEditingController _searchController;
  late final FocusNode _focusNode;
  late List<String> _recents;
  final _listKey = GlobalKey<AnimatedListState>();

  // Puertos sugeridos, esto podría venir de una configuración remota
  final List<String> _predefinedPorts = [
    "Bahía de Caráquez", "Puerto Guayaquil", "Puerto Bolívar", "Isla Puna", "Posorja", "Manta", "Esmeraldas"
  ];

  @override
  void initState() {
    super.initState();
    _recents = List<String>.from(widget.recentPorts);
    _searchController = TextEditingController();
    _focusNode = FocusNode();

    _searchController.addListener(() {
      setState(() {}); // Actualiza la UI al escribir en el buscador
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // =========== FIX START ===========
  // Se añade el parámetro ThemeData para que pueda ser pasado a _buildAnimatedListItem
  void _removeRecent(int index, String port, ThemeData theme) {
    if (_recents.contains(port)) {
      final removedPort = _recents.removeAt(index);
      _listKey.currentState?.removeItem(
        index,
        (context, animation) => _buildAnimatedListItem(
          port: removedPort,
          animation: animation,
          theme: theme, // Se pasa el theme recibido
          onTap: () {},
        ),
        duration: const Duration(milliseconds: 400),
      );
      setState(() {});
    }
  }
  // =========== FIX END ===========

  void _onSelectPort(String port) {
    HapticFeedback.lightImpact();
    Navigator.pop(context, port);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filtered = widget.ports
        .where((p) => p.toLowerCase().contains(_searchController.text.toLowerCase()))
        .toList();

    // Color del sheet con efecto "glassmorphism" adaptable
    final sheetColor = isDark
        ? const Color.fromRGBO(30, 30, 30, 0.85) // Tono oscuro translúcido
        : const Color.fromRGBO(248, 248, 248, 0.9); // Tono claro translúcido

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: sheetColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 30,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildDragHandle(theme),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _buildSearchBar(theme),
                  ),
                  Expanded(
                    child: ListView(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: _searchController.text.isEmpty
                          ? _buildInitialContent(theme)
                          : _buildSearchResults(filtered, theme),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDragHandle(ThemeData theme) {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: theme.dividerColor,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final searchBarFillColor = isDark ? Colors.black.withOpacity(0.3) : Colors.grey.shade200;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search, color: theme.iconTheme.color),
              hintText: 'Buscar puerto...',
              hintStyle: theme.textTheme.bodyMedium,
              filled: true,
              fillColor: searchBarFillColor,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      color: theme.iconTheme.color,
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancelar', 
            style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)
          ),
        ),
      ],
    );
  }

  List<Widget> _buildInitialContent(ThemeData theme) {
    return [
      Text(
        'Puertos Populares',
        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _predefinedPorts.map((port) => _buildPuertoChip(nombre: port, theme: theme)).toList(),
      ),
      const SizedBox(height: 24),
      Text(
        'Recientes',
        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      _buildRecentPorts(theme),
    ];
  }

  List<Widget> _buildSearchResults(List<String> filtered, ThemeData theme) {
    if (filtered.isEmpty) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 48.0),
            child: Text('No se encontraron puertos.', style: theme.textTheme.bodyMedium),
          ),
        )
      ];
    }
    return filtered.map((port) {
      return _buildListItem(port: port, onTap: () => _onSelectPort(port), theme: theme);
    }).toList();
  }

  Widget _buildPuertoChip({required String nombre, required ThemeData theme}) {
    final isDark = theme.brightness == Brightness.dark;
    final chipBackgroundColor = isDark ? theme.colorScheme.surface.withOpacity(0.5) : theme.colorScheme.secondary.withOpacity(0.1);
    
    return ActionChip(
      label: Text(nombre, style: theme.textTheme.labelLarge),
      avatar: Icon(Icons.anchor, size: 20, color: theme.colorScheme.primary),
      backgroundColor: chipBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onPressed: () => _onSelectPort(nombre),
      side: BorderSide.none,
    );
  }

  Widget _buildRecentPorts(ThemeData theme) {
    if (_recents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    'assets/shrimp_z.png',
                    width: 72,
                    height: 64,
                    color: theme.textTheme.bodySmall?.color,
                    colorBlendMode: BlendMode.srcIn,
                    errorBuilder: (context, error, stackTrace) => 
                      Icon(Icons.bedtime_outlined, size: 56, color: theme.textTheme.bodySmall?.color),
                  ),
                  Positioned(top: -12, right: -12, child: Text('z', style: TextStyle(fontSize: 20, color: theme.textTheme.bodySmall?.color, fontWeight: FontWeight.bold))),
                  Positioned(top: 0, right: -18, child: Text('z', style: TextStyle(fontSize: 14, color: theme.textTheme.bodySmall?.color, fontWeight: FontWeight.bold))),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'No hay actividad reciente',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }
    return AnimatedList(
      key: _listKey,
      initialItemCount: _recents.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index, animation) {
        final port = _recents[index];
        return _buildAnimatedListItem(
          port: port,
          animation: animation,
          theme: theme,
          onTap: () => _onSelectPort(port),
          trailing: IconButton(
            icon: Icon(Icons.close, color: theme.textTheme.bodySmall?.color),
            // =========== FIX START ===========
            // Se pasa el theme al momento de llamar a la función
            onPressed: () => _removeRecent(index, port, theme),
            // =========== FIX END ===========
          ),
        );
      },
    );
  }

  Widget _buildAnimatedListItem({
    required String port,
    required Animation<double> animation,
    required ThemeData theme,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.3, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: _buildListItem(port: port, onTap: onTap, trailing: trailing, theme: theme),
      ),
    );
  }

  Widget _buildListItem({
    required String port,
    required VoidCallback onTap,
    required ThemeData theme,
    Widget? trailing,
  }) {
    return ListTile(
      title: Text(port, style: theme.textTheme.bodyLarge),
      subtitle: Text('Ecuador', style: theme.textTheme.bodyMedium),
      leading: Icon(Icons.waves, color: theme.colorScheme.primary),
      trailing: trailing,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    );
  }
}
