import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://zpprbzujtziokfyyhlfa.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpwcHJienVqdHppb2tmeXlobGZhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA3ODAyNzgsImV4cCI6MjA1NjM1NjI3OH0.cVRK3Ffrkjk7M4peHsiPPpv_cmXwpX859Ii49hohSLk',
  );

  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Configuraciones',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      scaffoldMessengerKey: scaffoldMessengerKey,
      home: const HomeScreenSettings(),
    );
  }
}

// Pantalla principal con el Drawer (Sidebar)
class HomeScreenSettings extends StatefulWidget {
  const HomeScreenSettings({super.key});
  @override
  State<HomeScreenSettings> createState() => _HomeScreenSettingsState();
}
class _HomeScreenSettingsState extends State<HomeScreenSettings> {
  String nombre = '';
  String apellido = '';
  String correo = '';

  @override
  void initState() {
    super.initState();
    cargarPerfilDePrueba();

  }
  Future<void> cargarPerfil() async {
    final perfil = await UserProfileService().getUserProfile();
    if (perfil != null) {
      setState(() {
        nombre = perfil['nombre'] ?? '';
        apellido = perfil['apellido'] ?? '';
        correo = perfil['correo'] ?? '';
      });
    }
  }
  Future<void> cargarPerfilDePrueba() async {
    const userId = '8ed84979-37f3-4bde-9bd7-487b4e33e215';
    final perfil = await UserProfileService().getUserProfileById(userId);
    if (perfil != null) {
      setState(() {
        nombre   = perfil['nombre_usuario']  ?? '';
        apellido = perfil['apellido_usuario'] ?? '';
        correo   = perfil['correo']           ?? '';
      });
    }

  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scanner")),
      key: scaffoldKey,
      drawer: AppDrawer(nombre: nombre,
        apellido: apellido,
        correo: correo,),
      body: Center(
        child: Text("Aqui la vista principal"),
      ),
    );
  }
}


class AppDrawer extends StatelessWidget {
  final String nombre;
  final String apellido;
  final String correo;
  const AppDrawer({
    Key? key,
    required this.nombre,
    required this.apellido,
    required this.correo,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text('$nombre $apellido'),
            accountEmail: Text(correo),
            currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  nombre.isNotEmpty ? nombre[0] : '',
                  style: TextStyle(fontSize: 40.0),
                )
            ),
          ),
          ListTile(
            leading: Icon(Icons.person, color: Colors.green),
            title: Text("Cuenta"),
            onTap: () {
              Navigator.push(context,MaterialPageRoute(builder: (context) => AccountScreen()),);
            },
          ),
          ListTile(
            leading: Icon(Icons.privacy_tip, color: Colors.green),
            title: Text("Privacidad"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PrivacyScreen()),
              );
            },
          ),

          ListTile(
            leading: Icon(Icons.notifications, color: Colors.green),
            title: Text("Notificaciones"),
            onTap: () {
              Navigator.push(context,MaterialPageRoute(builder: (context) => NotificationsScreen()),);
            },
          ),
          ListTile(
            leading: Icon(Icons.language, color: Colors.green),
            title: Text("Idioma"),
            onTap: () {
              Navigator.push(context,MaterialPageRoute(builder: (context) => LanguageScreen()),);
            },
          ),

          Divider(),
          ListTile(
            leading: Icon(Icons.info, color: Colors.green),
            title: Text("Acerca de"),
            onTap: () {
              Navigator.push(context,MaterialPageRoute(builder: (context) => AcercaDeScreen()),);
            },
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text("Cerrar sesión", style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context); // cerrar el drawer primero
              Future.delayed(const Duration(milliseconds: 300), () {
                final parentContext = scaffoldKey.currentContext!;
                showDialog(
                  context: parentContext,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('¿Cerrar sesión?'),
                    content: const Text('¿Estás seguro que deseas salir de la aplicación?'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          scaffoldKey.currentState?.openDrawer();
                        },
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);

                          // Mostrar SnackBar
                          scaffoldMessengerKey.currentState?.showSnackBar(
                            const SnackBar(
                              content: Text('Cerrando sesión...'),
                              duration: Duration(seconds: 2),
                            ),
                          );

                          // Cerrar app después del SnackBar
                          Future.delayed(const Duration(seconds: 2), () {
                            exit(0);
                          });
                        },
                        child: const Text('Sí, salir'),
                      ),
                    ],
                  ),
                );
              });
            },
          ),
        ],
      ),
    );
  }
}

//1.CUENTA
class AccountScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cuenta'),
      ),
      body: ListView(
        children: [
          ListTile(
              leading: Icon(Icons.person,color: Colors.green),
              title: Text("Mi Perfil"),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditProfileScreen()),
                );
                final homeScreenState = context.findAncestorStateOfType<_HomeScreenSettingsState>();
                homeScreenState?.cargarPerfilDePrueba();
              }
          ),
          ListTile(
            leading: Icon(Icons.email, color: Colors.green),
            title: Text("Cambiar correo"),
            onTap: () {
              Navigator.push(context,MaterialPageRoute(
                builder: (context) => ChangeCredentialScreen(tipo: 'CORREO'),),);
            },
          ),
          ListTile(
            leading: Icon(Icons.lock, color: Colors.green),
            title: Text("Cambiar contraseña"),
            onTap: () {
              Navigator.push(context,MaterialPageRoute(
                builder: (context) => ChangeCredentialScreen(tipo: 'CONTRASEÑA'),),);
            },
          ),
        ],
      ),
    );
  }
}

// 1.1 Pantalla de edición de perfil
class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final nameController = TextEditingController();
  final lastNameController = TextEditingController();
  File? _image;
  String nombre = '';
  String apellido = '';
  String correo = '';

  @override
  void initState() {
    super.initState();
    loadUserProfile();
    nameController.text = "Nombre";
    lastNameController.text = "Apellido";
  }
  // Función para actualizar el perfil
  Future<void> loadUserProfile() async {
    final service = UserProfileService();
    //final profile = await service.getUserProfile();
    final profile = await service.getUserProfileById('8ed84979-37f3-4bde-9bd7-487b4e33e215');
    if (profile != null) {
      setState(() {
        nameController.text = profile['nombre_usuario'] ?? '';
        lastNameController.text = profile['apellido_usuario'] ?? '';
      });
    }

  }
  Future<void> guardarCambios() async {
    final supabase = Supabase.instance.client;
    final userId = '8ed84979-37f3-4bde-9bd7-487b4e33e215';

    final response = await supabase
        .from('usuarios')
        .update({
      'nombre_usuario': nameController.text.trim(),
      'apellido_usuario': lastNameController.text.trim(),
    })
        .eq('id', userId)
        .select();

    if (response.isEmpty) {
      print('Error al actualizar perfil.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar perfil')),
      );
    } else {
      print('Perfil actualizado correctamente.');

      // Mostrar el nombre actualizado y la foto en la Snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: _image != null
                    ? FileImage(_image!)
                    : AssetImage("assets/default_avatar.png") as ImageProvider,
              ),
              SizedBox(width: 12),
              Text('Perfil actualizado: ${nameController.text.trim()}'),
            ],
          ),
          duration: Duration(seconds: 3),
        ),
      );

      setState(() {}); // Refrescar la pantalla si quieres mostrar el cambio
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
    }
  }
  void _removeImage() {
    setState(() {
      _image = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Editar Perfil")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _image != null
                    ? FileImage(_image!)
                    : AssetImage("assets/default_avatar.png") as ImageProvider,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Icon(Icons.camera_alt, color: const Color.fromARGB(255, 103, 35, 118)),
                ),
              ),
            ),
            // Botón para eliminar la imagen
            if (_image != null)
              TextButton(
                onPressed: _removeImage,
                child: Text("Eliminar foto", style: TextStyle(color: Colors.red)),
              ),
            SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: "Nombre"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: lastNameController,
              decoration: InputDecoration(labelText: "Apellido"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: guardarCambios,
              child: Text('Guardar Cambios'),
            ),
          ],
        ),
      ),
    );
  }
}
//Supabase
class UserProfileService {
  final supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      return null;
    }

    final response = await supabase
        .from('usuarios')
        .select('nombre_usuario, apellido_usuario, correo')
        .eq('id', user.id)
        .single();

    return response;
  }
  //Ensayo mientras que se integra login
  Future<Map<String, dynamic>?> getUserProfileById(String id) async {
    final response = await supabase
        .from('usuarios')
        .select('nombre_usuario, apellido_usuario, correo')
        .eq('id', id)
        .single();
    return response;
  }
  // Función para actualizar nombre y apellido
  Future<void> updateUserProfile(String nombre, String apellido) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      print('No hay usuario logueado');
      return;
    }

    final response = await supabase.from('usuarios').upsert({
      'id': user.id,
      'nombre_usuario': nombre,
      'apellido_usuario': apellido,
    })..eq('id', user.id)
        .execute();
    if (response.status >= 400) {
      print('Error al actualizar perfil: ${response.data}');
    } else {
      print('Perfil actualizado correctamente.');
    }
  }

}

//1.2 Cambiar contraseña/correo
class ChangeCredentialScreen extends StatelessWidget {
  final String tipo;

  const ChangeCredentialScreen({super.key, required this.tipo});

  @override
  Widget build(BuildContext context) {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: Text('CAMBIAR $tipo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: currentController,
              obscureText: tipo == 'CONTRASEÑA',
              decoration: InputDecoration(
                labelText: '$tipo ACTUAL',
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: newController,
              obscureText: tipo == 'CONTRASEÑA',
              decoration: InputDecoration(
                labelText: 'NUEVO $tipo',
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: confirmController,
              obscureText: tipo == 'CONTRASEÑA',
              decoration: InputDecoration(
                labelText: 'CONFIRMAR $tipo',
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                if (newController.text == confirmController.text &&
                    newController.text.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$tipo CAMBIADO CON ÉXITO.')),
                  );
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('EL $tipo NO COINCIDE.')),
                  );
                }
              },
              child: Text('GUARDAR'),
            )
          ],
        ),
      ),
    );
  }
}

//2. PRIVACIDAD

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Privacidad')),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.privacy_tip, color: Colors.green),
            title: Text('Política de privacidad'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Política de privacidad')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Text(
                'Este es un texto ficticio de política de privacidad. Aquí iría la información legal sobre el uso de los datos del usuario...',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Center(
              child: ElevatedButton.icon(
                icon: Icon(Icons.report),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Reporte enviado')),
                  );
                },
                label: Text('Reportar'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//3. NOTIFICACIONES
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool notificationsEnabled = true;
  bool sms = false;
  bool email = true;
  bool whatsapp = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Permitir notificaciones
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Permitir notificaciones',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Switch(
                value: notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    notificationsEnabled = value;

                    if (value) {
                      // Si se activan notificaciones, se activa Email
                      email = true;
                    } else {
                      // Si se desactivan notificaciones, se apagan todas las preferencias
                      sms = false;
                      email = false;
                      whatsapp = false;
                    }
                  });
                },
                activeColor: Colors.green,
                inactiveThumbColor: Colors.grey,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Sección Preferencias
          const Text('Preferencias',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Divider(),
          SwitchListTile(
            title: const Text('SMS'),
            value: sms,
            activeColor: Colors.green,
            inactiveThumbColor: Colors.grey,
            onChanged: notificationsEnabled
                ? (value) => setState(() => sms = value)
                : null, // Desactiva el switch si notificaciones están apagadas
          ),
          SwitchListTile(
            title: const Text('Email'),
            value: email,
            activeColor: Colors.green,
            inactiveThumbColor: Colors.grey,
            onChanged: notificationsEnabled
                ? (value) => setState(() => email = value)
                : null,
          ),
          SwitchListTile(
            title: const Text('WhatsApp'),
            value: whatsapp,
            activeColor: Colors.green,
            inactiveThumbColor: Colors.grey,
            onChanged: notificationsEnabled
                ? (value) => setState(() => whatsapp = value)
                : null,
          ),
          const SizedBox(height: 24),

          // Sección Actualizaciones
          const Text('Actualizaciones', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Divider(),
          const Text('Scanner ya está actualizada'),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                // Acción de reporte
              },
              icon: Icon(Icons.report,color: const Color.fromARGB(255, 103, 35, 118), size: 20),
              label: Text(
                'Reportar',
                style: TextStyle(color: Colors.grey[700]),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//4.IDIOMA
class LanguageScreen extends StatefulWidget {
  @override
  _LanguageScreenState createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  final List<String> languages = [
    'Alemán',
    'Español',
    'Francés',
    'Inglés',
    'Portugués'
  ];
  List<String> filteredLanguages = [];

  @override
  void initState() {
    super.initState();
    filteredLanguages = List.from(languages)..sort();
  }

  void filterLanguages(String query) {
    setState(() {
      filteredLanguages = languages
          .where((lang) =>
          lang.toLowerCase().contains(query.toLowerCase()))
          .toList()
        ..sort();
    });
  }

  void changeLanguage(String lang) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_getChangingText(lang))),
    );
  }

  String _getChangingText(String lang) {
    switch (lang) {
      case 'Español':
        return 'Cambiando idioma...';
      case 'Inglés':
        return 'Changing language...';
      case 'Francés':
        return 'Changement de langue...';
      case 'Portugués':
        return 'Mudando idioma...';
      case 'Alemán':
        return 'Sprache ändern...';
      default:
        return 'Cambiando idioma...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Idioma')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              onChanged: filterLanguages,
              decoration: InputDecoration(
                hintText: 'Buscar idioma...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredLanguages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Icon(Icons.language),
                  title: Text(filteredLanguages[index]),
                  onTap: () => changeLanguage(filteredLanguages[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

//5.Acerca de
class AcercaDeScreen extends StatelessWidget {
  const AcercaDeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Acerca de')),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.help, color: Colors.green),
            title: Text('Ayuda'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ayuda')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Image.network(
              'https://upload.wikimedia.org/wikipedia/commons/thumb/8/80/QR_code_for_mobile_English_Wikipedia.svg/1920px-QR_code_for_mobile_English_Wikipedia.svg.png',
              height: 200,
            ),
            SizedBox(height: 20),
            Text(
              'Escanea el código QR para acceder a ayuda personalizada.',
              textAlign: TextAlign.center,
            )
          ],
        ),
      ),
    );
  }
}

//Cerrar sesion
class LogoutScreen extends StatelessWidget {
  const LogoutScreen({super.key});

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('¿Cerrar sesión?'),
        content: Text('¿Estás seguro que deseas salir de la aplicación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              exit(0); // cierra completamente la app pero en emulador
            },
            child: Text('Sí, salir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cerrar sesión')),
      body: Center(
        child: ElevatedButton.icon(
          icon: Icon(Icons.logout),
          label: Text('Cerrar sesión'),
          onPressed: () => _confirmLogout(context),
        ),
      ),
    );
  }
}