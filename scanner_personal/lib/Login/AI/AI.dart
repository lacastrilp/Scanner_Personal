import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> generarCVGratis(String datosUsuario) async {
  final response = await http.post(
    Uri.parse("https://openrouter.ai/api/v1/chat/completions"),
    headers: {
      "Authorization": "Bearer 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",
      "Content-Type": "application/json",
    },
    body: jsonEncode({
      "model": "deepseek/deepseek-chat-v3-0324:free",
      "max_tokens": 1500, // Asegura que la respuesta sea más larga
      "messages": [
        {
          "role": "system",
          "content": "Eres un generador avanzado de currículums profesionales. A partir de la información proporcionada, estructura un CV claro, profesional y bien organizado, resaltando las fortalezas del candidato. Usa un formato adecuado con secciones bien definidas y adaptadas al perfil del usuario."
        },
        {
          "role": "user",
          "content": "Genera un CV con los siguientes datos:\n\n$datosUsuario"
        }
      ]
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(utf8.decode(response.bodyBytes)); // Decodifica correctamente
    print("CV generado:\n${data["choices"][0]["message"]["content"]}");
  } else {
    print("Error: ${response.statusCode} - ${response.body}");
  }
}

void main() async {
  await generarCVGratis("""
    Nombres: Luis
    Apellidos: Castrillón
    Dirección: Calle 123, Medellín, Colombia
    Teléfono: +57 300 123 4567
    Correo electrónico: luis.castrillon@email.com
    Nacionalidad: Colombiano
    Fecha de nacimiento: 15/08/1995
    Estado civil: Soltero
    LinkedIn: linkedin.com/in/luiscastrillon
    GitHub: github.com/lcastrillon
    Portafolio: luiscastrillon.dev

    🔹 Perfil Profesional / Resumen:
    Profesional con experiencia en ventas y atención al cliente, especializado en estrategias comerciales y negociación.

    🔹 Objetivos Profesionales:
    Busco un rol en ventas que me permita aplicar mis habilidades de negociación y expansión de mercado.

    🔹 Experiencia Laboral:
    - Nombre de la empresa: Tiendas XYZ
    - Cargo: Ejecutivo de Ventas
    - Fechas: 2022 - 2024
    - Funciones: Atención al cliente, cierre de ventas, gestión de cartera de clientes.
    - Tecnologías utilizadas: CRM Salesforce, Excel avanzado.

    🔹 Educación y Formación Académica:
    - Universidad EAFIT
    - Título: Administración de Empresas
    - Fechas: 2018 - 2023
    - Promedio: 4.2

    🔹 Habilidades y Competencias:
    - Técnicas: Análisis de datos, estrategias de ventas, manejo de CRM.
    - Blandas: Comunicación efectiva, liderazgo, trabajo en equipo.

    🔹 Idiomas:
    - Español (Nativo)
    - Inglés (Intermedio - B2)

    🔹 Certificaciones y Cursos:
    - Curso: Estrategias de Ventas
    - Institución: Coursera
    - Año: 2023

    🔹 Proyectos Personales o Académicos:
    - Nombre: Desarrollo de una estrategia comercial para Tiendas XYZ.
    - Tecnologías: Power BI, CRM.

    🔹 Referencias Profesionales:
    - Nombre: Juan Pérez
    - Cargo: Gerente de Ventas
    - Empresa: Tiendas XYZ
    - Contacto: juan.perez@xyz.com

    🔹 Disponibilidad para Entrevistas:
    - Horario: Lunes a viernes, 8 AM - 6 PM.
    - Modalidad: Virtual o presencial.
  """);
}
