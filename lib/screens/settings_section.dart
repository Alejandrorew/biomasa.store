import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:another_flushbar/flushbar.dart';
import 'register_screen.dart';
import '../theme_mode_notifier.dart'; // Importa el notifier
import '../main.dart' show themeModeNotifier;
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsSection extends StatefulWidget {
  const SettingsSection({super.key});

  @override
  State<SettingsSection> createState() => _SettingsSectionState();
}

class _SettingsSectionState extends State<SettingsSection> with SingleTickerProviderStateMixin {
  late User? user;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    _nameController.text = user?.displayName ?? "";

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RegisterScreen()),
        (route) => false,
      );
    }
  }

  void _showEditProfileDialog(ThemeData theme) {
    _nameController.text = user?.displayName ?? "";
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: theme.cardColor,
          title: Text('Actualizar Nombre', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: _nameController,
            autofocus: true,
            style: TextStyle(color: theme.colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: 'Nombre y Apellido',
              labelStyle: TextStyle(color: theme.colorScheme.primary),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: theme.colorScheme.primary),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: theme.dividerColor),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
            ),
            TextButton(
              onPressed: () {
                _updateProfile(theme);
                Navigator.of(context).pop();
              },
              child: Text('Guardar', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateProfile(ThemeData theme) async {
    if (_nameController.text.trim().isNotEmpty && user != null) {
      try {
        await user!.updateDisplayName(_nameController.text.trim());
        await user!.reload();
        user = FirebaseAuth.instance.currentUser;
        
        setState(() {});

        if (mounted) {
          Flushbar(
            message: "¡Perfil actualizado con éxito!",
            icon: Icon(Icons.check_circle_outline_rounded, size: 28.0, color: theme.colorScheme.secondary),
            duration: const Duration(seconds: 3),
            backgroundColor: theme.cardColor,
            messageColor: theme.colorScheme.onSurface,
            borderRadius: BorderRadius.circular(16),
            margin: const EdgeInsets.all(20),
            flushbarPosition: FlushbarPosition.TOP,
            boxShadows: [BoxShadow(color: theme.shadowColor, blurRadius: 10)],
          ).show(context);
        }
      } catch (e) {
        if (mounted) {
           Flushbar(
            message: "Error al actualizar el perfil.",
            icon: Icon(Icons.error_outline_rounded, size: 28.0, color: theme.colorScheme.error),
            duration: const Duration(seconds: 3),
            backgroundColor: theme.cardColor,
            messageColor: theme.colorScheme.onSurface,
           ).show(context);
        }
      }
    }
  }

  void _showDataSourceInfo(ThemeData theme) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: theme.cardColor,
              title: Text('Fuente de datos', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              content: Text(
                  'Los datos de mareas y fases lunares son extraídos de las "Tablas de mareas y datos astronómicos del Sol y la Luna" publicadas anualmente por el Instituto Oceanográfico y Antártico de la Armada de Ecuador (INOCAR).',
                  style: TextStyle(color: theme.colorScheme.onSurface),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Entendido', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)))
              ],
            ));
  }
  
   void _showHelpDialog(ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: theme.cardColor,
        title: Text(
          'Ayuda y soporte',
          style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cuenta con nosotros para lo que necesites. Puedes escribirnos:',
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.email_rounded, color: theme.colorScheme.primary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SelectableText(
                      'soporte.app@aquametrics.com.ec',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cerrar',
              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }

  void _confirmDeleteAccount(ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: theme.cardColor,
        title: Text('Eliminar cuenta', style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold)),
        content: Text(
          '¿Estás seguro de que deseas eliminar tu cuenta? Esta acción es irreversible y eliminará todos tus datos.',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar', style: TextStyle(color: theme.colorScheme.primary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteAccount();
            },
            child: Text('Eliminar', style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);

      final favorites = await userDoc.collection('favorites').get();
      for (final doc in favorites.docs) {
        await doc.reference.delete();
      }

      await userDoc.delete();
      await currentUser.delete();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const RegisterScreen()),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuenta eliminada correctamente.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.code == 'requires-recent-login'
                ? 'Por seguridad, vuelve a iniciar sesión para eliminar tu cuenta.'
                : 'Error al eliminar la cuenta: ${e.message}')),
          );
      }
    } catch (e) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Un error ocurrió al eliminar la cuenta: $e')),
            );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final userName = user?.displayName ?? "Usuario";
  final userEmail = user?.email ?? "sin-email@registrado.com";
  final userInitials = (userName.isNotEmpty && userName.contains(' '))
      ? userName.split(' ').where((n) => n.isNotEmpty).map((e) => e[0]).take(2).join()
      : (userName.isNotEmpty ? userName[0] : "U");
  final screenHeight = MediaQuery.of(context).size.height;

  return GestureDetector(
    onHorizontalDragEnd: (details) {
      if (details.primaryVelocity != null && details.primaryVelocity! > 0) {
        Navigator.of(context).pop();
      }
    },
    child: Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Ajustes',
          style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          children: [
            SizedBox(height: screenHeight * 0.02),
            _buildProfileCard(userInitials, userName, userEmail, theme),
            SizedBox(height: screenHeight * 0.03),
            _buildSettingsCard(theme),
            SizedBox(height: screenHeight * 0.03),
            _buildAboutCard(theme),
            SizedBox(height: screenHeight * 0.04),
            // Botón "Eliminar cuenta" fuera de las cards, al final
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.delete_forever_rounded),
              label: const Text(
                'Eliminar cuenta',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              onPressed: () => _confirmDeleteAccount(theme),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildProfileCard(String initials, String name, String email, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: theme.shadowColor,
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
            child: Text(
              initials.toUpperCase(),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: TextStyle(
              fontSize: 16,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Text(
              'Configuración de la Cuenta',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildSettingsButton(
            icon: Icons.edit_outlined,
            label: 'Editar Perfil',
            onTap: () => _showEditProfileDialog(theme),
            theme: theme,
          ),
          Divider(height: 24, indent: 8, endIndent: 8, color: theme.dividerColor),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeModeNotifier,
            builder: (context, mode, _) {
              final isDark = mode == ThemeMode.dark;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: theme.iconTheme.color,
                ),
                title: Text(
                  'Modo Oscuro',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                trailing: Switch(
                  value: isDark,
                  activeColor: theme.colorScheme.primary,
                  onChanged: (val) {
                    themeModeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                  },
                ),
                onTap: () {
                  themeModeNotifier.value =
                      isDark ? ThemeMode.light : ThemeMode.dark;
                },
              );
            },
          ),
          Divider(height: 24, indent: 8, endIndent: 8, color: theme.dividerColor),
          _buildSettingsButton(
            icon: Icons.logout_rounded,
            label: 'Cerrar Sesión',
            onTap: _logout,
            color: theme.colorScheme.error,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Text(
              'Información',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildSettingsButton(
            icon: Icons.info_outline_rounded,
            label: 'Fuente de datos',
            onTap: () => _showDataSourceInfo(theme),
            theme: theme,
          ),
          _buildSettingsButton(
            icon: Icons.help_outline_rounded,
            label: 'Ayuda y soporte',
            onTap: () => _showHelpDialog(theme),
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ThemeData theme,
    Color? color,
  }) {
    final itemColor = color ?? theme.colorScheme.onSurface;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        highlightColor: theme.colorScheme.primary.withOpacity(0.1),
        splashColor: theme.colorScheme.primary.withOpacity(0.2),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: itemColor, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: itemColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: itemColor.withOpacity(0.6), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
