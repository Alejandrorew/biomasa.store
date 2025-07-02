import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart'; // Importa el paquete lottie
import 'dart:math'; // Importado para las animaciones del fondo

// Asumiendo que estos imports son para tus otras pantallas
import 'home_screen.dart';
import 'register_screen.dart';


// --- OPTIMIZACIÓN DE CÓDIGO: MODULARIZACIÓN (RECOMENDACIÓN) ---
// Para una mejor organización y reutilización, todas las clases del fondo
// (OceanBackground, WavesPainter, BubblesPainter) deberían moverse a su
// propio archivo, por ejemplo: 'widgets/ocean_background.dart'.
// Luego, simplemente importarías ese archivo aquí.

/// Define las propiedades de una sola burbuja.
class Bubble {
  final double x;
  final double y;
  final double radius;
  final double opacity;

  Bubble({required this.x, required this.y, required this.radius, required this.opacity});
}

/// El widget principal que construye el fondo del océano.
class OceanBackground extends StatefulWidget {
  const OceanBackground({super.key});

  @override
  State<OceanBackground> createState() => _OceanBackgroundState();
}

class _OceanBackgroundState extends State<OceanBackground> {
  final List<Bubble> bubbles = [];

  @override
  void initState() {
    super.initState();
    _generateBubbles();
  }

  void _generateBubbles() {
    final Random random = Random();
    for (int i = 0; i < 15; i++) {
      bubbles.add(
        Bubble(
          x: random.nextDouble(),
          y: random.nextDouble(),
          radius: random.nextDouble() * 4 + 2,
          opacity: random.nextDouble() * 0.2 + 0.1,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- OPTIMIZACIÓN DE RENDIMIENTO ---
    // RepaintBoundary crea una capa de renderizado separada para el fondo.
    // Esto es eficiente porque el fondo es estático y no necesita redibujarse
    // cuando otros widgets (como temporizadores) se actualizan.
    return RepaintBoundary(
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF4AA9D3),
                  Color(0xFF1E6A9A),
                ],
              ),
            ),
          ),
          CustomPaint(
            size: Size.infinite,
            painter: WavesPainter(),
          ),
          CustomPaint(
            size: Size.infinite,
            painter: BubblesPainter(bubbles: bubbles),
          ),
        ],
      ),
    );
  }
}

/// Un pintor personalizado que se encarga de dibujar las capas de las olas.
class WavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    _drawWave(
      canvas,
      size,
      color: const Color(0xFF3B89B4).withOpacity(0.5),
      yOffset: size.height * 0.75,
      xOffset: 20,
      curveHeight: 25,
    );
    _drawWave(
      canvas,
      size,
      color: const Color(0xFF1E6A9A).withOpacity(0.6),
      yOffset: size.height * 0.8,
      xOffset: -40,
      curveHeight: 35,
    );
    _drawWave(
      canvas,
      size,
      color: const Color(0xFF0F4C75).withOpacity(0.8),
      yOffset: size.height * 0.9,
      xOffset: 0,
      curveHeight: 30,
    );
  }

  void _drawWave(Canvas canvas, Size size,
      {required Color color, required double yOffset, double xOffset = 0, double curveHeight = 20}) {
    final paint = Paint()..color = color;
    final path = Path();
    path.moveTo(-50 + xOffset, yOffset);
    path.quadraticBezierTo(
        size.width * 0.25 + xOffset, yOffset - curveHeight,
        size.width * 0.5 + xOffset, yOffset);
    path.quadraticBezierTo(
        size.width * 0.75 + xOffset, yOffset + curveHeight,
        size.width + 50 + xOffset, yOffset - 10);
    path.lineTo(size.width + 50, size.height);
    path.lineTo(-50, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Un pintor personalizado que se encarga de dibujar las burbujas.
class BubblesPainter extends CustomPainter {
  final List<Bubble> bubbles;

  BubblesPainter({required this.bubbles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final bubble in bubbles) {
      paint.color = Colors.white.withOpacity(bubble.opacity);
      canvas.drawCircle(
        Offset(bubble.x * size.width, bubble.y * size.height),
        bubble.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- Tu Pantalla de Verificación de Email ---

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  const EmailVerificationScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> with TickerProviderStateMixin {
  // --- OPTIMIZACIÓN DE ESTADO ---
  // Se usan ValueNotifiers para evitar reconstruir toda la pantalla con setState.
  // Solo los widgets envueltos en un ValueListenableBuilder se actualizarán.
  final ValueNotifier<bool> _isLoading = ValueNotifier(false);
  final ValueNotifier<bool> _canResend = ValueNotifier(true);
  final ValueNotifier<int> _resendSeconds = ValueNotifier(0);

  Timer? _autoCheckTimer;
  Timer? _resendTimer;
  static const int resendCooldown = 30;

  @override
  void initState() {
    super.initState();
    _startAutoCheckTimer();
  }

  void _startAutoCheckTimer() {
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await FirebaseAuth.instance.currentUser?.reload();
      final isVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
      if (isVerified && mounted) {
        timer.cancel();
        _navigateIfVerified();
      }
    });
  }

  void _navigateIfVerified() {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(
          successMessage: "¡Cuenta creada exitosamente!",
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
      (route) => false,
    );
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResend.value) return;

    // Actualiza el estado sin llamar a setState
    _canResend.value = false;
    _resendSeconds.value = resendCooldown;

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds.value > 1) {
        _resendSeconds.value--; // Simplemente decrementa el valor
      } else {
        timer.cancel();
        _canResend.value = true; // Habilita el botón de nuevo
      }
    });

    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      _showSnackBar("Correo de verificación reenviado.");
    } catch (_) {
      _showSnackBar("Error al reenviar correo.", isError: true);
    }
  }
  
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.white,
        elevation: 6.0,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        margin: const EdgeInsets.all(20),
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? Colors.red.shade400 : const Color(0xFF005F99),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _autoCheckTimer?.cancel();
    _resendTimer?.cancel();
    // Es buena práctica liberar los recursos de los notifiers.
    _isLoading.dispose();
    _canResend.dispose();
    _resendSeconds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double animationHeight = 200.0;
    const Color accentColor = Color(0xFF005F99);

    return Scaffold(
      body: Stack(
        children: [
          const OceanBackground(),
          SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topCenter,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: animationHeight / 2),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24.0),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 384),
                              padding: const EdgeInsets.all(32.0),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(24.0),
                                border: Border.all(color: Colors.white.withOpacity(0.2)),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: animationHeight / 2),
                                  const Text(
                                    "¡Revisa tu correo!",
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1F2937),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF4B5563),
                                        height: 1.5,
                                      ),
                                      children: [
                                        const TextSpan(
                                          text: "Te enviamos un enlace de verificación a\n",
                                        ),
                                        TextSpan(
                                          text: widget.email,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF374151),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "Haz clic en el enlace para activar tu cuenta.",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF6B7280),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ValueListenableBuilder<bool>(
                                      valueListenable: _isLoading,
                                      builder: (context, isLoading, child) {
                                        return ElevatedButton(
                                          onPressed: isLoading
                                              ? null
                                              : () async {
                                                  _isLoading.value = true;
                                                  await FirebaseAuth.instance.currentUser?.reload();
                                                  final isVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
                                                  if(mounted) _isLoading.value = false;
                                                  if (isVerified) {
                                                    _navigateIfVerified();
                                                  } else {
                                                    _showSnackBar("Tu correo aún no está verificado.", isError: true);
                                                  }
                                                },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: accentColor,
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            elevation: 5,
                                          ),
                                          child: isLoading
                                              ? const SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child: CircularProgressIndicator(
                                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                    strokeWidth: 3.0,
                                                  ),
                                                )
                                              : const Text(
                                                  "Ya verifiqué mi cuenta",
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  ValueListenableBuilder<bool>(
                                    valueListenable: _canResend,
                                    builder: (context, canResend, child) {
                                      return TextButton(
                                        onPressed: canResend ? _resendVerificationEmail : null,
                                        child: ValueListenableBuilder<int>(
                                          valueListenable: _resendSeconds,
                                          builder: (context, seconds, child) {
                                            return Text(
                                              canResend
                                                  ? "¿No recibiste el enlace? Reenviar."
                                                  : "Reenviar en ${seconds}s",
                                              style: TextStyle(
                                                color: canResend ? accentColor : Colors.grey,
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      _autoCheckTimer?.cancel();
                                      Navigator.of(context).pushAndRemoveUntil(
                                        MaterialPageRoute(
                                          builder: (context) => const RegisterScreen(),
                                        ),
                                        (route) => false,
                                      );
                                    },
                                    child: const Text(
                                      "Cambiar dirección de email",
                                      style: TextStyle(color: Color(0xFF6B7280)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 70,
                        child: SizedBox(
                          width: animationHeight,
                          height: animationHeight,
                          child: Lottie.asset(
                            'assets/animacionbotella.json',
                            repeat: true,
                          ),
                        ),
                      ),
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
}