import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'package:scanner_personal/Home/home.dart';

class RegistroScreen extends StatefulWidget {
  @override
  _RegistroScreenState createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _supabase = Supabase.instance.client;

  final TextEditingController nombreController = TextEditingController();
  final TextEditingController apellidoController = TextEditingController();
  final TextEditingController correoController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? nombreError;
  String? apellidoError;
  String? correoError;
  String? passwordError;

  bool isFormValid = false;

  bool validarCorreo(String correo) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(correo);
  }

  bool validarPassword(String password) {
    final lengthValid = password.length >= 8;
    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    return lengthValid && hasUpper && hasSpecial;
  }

  void validarFormulario() {
    final correo = correoController.text.trim();
    final password = passwordController.text.trim();
    final nombre = nombreController.text.trim();
    final apellido = apellidoController.text.trim();

    setState(() {
      nombreError = nombre.isEmpty ? 'Nombre requerido' : null;
      apellidoError = apellido.isEmpty ? 'Apellido requerido' : null;
      correoError = validarCorreo(correo) ? null : 'Correo no válido';
      passwordError = validarPassword(password)
          ? null
          : 'Mínimo 8 caracteres, 1 mayúscula y 1 símbolo';
      isFormValid = nombreError == null &&
          apellidoError == null &&
          correoError == null &&
          passwordError == null;
    });
  }

  Future<void> registrarUsuario() async {
    validarFormulario(); // Asegurarnos que los errores estén actualizados
    if (!isFormValid) return;

    final correo = correoController.text.trim();
    final password = passwordController.text.trim();
    final nombre = nombreController.text.trim();
    final apellido = apellidoController.text.trim();

    try {
      // Verificamos si el correo ya existe en la tabla usuarios
      final existingUser = await _supabase
          .from('usuarios')
          .select()
          .eq('correo', correo)
          .maybeSingle();

      if (existingUser != null) {
        setState(() {
          correoError = 'El correo ya se encuentra registrado';
        });
        return;
      }

      final response =
      await _supabase.auth.signUp(email: correo, password: password);

      if (response.user != null) {
        final userId = response.user!.id;

        await _supabase.from('usuarios').insert({
          'id': userId,
          'nombre_usuario': nombre,
          'apellido_usuario': apellido,
          'correo': correo,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Usuario registrado correctamente')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar usuario')),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    // Validación en tiempo real
    nombreController.addListener(validarFormulario);
    apellidoController.addListener(validarFormulario);
    correoController.addListener(validarFormulario);
    passwordController.addListener(validarFormulario);
  }

  @override
  void dispose() {
    nombreController.dispose();
    apellidoController.dispose();
    correoController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Registro de Usuario")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nombreController,
              decoration: InputDecoration(
                labelText: "Nombre",
                errorText: nombreError,
              ),
            ),
            TextField(
              controller: apellidoController,
              decoration: InputDecoration(
                labelText: "Apellido",
                errorText: apellidoError,
              ),
            ),
            TextField(
              controller: correoController,
              decoration: InputDecoration(
                labelText: "Correo Electrónico",
                errorText: correoError,
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: "Contraseña",
                errorText: passwordError,
              ),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isFormValid ? registrarUsuario : null,
              child: Text("Registrar"),
            ),
          ],
        ),
      ),
    );
  }
}
