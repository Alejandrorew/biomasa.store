import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/email_verification_screen.dart';
import 'theme.dart'; // <--- Importa tus temas
import 'theme_mode_notifier.dart'; // <--- Importa el notifier

final themeModeNotifier = ThemeModeNotifier(); // <--- Instancia global

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting('es_ES', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: appLightTheme,
          darkTheme: appDarkTheme,
          themeMode: mode,
          home: const AuthGate(),
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          if (snapshot.data!.emailVerified) {
            // El usuario está verificado, va al HomeScreen que sí usa el tema dinámico.
            return const HomeScreen();
          } else {
            // El usuario está registrado pero no verificado.
            // La pantalla de verificación también usará un tema fijo para consistencia.
            return Theme(
              data: appLightTheme, // Se aplica el tema claro fijo.
              child: EmailVerificationScreen(email: snapshot.data!.email!),
            );
          }
        }
        
        // --- FIX START ---
        // Si el usuario no está autenticado, se muestra la pantalla de registro.
        // La envolvemos en un Widget Theme para forzar el tema claro y que no se vea
        // afectada por el modo oscuro del resto de la app.
        return Theme(
          data: appLightTheme, // Se aplica el tema claro fijo.
          child: const RegisterScreen(),
        );
        // --- FIX END ---
      },
    );
  }
}
