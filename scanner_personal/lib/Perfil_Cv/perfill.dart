//TODO
/**
 * - Que la info basica este en un cuadrito luego de la foto de perfil
 * -Pendiente mejora para que el usuario sea el que ingreso seccion
 * - Que los textos no estén centrados y que no tengan un fondo horrible
 * - Mostrar una foto de perfil online
**/

import 'package:flutter/material.dart';
import 'EditProfileScreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int? _expandedIndex;
  int? _hoverIndex;
  Map<String, dynamic> userData = {};

  @override
  void initState() {
    super.initState();
    fetchUserData(); // Cargar datos desde Supabase
  }

  Future<void> fetchUserData() async {
    final supabase = Supabase.instance.client;
    final userId = '1'; // Reemplaza con el ID válido o pásalo desde otra parte

    //Acá va lo de el usuario que inicia seccion
    try {
      final response = await supabase
          .from('perfil_information')
          .select()
          .eq('id', userId)
          .limit(1)
          .single();
      if (response != null) {
        setState(() {
          userData = {
            "Información Personal": {
              "Nombres": response['nombres'] ?? '',
              "Apellidos": response['apellidos'] ?? '',
              "Fotografía": response['fotografia'] ?? '',
              "Dirección": response['direccion'] ?? '',
              "Teléfono": response['telefono'] ?? '',
              "Correo electrónico": response['correo'] ?? '',
              "Nacionalidad": response['nacionalidad'] ?? '',
              "Fecha de nacimiento": response['fecha_nacimiento'] ?? '',
              "Estado civil": response['estado_civil'] ?? '',
            },
            "Redes y Portafolio": {
              "LinkedIn": response['linkedin'] ?? '',
              "GitHub": response['github'] ?? '',
              "Portafolio": response['portafolio'] ?? '',
            },
            "Experiencia Laboral": {
              "Perfil profesional": response['perfil_profesional'] ?? '',
              "Objetivos Profesionales": response['objetivos_profesionales'] ?? '',
              "Experiencia Laboral": response['experiencia_laboral'] ?? '',
              "Expectativas Laborales": response['expectativas_laborales'] ?? '',
              "Experiencia Internacional": response['experiencia_internacional'] ?? '',
            },
            "Educación y Conocimientos": {
              "Educación": response['educacion'] ?? '',
              "Habilidades": response['habilidades'] ?? '',
              "Idiomas": response['idiomas'] ?? '',
              "Certificaciones": response['certificaciones'] ?? '',
              "Participación en Proyectos": response['proyectos'] ?? '',
              "Publicaciones": response['publicaciones'] ?? '',
              "Premios": response['premios'] ?? '',
              "Voluntariados": response['voluntariados'] ?? '',
            },
            "Otros": {
              "Referencias": response['referencias'] ?? '',
              "Permisos y Documentación": response['permisos_documentacion'] ?? '',
              "Vehículo y Licencias": response['vehiculo_licencias'] ?? '',
              "Disponibilidad para Entrevistas": response['disponibilidad_entrevistas'] ?? '',
            }
          };
        });
      }
    } catch (error) {
      print("Error al obtener los datos: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: Icon(Icons.person,color: Color(0xFF25AD4C),),leadingWidth: 60,
        title: Text("Información del Perfil"),
        titleSpacing: 0,
        backgroundColor: Colors.white54,
        shadowColor: Colors.black12,
        bottomOpacity: 1,
        surfaceTintColor: Colors.black26,
      ),
      floatingActionButton: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 20.0, bottom: 10),
          child: FloatingActionButton.extended(
            backgroundColor: Color(0xFF25AD4C),
            icon: Icon(Icons.edit),
            label: Text('Editar'),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProfileScreen(
                    userId: '1',
                    userData: userData,
                  ),
                ),
              );

              if (result == true) {
                await fetchUserData(); // 🔁 Refresca los datos si se editó algo
              }
            },
          ),
        ),
      ),
      body: userData.isEmpty
          ? Center(child: CircularProgressIndicator()) // Muestra un indicador de carga
          : SingleChildScrollView(
        child: ExpansionPanelList(
          dividerColor: Colors.transparent,
          animationDuration: Duration(milliseconds: 400),
          expansionCallback: (index, _) {
            setState(() {
              _expandedIndex = (_expandedIndex == index) ? null : index;
            });
          },
          children: _buildPanels(),
        ),
      ),
    );
  }

  List<ExpansionPanel> _buildPanels() {
    List<String> categories = userData.keys.toList();
    return List.generate(categories.length, (index) {
      String category = categories[index];
      var content = userData[category];

      return ExpansionPanel(
        canTapOnHeader: true, // Permite expandir sin la flecha automática
        backgroundColor: Colors.white54,
        headerBuilder: (context, isExpanded) {
          return MouseRegion(
            onEnter: (_) => setState(() => _hoverIndex = index),
            onExit: (_) => setState(() => _hoverIndex = null),
            child: InkWell(
              onTap: () {
                setState(() {
                  _expandedIndex = (_expandedIndex == index) ? null : index;
                });
              },
              child: Container(
                alignment: Alignment.centerLeft, // Asegura la alineación a la izquierda
                padding: EdgeInsets.all(8),
                margin: EdgeInsets.symmetric(horizontal: 0, vertical: 1),

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: _hoverIndex == index ? Color(0xFF64319b).withOpacity(0.6):Colors.white24,
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                 // mainAxisAlignment: MainAxisAlignment.start, // Ajusta alineación
                  children: [
                    Text(
                      textAlign: TextAlign.left,
                      category,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        body: Container(
          padding: EdgeInsets.all(8),
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildContent(content),
              SizedBox(height: 8),
            ],
          ),
        ),
        isExpanded: _expandedIndex == index,
      );
    });
  }

  Widget _buildContent(dynamic content) {
    if (content is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: content.map((item) {
          if (item is Map) {
            return Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: item.entries.map((entry) => Text("${entry.key}: ${entry.value}")).toList(),
              ),
            );
          } else {
            return Text(item.toString());
          }
        }).toList(),
      );
    } else if (content is Map) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: content.entries.map((entry) {
          if (entry.key == "Fotografía" && entry.value.isNotEmpty) {
            return Image.network(entry.value, height: 100, width: 100);
          }
          return Text("${entry.key}: ${entry.value}");
        }).toList(),
      );
    } else {
      return Text("No hay información disponible");
    }
  }
}
