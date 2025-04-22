import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scanner_personal/Home/home.dart';
import 'package:scanner_personal/Login/screens/login_screen.dart';
import 'package:scanner_personal/Login/screens/change_password_screen.dart';
import 'package:scanner_personal/Login/screens/splash_screen.dart';

class AuthRouter extends StatefulWidget {
  const AuthRouter({super.key});

  @override
  State<AuthRouter> createState() => _AuthRouterState();
}

class _AuthRouterState extends State<AuthRouter> {
  bool isLoading = true;
  Widget? screenToShow;

  @override
  void initState() {
    super.initState();
    _initAuthFlow();
  }

  Future<void> _initAuthFlow() async {
    final uri = Uri.base;

    // 1. Procesar token si vino desde el email
    if (uri.fragment.contains('access_token')) {
      await Supabase.instance.client.auth.getSessionFromUrl(uri);
    }

    // 2. Esperar un segundo para dar tiempo a que Supabase dispare el evento
    await Future.delayed(const Duration(seconds: 1));

    final session = Supabase.instance.client.auth.currentSession;

    // 3. Verificamos si el evento es recovery
    final recoveryDetected = Supabase.instance.client.auth.currentUser?.email != null &&
        uri.fragment.contains('type=recovery');

    // 4. Decidir a dónde vamos
    setState(() {
      if (recoveryDetected && session != null) {
        screenToShow = CambiarPasswordScreen();
      } else if (session != null) {
        screenToShow = HomeScreen();
      } else {
        screenToShow = const LoginScreen();
      }

      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return isLoading ? const SplashScreen() : screenToShow!;
  }
}
