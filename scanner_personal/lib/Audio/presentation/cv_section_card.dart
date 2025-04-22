import 'package:flutter/material.dart';
import '../domain/models/cv_section_model.dart';

class CVSectionCard extends StatefulWidget {
  final CVSection section;
  final bool isRecording;
  final bool isPlaying;
  final bool hasAudio;
  final String transcription;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final VoidCallback onPlayRecording;
  final Function(String) onUpdateTranscription;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final bool isFirstSection;
  final bool isLastSection;

  const CVSectionCard({
    Key? key,
    required this.section,
    required this.isRecording,
    required this.isPlaying,
    required this.hasAudio,
    required this.transcription,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onPlayRecording,
    required this.onUpdateTranscription,
    required this.onNext,
    required this.onPrevious,
    required this.isFirstSection,
    required this.isLastSection,
  }) : super(key: key);

  @override
  _CVSectionCardState createState() => _CVSectionCardState();
}

class _CVSectionCardState extends State<CVSectionCard> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Cabecera de la tarjeta
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF00FF7F).withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.section.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.section.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),

            // Cuerpo de la tarjeta
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Campos relevantes para esta sección
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Campos para incluir:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: widget.section.fields.map((field) => Chip(
                              label: Text(field),
                              backgroundColor: Color(0xFF00FF7F).withOpacity(0.2),
                              labelStyle: TextStyle(fontSize: 12),
                            )).toList(),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),

                    // Control de grabación de audio
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: widget.isRecording
                                ? widget.onStopRecording
                                : widget.onStartRecording,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: widget.isRecording ? Colors.red : Color(0xFF00FF7F),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                widget.isRecording ? Icons.stop : Icons.mic,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            widget.isRecording
                                ? 'Presiona para detener la grabación'
                                : 'Presiona para iniciar la grabación',
                            style: TextStyle(fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),

                    // Reproductor de audio (solo visible si hay audio grabado)
                    if (widget.hasAudio) ...[
                      Center(
                        child: ElevatedButton.icon(
                          icon: Icon(
                            widget.isPlaying ? Icons.stop : Icons.play_arrow,
                            color: Colors.white,
                          ),
                          label: Text(
                            widget.isPlaying ? 'Detener' : 'Reproducir grabación',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF00FF7F),
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: widget.onPlayRecording,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Pie de la tarjeta con botones de navegación
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Botón Anterior
                  if (!widget.isFirstSection)
                    ElevatedButton.icon(
                      icon: Icon(Icons.arrow_back),
                      label: Text('Anterior'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black87,
                      ),
                      onPressed: widget.onPrevious,
                    )
                  else
                    SizedBox(width: 100),

                  // Botón Siguiente o Finalizar
                  ElevatedButton.icon(
                    icon: Icon(widget.isLastSection ? Icons.check : Icons.arrow_forward),
                    label: Text(widget.isLastSection ? 'Finalizar' : 'Siguiente'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF00FF7F),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey,
                    ),
                    onPressed: widget.hasAudio ? widget.onNext : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}