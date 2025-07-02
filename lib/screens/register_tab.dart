import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'email_verification_screen.dart';
import 'register_screen.dart'; // Importamos para acceder a AppColors y CustomFormField

class RegisterTab extends StatefulWidget {
  final VoidCallback? onRegisterSuccess;

  const RegisterTab({super.key, this.onRegisterSuccess});

  @override
  State<RegisterTab> createState() => _RegisterTabState();
}

class _RegisterTabState extends State<RegisterTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  bool _isLoading = false;
  bool _showPassword = false;
  String? _emailError, _passwordError;
  final Set<String> _touched = {};
  bool _triedSubmit = false;

  @override
  void initState() {
    super.initState();
    // Listeners para detectar cuando un campo pierde el foco
    _nameFocus.addListener(() => _handleFocusChange('name', _nameFocus.hasFocus));
    _emailFocus.addListener(() => _handleFocusChange('email', _emailFocus.hasFocus));
    _passwordFocus.addListener(() => _handleFocusChange('password', _passwordFocus.hasFocus));
    _confirmPasswordFocus.addListener(() => _handleFocusChange('confirmPassword', _confirmPasswordFocus.hasFocus));
  }

  void _handleFocusChange(String field, bool hasFocus) {
    if (!hasFocus) {
      setState(() => _touched.add(field));
      _formKey.currentState?.validate(); // Re-valida al perder el foco
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (!_touched.contains('name') && !_triedSubmit) return null;
    if (value == null || value.trim().isEmpty) return 'Ingresa tu nombre';
    return null;
  }

  String? _validateEmail(String? value) {
    if (!_touched.contains('email') && !_triedSubmit) return null;
    if (value == null || value.trim().isEmpty) return 'Ingresa tu correo';
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) return 'Correo inválido';
    return null;
  }

  String? _validatePassword(String? value) {
    if (!_touched.contains('password') && !_triedSubmit) return null;
    if (value == null || value.isEmpty) return 'Crea una contraseña';
    if (value.length < 6) return 'Debe tener al menos 6 caracteres';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (!_touched.contains('confirmPassword') && !_triedSubmit) return null;
    if (value == null || value.isEmpty) return 'Confirma tu contraseña';
    if (value != _passwordController.text) return 'Las contraseñas no coinciden';
    return null;
  }

  Future<void> _onRegisterSubmit() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _triedSubmit = true;
    });

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await userCredential.user?.updateDisplayName(_nameController.text.trim());
      await userCredential.user?.sendEmailVerification();

      _formKey.currentState?.reset();
      widget.onRegisterSuccess?.call();
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EmailVerificationScreen(email: _emailController.text.trim()),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'email-already-in-use') {
          _emailError = 'Este correo ya está en uso.';
        } else if (e.code == 'invalid-email') {
          _emailError = 'El correo ingresado no es válido.';
        } else if (e.code == 'weak-password') {
          _passwordError = 'La contraseña es demasiado débil.';
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? "Ocurrió un error al registrar.")),
          );
        }
      });
    } finally {
      if(mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          const SizedBox(height: 24),
          CustomFormField(
            controller: _nameController,
            hintText: 'Nombre',
            icon: Icons.person_outline,
            focusNode: _nameFocus,
            validator: _validateName,
            onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_emailFocus),
          ),
          const SizedBox(height: 16),
          CustomFormField(
            controller: _emailController,
            hintText: 'Correo electrónico',
            icon: Icons.email_outlined,
            focusNode: _emailFocus,
            validator: _validateEmail,
            errorText: _emailError,
            onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFocus),
          ),
          const SizedBox(height: 16),
          CustomFormField(
            controller: _passwordController,
            hintText: 'Contraseña',
            icon: Icons.lock_outline,
            obscureText: !_showPassword,
            focusNode: _passwordFocus,
            validator: _validatePassword,
            errorText: _passwordError,
            suffixIcon: IconButton(
              icon: Icon(
                _showPassword ? Icons.visibility : Icons.visibility_off,
                color: AppColors.blue,
              ),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
            onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_confirmPasswordFocus),
          ),
          const SizedBox(height: 16),
          CustomFormField(
            controller: _confirmPasswordController,
            hintText: 'Confirmar contraseña',
            icon: Icons.lock_outline,
            obscureText: !_showPassword,
            focusNode: _confirmPasswordFocus,
            validator: _validateConfirmPassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _onRegisterSubmit(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: _isLoading ? null : _onRegisterSubmit,
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                    )
                  : const Text('Registrarse'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
