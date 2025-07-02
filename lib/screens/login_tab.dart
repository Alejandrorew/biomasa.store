import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart' hide AppColors; // <-- SOLUCIÓN: Ocultamos AppColors de este import
import 'register_screen.dart'; // Mantenemos este para acceder a AppColors y CustomFormField
  import 'forgot_password_screen.dart'; // Importamos la pantalla de restablecimiento de contraseña

class LoginTab extends StatefulWidget {
  final VoidCallback? onLoginSuccess;

  const LoginTab({super.key, this.onLoginSuccess});

  @override
  State<LoginTab> createState() => _LoginTabState();
}

class _LoginTabState extends State<LoginTab> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _isLoading = false;
  bool _showPassword = false;
  String? _emailError, _passwordError;
  final Set<String> _touched = {};
  bool _triedSubmit = false;

  bool get _isFormFilled =>
      _emailController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() {
      if (!_emailFocus.hasFocus) setState(() => _touched.add('email'));
    });
    _passwordFocus.addListener(() {
      if (!_passwordFocus.hasFocus) setState(() => _touched.add('password'));
    });
    _emailController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (!_touched.contains('email') && !_triedSubmit) return null;
    if (value == null || value.trim().isEmpty) return 'Ingresa tu correo electrónico';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value.trim())) return 'Correo electrónico inválido';
    return null;
  }

  String? _validatePassword(String? value) {
    if (!_touched.contains('password') && !_triedSubmit) return null;
    if (value == null || value.isEmpty) return 'Ingresa tu contraseña';
    if (value.length < 6) return 'La contraseña debe tener al menos 6 caracteres';
    return null;
  }

  Future<void> _onLoginSubmit() async {
    // Limpia errores anteriores antes de validar
    setState(() {
      _emailError = null;
      _passwordError = null;
      _triedSubmit = true;
    });

    if (!(_formKey.currentState?.validate() ?? false)) return;
    
    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      User? user = userCredential.user;
      if (user != null && user.emailVerified) {
        _formKey.currentState?.reset();
        widget.onLoginSuccess?.call();
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        await FirebaseAuth.instance.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes verificar tu correo antes de ingresar.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      String? tempEmailError;
      String? tempPasswordError;
      String snackBarMessage = 'Ocurrió un error. Intenta nuevamente.';

      switch (e.code) {
        case 'user-not-found':
        case 'invalid-email':
          tempEmailError = 'Correo electrónico inválido o no registrado.';
          break;
        case 'wrong-password':
          tempPasswordError = 'La contraseña es incorrecta.';
          break;
        case 'user-disabled':
          snackBarMessage = 'Esta cuenta ha sido deshabilitada.';
          break;
      }
      
      if (tempEmailError == null && tempPasswordError == null){
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(snackBarMessage)),
          );
      }

      setState(() {
        _emailError = tempEmailError;
        _passwordError = tempPasswordError;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 24),
          // Campo de correo electrónico reutilizable
          CustomFormField(
            controller: _emailController,
            hintText: 'Correo electrónico',
            icon: Icons.mail,
            focusNode: _emailFocus,
            validator: _validateEmail,
            errorText: _emailError,
            onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFocus),
          ),
          const SizedBox(height: 16),
          // Campo de contraseña reutilizable
          CustomFormField(
            controller: _passwordController,
            focusNode: _passwordFocus,
            hintText: 'Contraseña',
            icon: Icons.lock,
            obscureText: !_showPassword,
            validator: _validatePassword,
            errorText: _passwordError,
            onFieldSubmitted: (_) => _onLoginSubmit(),
            suffixIcon: IconButton(
              icon: Icon(
                _showPassword ? Icons.visibility : Icons.visibility_off,
                color: AppColors.blue,
              ),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
          ),
          const SizedBox(height: 24),
          // Botón de iniciar sesión
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              onPressed: _isLoading ? null : _onLoginSubmit,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Iniciar sesión',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _isFormFilled ? AppColors.white : Colors.grey[400],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          // Olvidaste tu contraseña
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
              );
            },
            child: Text(
              '¿Olvidaste tu contraseña?',
              style: TextStyle(
                color: AppColors.blue,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 14),
          // Mensaje de soporte
          const Text(
            "Contáctanos: ",
            style: TextStyle(color: Colors.black54, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          SelectableText(
            "soporte.app@aquametrics.com.ec",
            style: TextStyle(
              color: AppColors.blue,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
