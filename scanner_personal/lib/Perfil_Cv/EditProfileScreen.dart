import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const EditProfileScreen({required this.userId, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};

  final Map<String, String> fieldMapping = {
    "Nombres": "nombres",
    "Apellidos": "apellidos",
    "Fotografía": "fotografia",
    "Dirección": "direccion",
    "Teléfono": "telefono",
    "Correo electrónico": "correo",
    "Nacionalidad": "nacionalidad",
    "Fecha de nacimiento": "fecha_nacimiento",
    "Estado civil": "estado_civil",
    "LinkedIn": "linkedin",
    "GitHub": "github",
    "Portafolio": "portafolio",
    "Perfil profesional": "perfil_profesional",
    "Objetivos Profesionales": "objetivos_profesionales",
    "Experiencia Laboral": "experiencia_laboral",
    "Expectativas Laborales": "expectativas_laborales",
    "Experiencia Internacional": "experiencia_internacional",
    "Educación": "educacion",
    "Habilidades": "habilidades",
    "Idiomas": "idiomas",
    "Certificaciones": "certificaciones",
    "Participación en Proyectos": "proyectos",
    "Publicaciones": "publicaciones",
    "Premios": "premios",
    "Voluntariados": "voluntariados",
    "Referencias": "referencias",
    "Permisos y Documentación": "permisos_documentacion",
    "Vehículo y Licencias": "vehiculo_licencias",
    "Contacto de Emergencia": "contacto_emergencia",
    "Disponibilidad para Entrevistas": "disponibilidad_entrevistas",
  };

  @override
  void initState() {
    super.initState();
    fieldMapping.forEach((label, key) {
      final value = _getValueByKey(label);
      _controllers[label] = TextEditingController(text: value);
    });
  }

  String _getValueByKey(String label) {
    for (var section in widget.userData.values) {
      if (section is Map && section.containsKey(label)) {
        return section[label] ?? '';
      }
    }
    return '';
  }

  Future<void> _saveChanges() async {
    final updates = <String, dynamic>{};

    fieldMapping.forEach((label, key) {
      updates[key] = _controllers[label]?.text ?? '';
    });

    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('perfil_information')
          .update(updates)
          .eq('id', widget.userId);

      Navigator.pop(context, true);
    } catch (error) {
      print('Error al guardar cambios: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar los cambios.')),
      );
    }
  }

  @override
  void dispose() {
    _controllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Perfil'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              ...fieldMapping.keys.map((label) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextFormField(
                    controller: _controllers[label],
                    decoration: InputDecoration(
                      labelText: label,
                      border: OutlineInputBorder(),
                    ),
                  ),
                );
              }).toList(),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveChanges,
                child: Text('Guardar Cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
