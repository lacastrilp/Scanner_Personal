import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OCRScreen(),
    );
  }
}

class OCRScreen extends StatefulWidget {
  @override
  _OCRScreenState createState() => _OCRScreenState();
}

class _OCRScreenState extends State<OCRScreen> {
  Uint8List? _imageBytes;
  String _extractedText = "No se ha extraído texto aún";
  bool _isLoading = false;

  // Método para seleccionar imagen
  Future<void> pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null) {
      setState(() {
        _imageBytes = result.files.first.bytes;
        _extractedText = "Extrayendo texto...";
        _isLoading = true;
      });

      extractTextFromImage(_imageBytes!);
    }
  }

  // Método para enviar la imagen a OCR.space
  Future<void> extractTextFromImage(Uint8List imageBytes) async {
    String apiKey = "K89866469688957";  // ⚠️ Reemplaza con tu API Key
    var url = Uri.parse("https://api.ocr.space/parse/image");

    var request = http.MultipartRequest('POST', url)
      ..headers.addAll({"apikey": apiKey})  // Agrega la API Key
      ..files.add(http.MultipartFile.fromBytes("file", imageBytes, filename: "image.png"))
      ..fields["language"] = "spa"
      ..fields["isOverlayRequired"] = "false"
      ..fields["OCREngine"] = "2";

    var response = await request.send();

    if (response.statusCode == 200) {
      var responseData = await response.stream.bytesToString();
      var jsonData = json.decode(responseData);

      setState(() {
        _extractedText = jsonData["ParsedResults"][0]["ParsedText"] ?? "No se detectó texto.";
        _isLoading = false;
      });
    } else {
      setState(() {
        _extractedText = "Error en la API: ${response.statusCode}";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("OCR en Flutter Web")),
      body: SingleChildScrollView(  // Agrega desplazamiento vertical
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_imageBytes != null)
                Container(
                  height: MediaQuery.of(context).size.height * 0.4, // Evita desbordamiento
                  child: Image.memory(_imageBytes!),
                )
              else
                Icon(Icons.image, size: 100, color: Colors.grey),

              SizedBox(height: 20),

              ElevatedButton(
                onPressed: pickImage,
                child: Text("Seleccionar Imagen"),
              ),

              SizedBox(height: 20),

              _isLoading
                  ? CircularProgressIndicator()
                  : Container(
                height: 200,  // Ajusta la altura para el texto extraído
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(_extractedText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
