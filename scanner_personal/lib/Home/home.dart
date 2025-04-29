import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scanner_personal/Formulario/main.dart';
import 'package:scanner_personal/Login/data_base/database_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scanner_personal/Configuracion/mainConfig.dart';

import '../Audio/screens/AudioRecorderScreen.dart';
import '../Audio/screens/cv_generator.dart';

final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();


class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.deepPurple),
              child: Text('Menú', style: GoogleFonts.poppins(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Perfil', style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pushNamed(context, '/perfil');
              },
            ),
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Modificar datos personales', style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreenSettings()), // ✅ Lleva a settings
                );
              },
            ),

            ListTile(
              leading: Icon(Icons.lock),
              title: Text('Cambiar contraseña', style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pushNamed(context, '/change-password');
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Cerrar sesión', style: GoogleFonts.poppins()),
              onTap: () async {
                await DatabaseHelper.instance.cerrarSesion();

                if (!context.mounted) return;

                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                      (route) => false,
                );
              },
            ),
            Divider(), // Separador visual

            // 📚 Opciones adicionales de configuración:
            ListTile(
              leading: Icon(Icons.privacy_tip, color: Colors.green),
              title: Text("Privacidad"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PrivacyScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.notifications, color: Colors.green),
              title: Text("Notificaciones"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NotificationsScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.language, color: Colors.green),
              title: Text("Idioma"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LanguageScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.info, color: Colors.green),
              title: Text("Acerca de"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AcercaDeScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.info, color: Colors.green),
              title: Text("Cuenta"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AccountScreen()),
                );
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
        ),
      appBar: AppBar(
        title: Text('Bienvenido', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.indigo.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selecciona una opción',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount;
                    double width = constraints.maxWidth;

                    if (width >= 1000) {
                      crossAxisCount = 4;
                    } else if (width >= 600) {
                      crossAxisCount = 3;
                    } else {
                      crossAxisCount = 2;
                    }

                    return AnimatedSwitcher(
                      duration: Duration(milliseconds: 300),
                      child: GridView.count(
                        key: ValueKey(crossAxisCount),
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: 1,
                        children: [
                          CustomCard(
                            text: 'Escanear Documento',
                            icon: Icons.camera_alt,
                            onTap: () async {
                              final ImagePicker picker = ImagePicker();
                              final XFile? foto = await picker.pickImage(source: ImageSource.camera);

                              if (foto != null) {
                                final bytes = await foto.readAsBytes();
                                final supabase = Supabase.instance.client;
                                final nombreArchivo = 'foto_${DateTime.now().millisecondsSinceEpoch}.jpg';

                                await supabase.storage.from('cv').uploadBinary('archivos/$nombreArchivo', bytes);

                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Foto subida exitosamente')),
                                );
                              }
                            },
                          ),
                          CustomCard(
                            text: 'Grabar Audio',
                            icon: Icons.mic,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CVGenerator()),
                              );
                            },
                          ),

                          CustomCard(
                            text: 'Subir Documento',
                            icon: Icons.upload,
                            onTap: () async {
                              FilePickerResult? result = await FilePicker.platform.pickFiles(
                                type: FileType.custom,
                                allowedExtensions: ['pdf'],
                              );

                              if (result != null) {
                                final archivo = result.files.first;
                                Uint8List? archivoBytes = archivo.bytes;

                                if (archivoBytes == null && archivo.path != null) {
                                  archivoBytes = await File(archivo.path!).readAsBytes();
                                }

                                if (archivoBytes != null) {
                                  final supabase = Supabase.instance.client;
                                  final nombreArchivo = archivo.name;

                                  await supabase.storage.from('cv').uploadBinary('archivos/$nombreArchivo', archivoBytes);

                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('PDF subido exitosamente')),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('No se pudo leer el archivo')),
                                  );
                                }
                              }
                            },
                          ),

                          CustomCard(
                            text: 'Llenar Formulario',
                            icon: Icons.edit,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => PantallaSubirCV(initialAction: 'formulario')),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

class CustomCard extends StatefulWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onTap; // 👈 Agregado

  CustomCard({
    required this.text,
    required this.icon,
    this.onTap, // 👈 Agregado
  });

  @override
  _CustomCardState createState() => _CustomCardState();
}


class _CustomCardState extends State<CustomCard> with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
      lowerBound: 0.0,
      upperBound: 0.05,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(_controller);
  }

  void _onHover(bool isHovering) {
    setState(() {
      _isHovering = isHovering;
      if (isHovering) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: _isHovering ? Colors.greenAccent : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon, size: 50, color: Colors.deepPurple),
                  SizedBox(height: 10),
                  Text(
                    widget.text,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

