import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:logger/logger.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  final Logger _logger = Logger();

  DatabaseHelper._init();

  Future<Map<String, String>?> obtenerUsuarioPorEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final storedEmail = prefs.getString('email') ?? '';
    if (storedEmail == email) {
      final nombre = prefs.getString('nombre') ?? '';
      final password = prefs.getString('password') ?? '';
      return {
        'nombre': nombre,
        'email': storedEmail,
        'password': password,
      };
    }
    return null;
  }

  Future<Map<String, String>?> autenticarUsuario(String email, String password) async {
    final usuario = await obtenerUsuarioPorEmail(email);
    if (usuario != null && usuario['password'] == password) {
      return usuario;
    }
    return null;
  }

  Future<Map<String, dynamic>?> obtenerUsuario(String email) async {
    final supabase = Supabase.instance.client;
    final response = await supabase.from('usuarios').select().eq('email', email).single();
    return response;
  }

  /// **Registrar usuario usando Supabase Auth**
  Future<bool> registrarUsuario(String nombre, String apellido, String correo, String password) async {
    final supabase = Supabase.instance.client;

    try {
      final response = await supabase.auth.signUp(
        email: correo,
        password: password,
        data: {
          'nombre': nombre,
          'apellido': apellido,
        },
      );

      if (response.user != null) {
        _logger.i("Usuario registrado exitosamente: ${response.user!.email}");
        return true;
      } else {
        _logger.w("Registro fallido.");
        return false;
      }
    } catch (e) {
      _logger.e("Error en registro: $e");
      return false;
    }
  }

  /// **Iniciar sesión con Supabase Auth**
  Future<bool> iniciarSesion(String correo, String password) async {
    final supabase = Supabase.instance.client;

    try {
      final authResponse = await supabase.auth.signInWithPassword(
        email: correo,
        password: password,
      );

      if (authResponse.session != null) {
        _logger.i("Usuario autenticado: ${authResponse.user!.email}");
        return true;
      } else {
        _logger.w("Credenciales incorrectas.");
        return false;
      }
    } catch (e) {
      _logger.e("Error en Supabase Auth: $e");
      return false;
    }
  }

  /// **Guardar sesión en SharedPreferences**
  Future<void> guardarSesion(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('usuario_actual', email);
  }

  /// **Cerrar sesión**
  Future<void> cerrarSesion() async {
    final supabase = Supabase.instance.client;

    try {
      // 🔐 Cierra sesión en Supabase
      await supabase.auth.signOut();

      // 🧹 Limpia SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // 👈 Limpia TODO por si acaso

      _logger.i("Sesión cerrada y preferencias eliminadas.");
    } catch (e) {
      _logger.e("Error al cerrar sesión: $e");
    }
  }


  /// **Obtener usuario autenticado**
  Future<Map<String, dynamic>?> obtenerUsuarioActual() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user != null) {
      return {
        'id': user.id,
        'email': user.email,
        'nombre': user.userMetadata?['nombre'] ?? '',
        'apellido': user.userMetadata?['apellido'] ?? '',
      };
    }
    return null;
  }
}
