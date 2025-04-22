import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CambiarPasswordScreen extends StatefulWidget {
  @override
  _CambiarPasswordScreenState createState() => _CambiarPasswordScreenState();
}

class _CambiarPasswordScreenState extends State<CambiarPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool isValidPassword = false;
  bool passwordsMatch = true;
  String passwordStrength = '';

  @override
  void initState() {
    super.initState();
    passwordController.addListener(_validatePassword);
    confirmPasswordController.addListener(_checkPasswordsMatch);
  }

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _validatePassword() {
    final password = passwordController.text.trim();

    setState(() {
      passwordsMatch = password == confirmPasswordController.text.trim();

      isValidPassword = RegExp(
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~.,;:<>?])[A-Za-z\d!@#\$&*~.,;:<>?]{8,}$',
      ).hasMatch(password);

      passwordStrength = _calcularFuerza(password);
    });
  }

  void _checkPasswordsMatch() {
    setState(() {
      passwordsMatch = passwordController.text.trim() ==
          confirmPasswordController.text.trim();
    });
  }

  String _calcularFuerza(String password) {
    if (password.length < 8) return 'Débil';
    final hasLetters = RegExp(r'[A-Za-z]').hasMatch(password);
    final hasNumbers = RegExp(r'\d').hasMatch(password);
    final hasSpecial = RegExp(r'[!@#\$&*~.,;:<>?]').hasMatch(password);
    final hasUpper = RegExp(r'[A-Z]').hasMatch(password);

    if (hasLetters && hasNumbers && hasSpecial && hasUpper) return 'Fuerte';
    if (hasLetters && hasNumbers) return 'Media';
    return 'Débil';
  }

  Color _colorPorFuerza(String fuerza) {
    switch (fuerza) {
      case 'Fuerte':
        return Colors.green;
      case 'Media':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  Future<void> _submit() async {
    if (!isValidPassword || !passwordsMatch) return;

    final password = passwordController.text.trim();

    try {
      final result = await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );

      if (result.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contraseña actualizada con éxito')),
        );
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        throw Exception("No se pudo actualizar la contraseña");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar contraseña: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva contraseña')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                'Crea una nueva contraseña segura:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Nueva contraseña',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        isPasswordVisible = !isPasswordVisible;
                      });
                    },
                  ),
                  helperText:
                  'Debe tener al menos 8 caracteres, incluir mayúsculas, minúsculas, números y símbolos.',
                  errorText: isValidPassword || passwordController.text.isEmpty
                      ? null
                      : 'Contraseña no válida',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Fortaleza: ',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    passwordStrength,
                    style: TextStyle(color: _colorPorFuerza(passwordStrength)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: !isConfirmPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Confirmar contraseña',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isConfirmPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        isConfirmPasswordVisible = !isConfirmPasswordVisible;
                      });
                    },
                  ),
                  errorText: passwordsMatch
                      ? null
                      : 'Las contraseñas no coinciden',
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: isValidPassword && passwordsMatch ? _submit : null,
                child: const Text('Actualizar contraseña'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
