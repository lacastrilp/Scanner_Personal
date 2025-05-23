import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> generarCVConPDFMonkey(Map<String, dynamic> datosUsuario) async {
  final apiKey = "DSWR_cysY-sfALmVTAc6"; // Reemplázala con tu clave real
  final templateId = "90e21547-5024-4fef-a23d-de80c01c7b97"; // ID de tu plantilla

  final response = await http.post(
    Uri.parse("https://api.pdfmonkey.io/api/v1/documents"),
    headers: {
      "Authorization": "Bearer $apiKey",
      "Content-Type": "application/json",
    },
    body: jsonEncode({
      "document_template_id": templateId,
      "payload": datosUsuario, // Cambié "data" por "payload" (nombre correcto)
      "status": "pending"
    }),
  );

  final responseBody = jsonDecode(response.body);

  if (response.statusCode == 201) {
    if (responseBody["data"] != null) {
      print("✅ Documento en proceso. ID: ${responseBody["data"]["id"]}");
      print("📄 Puedes verificar el PDF en: ${responseBody["data"]["links"]["self"]}");
    } else {
      print("⚠️ Respuesta inesperada: $responseBody");
    }
  } else {
    print("❌ Error: ${response.statusCode} - ${responseBody["error"] ?? responseBody}");
  }
}

void main() async {
  await generarCVConPDFMonkey({
    "nombres": "Luis",
    "apellidos": "Castrillón",
    "direccion": "Calle 123, Medellín, Colombia",
    "telefono": "+57 300 123 4567",
    "correo": "luis.castrillon@email.com",
    "nacionalidad": "Colombiano",
    "fecha_nacimiento": "15/08/1995",
    "estado_civil": "Soltero",
    "redes_profesionales": [
      {"plataforma": "LinkedIn", "enlace": "linkedin.com/in/luiscastrillon"},
      {"plataforma": "GitHub", "enlace": "github.com/lcastrillon"}
    ],
    "perfil_profesional": "Profesional con experiencia en ventas y atención al cliente.",
    "objetivos_profesionales": "Busco un rol en ventas para aplicar mis habilidades.",
    "experiencia": [
      {
        "empresa": "Tiendas XYZ",
        "cargo": "Ejecutivo de Ventas",
        "inicio": "2022",
        "fin": "2024",
        "descripcion": "Atención al cliente, cierre de ventas, gestión de cartera."
      }
    ],
    "educacion": [
      {
        "institucion": "Universidad EAFIT",
        "titulo": "Administración de Empresas",
        "inicio": "2018",
        "fin": "2023"
      }
    ],
    "habilidades_tecnicas": "Análisis de datos, CRM, Excel avanzado",
    "habilidades_blandas": "Comunicación efectiva, liderazgo, trabajo en equipo",
    "idiomas": [
      {"idioma": "Español", "nivel": "Nativo"},
      {"idioma": "Inglés", "nivel": "Intermedio - B2"}
    ],
    "certificaciones": [
      {
        "nombre": "Estrategias de Ventas",
        "institucion": "Coursera",
        "año": "2023"
      }
    ],
    "referencias": [
      {
        "nombre": "Juan Pérez",
        "cargo": "Gerente de Ventas",
        "empresa": "Tiendas XYZ",
        "contacto": "juan.perez@xyz.com"
      }
    ],
    "entrevistas": {
      "horario": "Lunes a viernes, 8 AM - 6 PM",
      "modalidad": "Virtual o presencial"
    }
  });
}
