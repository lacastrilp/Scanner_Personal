import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scanner_personal/Login/screens/login_screen.dart';
import 'package:scanner_personal/Login/screens/registro_screen.dart';
import 'package:scanner_personal/Login/screens/welcome_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


// Inicializar Supabase (hazlo en el mainFormulario.dart)
Future<void> main() async {

  await dotenv.load();

  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://zpprbzujtziokfyyhlfa.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpwcHJienVqdHppb2tmeXlobGZhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA3ODAyNzgsImV4cCI6MjA1NjM1NjI3OH0.cVRK3Ffrkjk7M4peHsiPPpv_cmXwpX859Ii49hohSLk',
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/registro': (context) => RegistroScreen(),
        '/welcome': (context) => WelcomeScreen(),
      },
    );
  }
}



