import 'package:flutter/material.dart';

import 'register_tab.dart';
import 'login_tab.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyDark,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(
          children: [
            // Fondo PNG
            Positioned.fill(
              child: Image.asset(
                'assets/fondo_or.png',
                fit: BoxFit.cover,
              ),
            ),
            // Estructura responsiva: logo y modal en columna
            Column(
              children: [
                // Espacio superior proporcional
                SizedBox(height: MediaQuery.of(context).size.height * 0.07),
                // Logo responsivo
                Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final logoWidth = screenWidth * 0.55; // 55% del ancho de pantalla
                      return Image.asset(
                        'assets/log.png',
                        width: logoWidth,
                        // Altura proporcional al ancho para mantener aspecto cuadrado
                        height: logoWidth,
                      );
                    },
                  ),
                ),
                // Espacio entre logo y modal
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                // Modal flexible que ocupa el resto de la pantalla
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: constraints.maxHeight,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                              decoration: BoxDecoration(
                                color: AppColors.cardBg,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(32),
                                  topRight: Radius.circular(32),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 32,
                                    offset: const Offset(0, -16),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TabBar(
                                    controller: _tabController,
                                    indicator: UnderlineTabIndicator(
                                      borderSide: BorderSide(width: 4, color: AppColors.navy),
                                      insets: const EdgeInsets.symmetric(horizontal: 40),
                                    ),
                                    labelColor: AppColors.navy,
                                    unselectedLabelColor: AppColors.blue,
                                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                    tabs: const [
                                      Tab(text: 'Registro'),
                                      Tab(text: 'Iniciar sesión'),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  Flexible(
                                    child: TabBarView(
                                      controller: _tabController,
                                      physics: const NeverScrollableScrollPhysics(),
                                      children: const [
                                        SingleChildScrollView(
                                          padding: EdgeInsets.only(bottom: 24),
                                          child: RegisterTab(),
                                        ),
                                        SingleChildScrollView(
                                          padding: EdgeInsets.only(bottom: 24),
                                          child: LoginTab(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ================== CÓDIGO REUTILIZABLE ==================
// Colocado aquí para no crear nuevos archivos, como se solicitó.

/// Clase para centralizar la paleta de colores de la aplicación.
/// Esto facilita el mantenimiento y asegura la consistencia visual.
class AppColors {
  static const Color navyDark = Color(0xFF001534);
  static const Color navy = Color(0xFF233A59);
  static const Color blue = Color(0xFF426A8C);
  static const Color cardBg = Color(0xFFF2F2F2);
  static const Color white = Colors.white;
}

/// Un widget de campo de texto personalizado y reutilizable.
/// Encapsula el estilo común para los campos de formulario, reduciendo la duplicación de código.
class CustomFormField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputAction textInputAction;
  final FocusNode? focusNode;
  final void Function(String)? onFieldSubmitted;
  final Widget? suffixIcon;
  final String? errorText;

  const CustomFormField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.validator,
    this.obscureText = false,
    this.textInputAction = TextInputAction.next,
    this.focusNode,
    this.onFieldSubmitted,
    this.suffixIcon,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      validator: validator,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.blue),
        hintText: hintText,
        filled: true,
        fillColor: AppColors.cardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        suffixIcon: suffixIcon,
        errorText: errorText,
      ),
    );
  }
}
