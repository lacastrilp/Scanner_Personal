import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() {
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
      home: const HomeScreen(),
    );
  }
}

// Pantalla principal con el Drawer (Sidebar)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scanner")),
      drawer: AppDrawer(), 
      body: Center(
        child: Text("Aqui la vista principal"),
      ),
    );
  }
}


class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text("Aleja Suarez(logica para que cuando inicie sesion este campo se llene automaticamente)"),
            accountEmail: Text("correo@tales (aqui lo mismo del nombre)"),
            currentAccountPicture: CircleAvatar(
              backgroundImage: AssetImage("assets/default_avatar.png"),
            ),
          ),
          ListTile(
            leading: Icon(Icons.person, color: Colors.green),
            title: Text("Mi Perfil"),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfileScreen()));
            },
          ),
          ListTile(
            leading: Icon(Icons.settings, color: Colors.green),
            title: Text("Ajustes"),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.lock, color: Colors.green),
            title: Text("Privacidad"),
            onTap: () {},
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.info, color: Colors.green),
            title: Text("Acerca de"),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.exit_to_app, color: Colors.red),
            title: Text("Cerrar sesión", style: TextStyle(color: Colors.red)),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

// Pantalla de edición de perfil
class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  TextEditingController nameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  File? _image;

  @override
  void initState() {
    super.initState();
    nameController.text = "Nombre(traer de inicio el nombre, pero que se pueda editar y actualizar en la bd)";
    lastNameController.text = "Apellido(que otros campos de info personal queremos agregar aqui?)";
  }
  //Acceder a la imagen
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
              onPressed: () {
                print("Nombre: ${nameController.text}, Apellido: ${lastNameController.text}");
                Navigator.pop(context);
              },
              child: Text("Guardar Cambios"),
            ),
          ],
        ),
      ),
    );
  }
}
