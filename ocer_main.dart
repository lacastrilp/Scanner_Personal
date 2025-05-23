// === FLUTTER WEB FRONTEND CON OCR.SPACE Y PARSING ===
// File: lib/main.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minerva OCR Web',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: OcrPage(),
    );
  }
}

class OcrPage extends StatefulWidget {
  @override
  _OcrPageState createState() => _OcrPageState();
}

class _OcrPageState extends State<OcrPage> {
  String extractedText = '';
  Map<String, Map<String, String>> parsedFields = {}; // ← Tipo corregido
  bool isLoading = false;

  Future<void> uploadFileAndSendToOcrSpace() async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result != null && result.files.single.bytes != null) {
      Uint8List fileBytes = result.files.single.bytes!;
      String fileName = result.files.single.name;

      setState(() => isLoading = true);

      final uri = Uri.parse("https://api.ocr.space/parse/image");

      var request = http.MultipartRequest('POST', uri);
      request.headers['apikey'] = 'K89877483388957'; // Reemplaza con tu API Key
      request.fields['language'] = 'spa';
      request.fields['isOverlayRequired'] = 'false';

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      ));

      var response = await request.send();
      final respStr = await response.stream.bytesToString();
      final data = json.decode(respStr);


      final rawText = data['ParsedResults']?[0]?['ParsedText'] ?? 'No se detectó texto.';
      final textoLimpio = await limpiarTextoConIA(rawText);
      final parsed = parseFieldsMinerva(textoLimpio);

      saveAsJson(parsed);

      setState(() {
        extractedText = textoLimpio;
        parsedFields = parsed;
        isLoading = false;




      });
    }
  }

  Map<String, Map<String, String>> parseFieldsMinerva(String rawText) {
    final text = cleanText(rawText);
    final result = <String, Map<String, String>>{};

    // === BLOQUE DE NOMBRE Y APELLIDO (específico para formato Minerva) ===
    final nombreMatch = RegExp(
      r"(?<=HOJA DE VIDA\s*)\n*([A-ZÁÉÍÓÚÑ]{3,}(?:\s+[A-ZÁÉÍÓÚÑ]{2,})+)",
      caseSensitive: false,
    ).firstMatch(text);

    if (nombreMatch != null) {
      final fullName = nombreMatch.group(1)!;
      final parts = fullName.split(RegExp(r'\s+'));
      if (parts.length >= 3) {
        final apellidos = parts.take(2).join(' ');
        final nombres = parts.skip(2).join(' ');
        result['apellido_del_aspirante'] = {'value': apellidos};
        result['nombre_del_aspirante'] = {'value': nombres};
      }
    }


    // === DIRECCIÓN ===
    final direccion = RegExp(r"MEDELL[IÍ]N.*CRA.*\d+-\d+", caseSensitive: false).firstMatch(text);
    if (direccion != null) {
      result['direccion_domicilio'] = {'value': direccion.group(1)!.trim()};
    }

    // === TELÉFONO ===
    final telefono = RegExp(r"\b60\d{7,}\b").firstMatch(text);
    if (telefono != null) result['telefono'] = {'value': telefono.group(0)!};

    // === CELULAR ===
    final celular = RegExp(r"\b3\d{9}\b").firstMatch(text);
    if (celular != null) result['no_celular'] = {'value': celular.group(0)!};

    // === CORREO ===
    final correo = RegExp(r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}").firstMatch(text);
    if (correo != null) result['correo_electronico'] = {'value': correo.group(0)!.toLowerCase()};

    // PROFESIÓN — buscar "profesión" o "ocupación" seguida de texto
    final profesion = RegExp(r"(?:PROFESIÓN|OCUPACIÓN|OFICIO)[^\n]*:\s*(.+)", caseSensitive: false).firstMatch(text);
    if (profesion != null) result['profesion_ocupacion_u_oficio'] = {'value': profesion.group(1)!.trim()};


    // === CARGO DESEADO ===
    final cargo = RegExp(r"(?:CARGO|EMPLEO).*INTERESADO[^\n]*:\s*(.+)", caseSensitive: false).firstMatch(text);
    if (cargo != null) result['empleo_o_cargo_en_el_que_esta_interesado'] = {'value': cargo.group(1)!.trim()};


    // === ESTADO CIVIL ===
    final estado = RegExp(r"ESTADO\s+CIVIL[^\n]*:\s*(\w+(?:\s+\w+)*)", caseSensitive: false).firstMatch(text);
    if (estado != null) result['estado_civil'] = {'value': estado.group(1)!.toUpperCase()};


    // === EXPERIENCIA LABORAL ===
    final exp = RegExp(r"(\d+)\s+AÑOS\s+DE\s+EXPERIENCIA", caseSensitive: false).firstMatch(text);
    if (exp != null) result['anos_de_experiencia_laboral'] = {'value': exp.group(1)!};

    // === NACIONALIDAD ===
    final nac = RegExp(r"NACIONALIDAD[^\n]*:\s*(\w+)", caseSensitive: false).firstMatch(text);
    if (nac != null) result['nacionalidad'] = {'value': nac.group(1)!.toUpperCase()};


    // === FECHA DEL FORMULARIO ===
    final fecha = RegExp(r"Fecha\s+(\d{1,2})\s*/\s*(\d{1,2})\s*/\s*(\d{4})").firstMatch(text);
    if (fecha != null) {
      result['fecha_formulario'] = {
        'value': "${fecha.group(1)}/${fecha.group(2)}/${fecha.group(3)}"
      };
    }



    // === OBJETIVO ===
    final objetivo = RegExp(r"OBJETIVO\s*(.*?)\s*(?=HOJA DE VIDA|¿Está trabajando|\n[A-Z]{2,})", dotAll: true, caseSensitive: false)
        .firstMatch(text);
    if (objetivo != null) {
      result['objetivo'] = {'value': objetivo.group(1)!.trim()};
    }

    return result;
  }



  void saveAsJson(Map<String, Map<String, String>> fields) {
    final jsonOutput = jsonEncode(fields);
    print(jsonOutput); // Para depuración o enviar a backend
  }

  Future<String> limpiarTextoConIA(String textoOcrCrudo) async {
    try {
      final response = await http.post(
        Uri.parse("http://localhost:5000/limpiar"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"text": textoOcrCrudo}),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded['texto_limpio'] ?? textoOcrCrudo;
      } else {
        print("IA error ${response.statusCode}: ${response.body}");
        return textoOcrCrudo;
      }
    } catch (e) {
      print("Error conectando con IA: $e");
      return textoOcrCrudo;
    }
  }



  String cleanText(String raw) {
    return raw
        .replaceAll(RegExp(r'[^A-Za-zÁÉÍÓÚÑáéíóúñ0-9@.:/\n\s-]'), '') // Quita caracteres basura
        .replaceAllMapped(RegExp(r'(?<=\d)\s(?=\d)'), (m) => '')     // Une fechas separadas
        .replaceAll('MEDEL \'N', 'MEDELLÍN')
        .replaceAll('GMAIL COM', 'GMAIL.COM')
        .replaceAll('CRA ', 'CRA')
        .replaceAll('HOJA DE VIDA', '')
        .replaceAll('PARA SOLICITUD DE EMPLEO', '');
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("OCR CV Minerva (OCR.space)")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: uploadFileAndSendToOcrSpace,
              child: Text("Subir imagen o PDF"),
            ),
            SizedBox(height: 20),
            if (isLoading)
              Center(child: CircularProgressIndicator()),
            if (!isLoading && parsedFields.isNotEmpty) ...[
              Text("Campos extraídos:", style: TextStyle(fontWeight: FontWeight.bold)),
              ...parsedFields.entries.map(
                    (e) => Text("${e.key}: ${e.value['value'] ?? ''}"),
              ),
              Divider(),
            ],
            if (!isLoading && extractedText.isNotEmpty) ...[
              Text("Texto completo OCR:", style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(extractedText),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
