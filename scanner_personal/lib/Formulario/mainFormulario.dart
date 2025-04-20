import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize( //
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
      title: 'Analizador de Hojas de Vida',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: PantallaSubirCV(),
    );
  }
}

class PantallaSubirCV extends StatefulWidget {
  @override
  PantallaSubirCVState createState() => PantallaSubirCVState();
}

class PantallaSubirCVState extends State<PantallaSubirCV> {
  String? filePath;
  Map<String, String> datosCV = {
    'Nombre': 'Pedro',
    'Apellido': 'Pérez',
    'Teléfono': '23902945',
    'Email': 'pedro_123@gmail.com',
    'Experiencia': '6 años en desarrollo de videojuegos',
    'Educación': 'Ingeniería en Sistemas - Universidad Eafit',
    'Habilidades': 'Liderazgo, comunicación',
  };

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        filePath = result.files.single.name;
      });
    }
  }

  void analizarCV() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PantallaAnalizarCV(extractedData: datosCV),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'Análisis de Hojas de Vida',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 4,
        shadowColor: Colors.black54,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.upload_file, size: 100, color: Colors.blue),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: pickFile,
                icon: Icon(Icons.folder_open),
                label: Text('Seleccionar archivo'),
              ),
              SizedBox(height: 20),
              if (filePath != null)
                Text(
                  'Archivo seleccionado: $filePath',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: filePath != null ? analizarCV : null,
                child: Text('Analizar hoja de vida'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PantallaAnalizarCV extends StatefulWidget {
  final Map<String, String> extractedData;

  PantallaAnalizarCV({required this.extractedData});

  @override
  PantallaAnalizarCVState createState() => PantallaAnalizarCVState();
}

class PantallaAnalizarCVState extends State<PantallaAnalizarCV> {
  late Map<String, TextEditingController> controllers;

  @override
  void initState() {
    super.initState();
    controllers = widget.extractedData.map(
      (key, value) => MapEntry(key, TextEditingController(text: value)),
    );
  }

  Future<void> guardarEnSupabase() async {
    final supabase = Supabase.instance.client;

    try {
      await supabase.from('cv_analizados').insert({
        'nombre': controllers['Nombre']!.text,
        'apellido': controllers['Apellido']!.text,
        'telefono': controllers['Teléfono']!.text,
        'email': controllers['Email']!.text,
        'experiencia': controllers['Experiencia']!.text,
        'educacion': controllers['Educación']!.text,
        'habilidades': controllers['Habilidades']!.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Datos guardados correctamente')),
      );

      Navigator.pop(context); 
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar los datos: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Resultado del Análisis')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: controllers.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: TextField(
                      controller: entry.value,
                      decoration: InputDecoration(
                        labelText: entry.key,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: guardarEnSupabase,
              child: Text('Guardar cambios'),
            ),
          ],
        ),
      ),
    );
  }
}
