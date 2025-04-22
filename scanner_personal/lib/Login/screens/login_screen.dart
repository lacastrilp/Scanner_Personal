import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data_base/database_helper.dart';
import 'package:scanner_personal/Home/home.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? emailError;
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
    final correo = emailController.text.trim();
    final password = passwordController.text.trim();

    setState(() {
      emailError = validarCorreo(correo) ? null : 'Correo no válido';
      passwordError = validarPassword(password)
          ? null
          : 'Mínimo 8 caracteres, 1 mayúscula y 1 símbolo';
      isFormValid = emailError == null && passwordError == null;
    });
  }

  Future<void> _iniciarSesion() async {
    validarFormulario(); // Aseguramos que esté validado antes de enviar
    if (!isFormValid) return;

    final correo = emailController.text.trim();
    final password = passwordController.text.trim();

    final success =
    await DatabaseHelper.instance.iniciarSesion(correo, password);

    if (!mounted) return;

    if (success) {
      await DatabaseHelper.instance.guardarSesion(correo);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Credenciales incorrectas')),
      );
    }
  }

  void _recuperarPassword() {
    final TextEditingController correoRecuperacion = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
            title: const Text('Recuperar contraseña'),
            content: TextField(
              controller: correoRecuperacion,
              decoration: const InputDecoration(
                labelText: 'Correo',
              ),
            ),
            actions: [
            TextButton(
            onPressed: ()
        =>
            Navigator.pop(context)
        ,
        child: const Text('Cancelar'),
        ),
        ElevatedButton(
        onPressed: () async {
          final email = correoRecuperacion.text.trim();

          try {
            await Supabase.instance.client.auth.resetPasswordForEmail(email);

            Navigator.pop(context);

            ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Revisa tu correo para continuar con el cambio de contraseña')),
            );
          } catch (e) {
            Navigator.pop(context);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Algo salió mal al enviar el correo: $e')),
            );
          }
        },

        child: const Text('Enviar')
        ,
        )
        ,
        ]
        ,
        );
      },
    );
  }


  @override
  void initState() {
    super.initState();
    emailController.addListener(validarFormulario);
    passwordController.addListener(validarFormulario);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inicio de Sesión')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: emailController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Email',
                  errorText: emailError,
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              TextFormField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  errorText: passwordError,
                ),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isFormValid ? _iniciarSesion : null,
                child: const Text('Iniciar Sesión'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/registro');
                },
                child: const Text(
                  'Crear cuenta',
                  style: TextStyle(fontSize: 16, color: Colors.blue),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _recuperarPassword,
                child: const Text(
                  'Olvidé mi contraseña',
                  style: TextStyle(fontSize: 16, color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
