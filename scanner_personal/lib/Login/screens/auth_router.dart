import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scanner_personal/Login/screens/splash_screen.dart';

class AuthRouter extends StatefulWidget {
  const AuthRouter({super.key});

  @override
  State<AuthRouter> createState() => _AuthRouterState();
}

class _AuthRouterState extends State<AuthRouter> {
  @override
  void initState() {
    super.initState();
    _handleRouting();
  }

  Future<void> _handleRouting() async {
    final uri = Uri.base;
    final path = uri.path;
    final type = uri.queryParameters['type'];
    final accessToken = uri.queryParameters['access_token'];

    final client = Supabase.instance.client;
    final session = client.auth.currentSession;

    debugPrint('🔗 URI: $uri');
    debugPrint('📂 path: $path');
    debugPrint('📩 type: $type');
    debugPrint('🔑 access_token: $accessToken');
    debugPrint('👤 Sesión actual: ${session?.user.email}');

    try {
      if (type == 'recovery' && accessToken != null) {
        // 🛠 Recuperar sesión
        await client.auth.recoverSession(accessToken);

        Future.microtask(() {
          Navigator.pushReplacementNamed(context, '/change-password');

        });
      } else if (session != null) {
        Future.microtask(() {
          Navigator.pushReplacementNamed(context, '/home');
        });
      } else {
        Future.microtask(() {
          Navigator.pushReplacementNamed(context, '/login');
        });
      }
    } catch (e, s) {
      debugPrint('❌ Error en AuthRouter: $e');
      debugPrint('$s');
      Future.microtask(() {
        Navigator.pushReplacementNamed(context, '/login');
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return const SplashScreen(); // mientras decide
  }
}
