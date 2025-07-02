import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Se importa la pantalla de registro para acceder a la clase AppColors centralizada.
import 'register_screen.dart'; 

// --- Pantalla Principal ---
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // --- Controladores y Estado ---
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // --- Lógica de Negocio ---
  /// Envía un correo de restablecimiento de contraseña utilizando Firebase Auth.
  Future<void> _sendPasswordResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor, ingresa un correo electrónico válido.'),
            backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      // Si el envío es exitoso, muestra el modal de confirmación.
      _showSuccessModal();
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Ocurrió un error. Intenta nuevamente.';
      if (e.code == 'user-not-found') {
        errorMessage = 'No se encontró una cuenta con este correo.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'El formato del correo no es válido.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(errorMessage), backgroundColor: Colors.redAccent),
      );
    } finally {
      // Asegura que el widget todavía está en el árbol antes de actualizar el estado.
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Muestra un modal de confirmación en la parte inferior de la pantalla.
  void _showSuccessModal() {
    // Los colores ahora vienen de la clase AppColors importada.
    // Asegúrate que los colores del nuevo diseño estén definidos ahí.
    // Ejemplo: AppColors.cardBg, AppColors.button, etc.
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A35), // Color del modal (cardBg)
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono de check
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.mark_email_read_outlined, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 24),
              // Título del modal
              const Text(
                'Revisa tu correo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              // Descripción del modal
              const Text(
                'Se han enviado las instrucciones para recuperar tu contraseña. Por favor, revisa tu correo ahora.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFAAAAAA), // secondaryText
                  fontSize: 16,
                  height: 1.5
                ),
              ),
              const SizedBox(height: 32),
              // Botón de acción del modal
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3D3D4A), // button
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    // Cierra el modal y luego la pantalla de "olvidé contraseña"
                    Navigator.of(context).pop(); // Cierra el modal
                    Navigator.of(context).pop(); // Regresa a la pantalla de login
                  },
                  child: const Text(
                    'Revisar Correo',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  // --- Construcción de la Interfaz Gráfica (UI) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C23), // background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título principal
              const Text(
                'Usa tu correo para\nrecuperar tu contraseña.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),
              // Subtítulo
              const Text(
                'Ingresa tu correo para recuperar tu contraseña fácilmente.',
                style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 16, height: 1.5), // secondaryText
              ),
              const SizedBox(height: 48),
              // Campo de texto para Email
              _buildTextField(
                label: 'Correo Electrónico',
                controller: _emailController,
                hintText: 'tu.correo@ejemplo.com',
                keyboardType: TextInputType.emailAddress,
              ),
              const Spacer(), // Empuja el botón hacia abajo
              // Botón principal de acción
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3D3D4A), // button
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _sendPasswordResetEmail,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child:
                              CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                      : const Text(
                          'Continuar',
                          style: TextStyle(
                              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 20), // Espacio inferior para que no quede pegado
            ],
          ),
        ),
      ),
    );
  }

  /// Widget reutilizable para crear los campos de texto del formulario.
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14), // secondaryText
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          style: const TextStyle(color: Colors.white),
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Color(0xFFAAAAAA)), // secondaryText
            filled: true,
            fillColor: const Color(0xFF2A2A35), // cardBg
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: const Color(0xFF3D3D4A).withOpacity(0.5)), // button
            ),
          ),
        ),
      ],
    );
  }
}
