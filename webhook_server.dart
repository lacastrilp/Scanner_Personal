import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';


Future<void> main() async {
  const mindeeSigningSecret = 'GmOWtsPLJf9YnnwNIBjk8fk5PeF4jucVOSY';

  final router = Router();



  router.post('/mindee/callback', (Request request) async {
    final body = await request.readAsString();
    final signatureHeader = request.headers['x-mindee-signature'];

    if (signatureHeader == null) {
      return Response.forbidden('❌ Falta la firma X-Mindee-Signature');
    }

    // ✅ Calcula HMAC con el secreto
    final calculatedSignature = Hmac(sha256, utf8.encode(mindeeSigningSecret))
        .convert(utf8.encode(body))
        .toString();

    if (signatureHeader != calculatedSignature) {
      return Response.forbidden('❌ Firma inválida');
    }

    try {
      final data = jsonDecode(body);
      final prediction = data['document']?['inference']?['prediction'];

      if (prediction == null) {
        return Response(400, body: 'No prediction data found');
      }

      print('📄 Predicción recibida y verificada:');
      prediction.forEach((key, value) {
        print('👉 $key: ${value['value']}');
      });

      return Response.ok('✅ Webhook recibido correctamente');
    } catch (e) {
      print('❌ Error al procesar el JSON: $e');
      return Response(500, body: 'Error procesando el JSON');
    }
  });


  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addHandler(router);

  final server = await serve(handler, InternetAddress.anyIPv4, 80);
  print('✅ Webhook escuchando en http://${server.address.host}:${server.port}/mindee/callback');
}
