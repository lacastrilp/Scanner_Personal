import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

const supabaseUrl = "https://zpprbzujtziokfyyhlfa.supabase.co";
const supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpwcHJienVqdHppb2tmeXlobGZhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA3ODAyNzgsImV4cCI6MjA1NjM1NjI3OH0.cVRK3Ffrkjk7M4peHsiPPpv_cmXwpX859Ii49hohSLk";
const supabaseTable = "documentos_procesados";

class MindeeScreen extends StatefulWidget {
  const MindeeScreen({super.key});

  @override
  State<MindeeScreen> createState() => _MindeeScreenState();
}

class _MindeeScreenState extends State<MindeeScreen> {
  Uint8List? _fileBytes;
  String? _fileName;
  String _responseText = "No se ha analizado ningún archivo aún.";
  bool _isLoading = false;
  Map<String, dynamic>? _jsonData;

  Future<void> pickAndSendFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.bytes != null) {
      final file = result.files.first;

      setState(() {
        _fileBytes = file.bytes;
        _fileName = file.name;
        _isLoading = true;
        _responseText = "Analizando archivo con OCR.Space + IA...";
      });

      await sendToMindeeBackend(file.bytes!, file.name);

    }
  }

  Future<void> sendToMindeeBackend(Uint8List bytes, String fileName) async {
    final uri = Uri.parse("http://localhost:5000/analizar"); // apuntando a app2.py

    final request = http.MultipartRequest("POST", uri)
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final decoded = jsonDecode(responseBody);
      final campos = decoded['campos_extraidos'] ?? {};

      setState(() {
        _responseText = const JsonEncoder.withIndent('  ').convert(campos);
        _jsonData = campos;
        _isLoading = false;
      });
    } else {
      setState(() {
        _responseText = "❌ Error del backend Mindee (${response.statusCode})";
        _isLoading = false;
      });
    }
  }



  /*Future<void> sendToOcrSpaceAndParse(Uint8List bytes, String filename) async {
    final uri = Uri.parse("https://api.ocr.space/parse/image");

    final request = http.MultipartRequest('POST', uri)
      ..headers['apikey'] = 'K89877483388957'
      ..fields['language'] = 'spa'
      ..fields['isOverlayRequired'] = 'false'
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

    try {
      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      final data = json.decode(respStr);
      final rawText = data['ParsedResults']?[0]?['ParsedText'] ?? '';

      final textoLimpio = await limpiarTextoConIA(rawText);
      final parsed = parseFieldsMinerva(textoLimpio);

      setState(() {
        _responseText = textoLimpio;
        _jsonData = parsed;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _responseText = "❌ Error al procesar OCR: $e";
        _isLoading = false;
      });
    }
  }*/

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



  Future<void> fetchMindeeDocument(String documentId) async {
    const apiKey = "e151df3d4c503c1b4680c9edacb68f65";
    final docUri = Uri.parse("https://api.mindee.net/v1/products/lacastrilp/api_docs/v1/documents/$documentId");

    final response = await http.get(docUri, headers: {
      'Authorization': 'Token $apiKey',
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _jsonData = data;
        _responseText = const JsonEncoder.withIndent('  ').convert(data);
        _isLoading = false;
      });
    } else {
      setState(() {
        _responseText = "Error al obtener documento: ${response.statusCode}";
        _isLoading = false;
      });
    }
  }

  Widget _buildStructuredView(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) {
      return const Center(child: Text("Sin datos extraídos."));
    }

    return ListView(
      children: data.entries.map<Widget>((entry) {
        final value = entry.value is Map ? entry.value['value'] : entry.value;
        return ListTile(
          title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(value?.toString() ?? '—'),
        );
      }).toList(),
    );
  }


  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF090467);
    const backgroundColor = Color(0xfff5f5fa);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFFeff8ff),
        foregroundColor: primaryColor,
        elevation: 1,
        title: Text("Escaneo de Documento", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analizador de Archivos',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            if (_fileName != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  'Archivo seleccionado: $_fileName',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: pickAndSendFile,
              icon: const Icon(Icons.upload_file),
              label: const Text("Seleccionar y analizar archivo"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(
                        labelColor: primaryColor,
                        tabs: [
                          Tab(text: "Vista organizada"),
                          Tab(text: "JSON crudo"),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildStructuredView(_jsonData),
                            SingleChildScrollView(
                              padding: const EdgeInsets.all(8),
                              child: SelectableText(
                                _responseText,
                                style: const TextStyle(fontFamily: 'monospace'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
