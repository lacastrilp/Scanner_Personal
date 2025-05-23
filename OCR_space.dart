import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

Future<String> sendToOcrSpace(Uint8List fileBytes, String fileName) async {
  final uri = Uri.parse("https://api.ocr.space/parse/image");

  var request = http.MultipartRequest('POST', uri);
  request.headers['apikey'] = 'K89877483388957'; // Consíguela en https://ocr.space/ocrapi
  request.fields['language'] = 'spa'; // Español
  request.fields['isOverlayRequired'] = 'false';

  request.files.add(http.MultipartFile.fromBytes(
    'file',
    fileBytes,
    filename: fileName,
  ));

  var response = await request.send();
  final result = await response.stream.bytesToString();
  final decoded = jsonDecode(result);

  return decoded['ParsedResults']?[0]?['ParsedText'] ?? '';
}
