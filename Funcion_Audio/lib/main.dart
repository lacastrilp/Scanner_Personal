import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Constante para la API key
const String ASSEMBLY_API_KEY = '127d118f76c446a0ad8dce63a120336d';
const int MAX_MONTHLY_TRANSCRIPTIONS = 25000; // ~416 horas = 25,000 minutos
const double COST_PER_MINUTE = 0.002; // $0.12 por hora = $0.002 por minuto

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://zpprbzujtziokfyyhlfa.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpwcHJienVqdHppb2tmeXlobGZhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA3ODAyNzgsImV4cCI6MjA1NjM1NjI3OH0.cVRK3Ffrkjk7M4peHsiPPpv_cmXwpX859Ii49hohSLk',
  );
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: AudioRecorderScreen(),
  ));
}

final supabase = Supabase.instance.client;

class AudioRecorderScreen extends StatefulWidget {
  const AudioRecorderScreen({super.key});

  @override
  _AudioRecorderScreenState createState() => _AudioRecorderScreenState();
}

class _AudioRecorderScreenState extends State<AudioRecorderScreen> {
  Record _audioRecorder = Record();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  String? _audioBlobUrl;
  Uint8List? _audioBytes;
  String? _audioSupabaseUrl; // URL en Supabase
  bool _isTranscribing = false;
  bool _isPlaying = false;
  int _monthlyTranscriptions = 0;
  double _monthlyCost = 0.0;
  int _currentStep =
      0; // 0: grabación, 1: reproducción/confirmación, 2: transcripción
  DateTime? _recordingStartTime; // Momento de inicio de grabación

  @override
  void initState() {
    super.initState();
    _loadUsageData();
    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _isPlaying = false;
      });
    });
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    try {
      await _audioRecorder.dispose();
      _audioRecorder = Record();
      await _audioRecorder.hasPermission();
    } catch (e) {
      print("Error al inicializar el grabador: $e");
    }
  }

  Future<void> _loadUsageData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _monthlyTranscriptions = prefs.getInt('monthlyTranscriptions') ?? 0;
      _monthlyCost = prefs.getDouble('monthlyCost') ?? 0.0;
    });
  }

  Future<void> _saveUsageData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('monthlyTranscriptions', _monthlyTranscriptions);
    await prefs.setDouble('monthlyCost', _monthlyCost);
  }

  Future<bool> _checkUsageLimits() async {
    if (_monthlyTranscriptions >= MAX_MONTHLY_TRANSCRIPTIONS) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Has alcanzado el límite mensual de transcripciones.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }

  void _resetRecording() async {
    // Primero detenemos cualquier reproducción en curso
    if (_isPlaying) {
      await _audioPlayer.stop();
    }

    // Detenemos grabación si está en curso
    if (_isRecording) {
      try {
        await _audioRecorder.stop();
      } catch (e) {
        print("Error al detener grabación durante reset: $e");
      }
    }

    // Reiniciamos el grabador
    await _initRecorder();

    setState(() {
      _currentStep = 0;
      _audioBlobUrl = null;
      _audioSupabaseUrl = null;
      _audioBytes = null;
      _isRecording = false;
      _isPlaying = false;
      _isTranscribing = false;
      _recordingStartTime = null;
    });
  }

  Future<void> _startRecording() async {
    try {
      // Reiniciar el grabador si ya estaba en uso
      if (_isRecording) {
        await _audioRecorder.stop();
      }

      bool hasPermission = await _audioRecorder.hasPermission();
      if (hasPermission) {
        // Configurar el grabador con opciones óptimas
        await _audioRecorder.start();
        _recordingStartTime = DateTime.now();
        setState(() {
          _isRecording = true;
        });
        print("Grabación iniciada correctamente");
      } else {
        print("No se tienen permisos para grabar audio");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se tienen permisos para grabar audio.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Error al iniciar grabación: $e");
      // Reiniciar el grabador en caso de error
      await _initRecorder();
    }
  }

  Future<void> _stopRecording() async {
    // Verificar si realmente estamos grabando
    if (!_isRecording) {
      print("Se intentó detener una grabación inexistente");
      return;
    }

    try {
      // Verificar si la grabación tiene una duración mínima
      final now = DateTime.now();
      final recordingDuration = _recordingStartTime != null
          ? now.difference(_recordingStartTime!)
          : Duration.zero;

      if (recordingDuration.inMilliseconds < 1000) {
        // Grabación demasiado corta, esperar un poco más
        print(
            "Grabación demasiado corta (${recordingDuration.inMilliseconds}ms), esperando...");
        await Future.delayed(
            Duration(milliseconds: 1000 - recordingDuration.inMilliseconds));
      }

      String? path = await _audioRecorder.stop();
      print(
          "Grabación detenida. Path: $path, duración: ${recordingDuration.inSeconds}s");

      if (path != null && path.isNotEmpty) {
        setState(() {
          _isRecording = false;
          _audioBlobUrl = path;
          _currentStep = 1;
          _recordingStartTime = null;
        });
      } else {
        print("Error: path de grabación vacío o nulo");
        _resetRecording();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al grabar audio. Intente nuevamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Error al detener grabación: $e");
      _resetRecording();
    }
  }

  Future<void> _convertBlobToBytesAndUpload(String blobUrl) async {
    try {
      final response = await html.HttpRequest.request(
        blobUrl,
        responseType: 'arraybuffer',
      );

      if (response.response is ByteBuffer) {
        _audioBytes = Uint8List.view(response.response as ByteBuffer);
        await _uploadAudioToSupabase();
      }
    } catch (e) {
      print("Error al convertir Blob a bytes: $e");
    }
  }

  Future<void> _uploadAudioToSupabase() async {
    if (_audioBytes == null) return;

    try {
      final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.webm';
      final response = await supabase.storage.from('Audios').uploadBinary(
          fileName, _audioBytes!,
          fileOptions: const FileOptions(contentType: 'audio/webm'));

      if (response.isNotEmpty) {
        _audioSupabaseUrl =
            supabase.storage.from('Audios').getPublicUrl(fileName);
        setState(() {});
        await _saveAudioinDB();
        print("Archivo subido a Supabase: $_audioSupabaseUrl");
      }
    } catch (e) {
      print("Error al subir el audio a Supabase: $e");
    }
  }

  Future<void> _saveAudioinDB() async {
    if (_audioSupabaseUrl == null) {
      print(
          "Error: _audioSupabaseUrl es null, no se puede guardar en la base de datos");
      return;
    }

    try {
      print("Intentando guardar audio en la base de datos...");
      print("URL del audio: $_audioSupabaseUrl");

      final response = await supabase.from('audio_transcrito').insert({
        'transcripcion': '',
        'enlace_audio': _audioSupabaseUrl!,
      });

      print("Respuesta de Supabase al insertar: $response");

      if (response.isEmpty) {
        print(
            "Advertencia: No se pudo insertar el registro en la base de datos");
      } else {
        print("Audio guardado exitosamente en la base de datos.");
      }
    } catch (e) {
      print("Error al guardar el audio en la base de datos: $e");
      print("Stack trace: ${StackTrace.current}");
    }
  }

  Future<void> _processConfirmedAudio() async {
    try {
      setState(() {
        _isTranscribing = true;
      });

      // 1. Convertir a bytes y subir a Supabase
      if (_audioBlobUrl != null) {
        await _convertBlobToBytesAndUpload(_audioBlobUrl!);
      } else {
        throw Exception('No hay grabación disponible');
      }

      // 2. Transcribir el audio (solo si se subió correctamente)
      if (_audioSupabaseUrl != null) {
        await _transcribeAudio(_audioSupabaseUrl!);
      } else {
        throw Exception('Error al subir el audio a Supabase');
      }
    } catch (e) {
      print("Error al procesar el audio: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al procesar el audio: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
      setState(() {
        _isTranscribing = false;
      });
    }
  }

  Future<void> _transcribeAudio(String audioUrl) async {
    try {
      if (!await _checkUsageLimits()) return;

      // Mostrar mensajes de estado
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enviando audio para transcripción...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );

      // Primero, enviamos la URL del audio a AssemblyAI
      var uploadRequest = http.Request(
        'POST',
        Uri.parse('https://api.assemblyai.com/v2/transcript'),
      );

      uploadRequest.headers.addAll({
        'authorization': ASSEMBLY_API_KEY,
        'content-type': 'application/json',
      });

      uploadRequest.body = jsonEncode({
        'audio_url': audioUrl,
        'language_code': 'es',
      });

      final uploadResponse = await http.Client().send(uploadRequest).timeout(
          Duration(seconds: 15),
          onTimeout: () => throw Exception(
              'Tiempo de espera agotado al iniciar la transcripción'));

      final uploadResponseBody = await uploadResponse.stream.bytesToString();

      print("Respuesta de AssemblyAI: $uploadResponseBody");

      if (uploadResponse.statusCode == 401) {
        throw Exception(
            'Error de autenticación: La API key de AssemblyAI no es válida o ha expirado. Por favor, obtén una nueva API key en https://www.assemblyai.com/dashboard/account');
      }

      final uploadJson = jsonDecode(uploadResponseBody);

      if (uploadResponse.statusCode != 200) {
        throw Exception(
            'Error al iniciar la transcripción: ${uploadJson['error'] ?? uploadJson}');
      }

      final String transcriptId = uploadJson['id'];
      print("ID de transcripción obtenido: $transcriptId");

      // Mostrar mensaje de procesamiento
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Procesando audio... Esto puede tardar unos momentos.'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 3),
        ),
      );

      // Esperamos y consultamos el resultado
      bool completed = false;
      String transcription = '';
      int retries = 0;
      final maxRetries = 20; // Máximo de 20 intentos (60 segundos)

      while (!completed && retries < maxRetries) {
        retries++;
        print("Intento $retries de $maxRetries para obtener la transcripción");

        try {
          final pollingResponse = await http.get(
            Uri.parse('https://api.assemblyai.com/v2/transcript/$transcriptId'),
            headers: {'authorization': ASSEMBLY_API_KEY},
          ).timeout(Duration(seconds: 10));

          final pollingJson = jsonDecode(pollingResponse.body);
          print("Estado de transcripción: ${pollingJson['status']}");

          if (pollingJson['status'] == 'completed') {
            completed = true;
            transcription = pollingJson['text'];
            print("Transcripción completada: $transcription");
          } else if (pollingJson['status'] == 'error') {
            throw Exception(
                'Error en la transcripción: ${pollingJson['error']}');
          } else if (pollingJson['status'] == 'processing' ||
              pollingJson['status'] == 'queued') {
            // Seguimos esperando
            await Future.delayed(Duration(seconds: 3));
          } else {
            print("Estado desconocido: ${pollingJson['status']}");
            await Future.delayed(Duration(seconds: 3));
          }
        } catch (e) {
          print("Error al consultar estado de transcripción: $e");
          // Esperamos antes de reintentar
          await Future.delayed(Duration(seconds: 3));
        }
      }

      if (!completed) {
        throw Exception(
            'Tiempo de espera agotado. La transcripción está tomando demasiado tiempo.');
      }

      setState(() {
        _monthlyTranscriptions++;
      });
      await _saveUsageData();
      await _updateTranscription(transcription);

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Transcripción completada con éxito!'),
          backgroundColor: Color(0xFF00FF7F),
          duration: Duration(seconds: 5),
        ),
      );

      // Volver al paso inicial
      _resetRecording();
    } catch (e) {
      print("Error en la transcripción: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 10),
        ),
      );
      // No reiniciamos la grabación aquí en caso de error
    } finally {
      setState(() {
        _isTranscribing = false;
      });
    }
  }

  Future<void> _updateTranscription(String transcription) async {
    try {
      if (_audioSupabaseUrl == null) {
        print(
            "Error: _audioSupabaseUrl es null, no se puede actualizar la transcripción");
        return;
      }

      print("Intentando actualizar transcripción en Supabase...");
      print("URL del audio: $_audioSupabaseUrl");
      print("Transcripción a guardar: $transcription");

      final response = await supabase
          .from('audio_transcrito')
          .update({'transcripcion': transcription}).eq(
              'enlace_audio', _audioSupabaseUrl!);

      print("Respuesta de Supabase: $response");

      if (response.isEmpty) {
        print("Advertencia: No se encontró ningún registro para actualizar");
      } else {
        print("Transcripción actualizada exitosamente en la base de datos.");
      }
    } catch (e) {
      print("Error al actualizar la transcripción en Supabase: $e");
      print("Stack trace: ${StackTrace.current}");
    }
  }

  Future<void> _playRecording() async {
    if (_isPlaying) {
      await _audioPlayer.stop();
      setState(() {
        _isPlaying = false;
      });
    } else {
      if (_audioSupabaseUrl != null) {
        await _audioPlayer.play(UrlSource(_audioSupabaseUrl!));
      } else if (_audioBlobUrl != null) {
        await _audioPlayer.play(UrlSource(_audioBlobUrl!));
      }
      setState(() {
        _isPlaying = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black),
                onPressed: _resetRecording,
              )
            : null,
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                if (_currentStep == 0) ...[
                  Text(
                    'Generar hoja de vida por medio de Audio',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _isRecording ? Colors.red : Color(0xFF00FF7F),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isRecording ? Icons.stop : Icons.mic,
                        color: Colors.white,
                        size: 40,
                      ),
                      onPressed: () {
                        if (_isRecording) {
                          _stopRecording();
                        } else {
                          _startRecording();
                        }
                      },
                    ),
                  ),
                  SizedBox(height: 40),
                  Text(
                    _isRecording
                        ? 'Presiona para detener la grabación'
                        : 'Presiona para iniciar la grabación',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (_currentStep == 1) ...[
                  Text(
                    'Verifica tu grabación',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                  GestureDetector(
                    onTap: _playRecording,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Color(0xFF00FF7F),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isPlaying ? Icons.stop : Icons.play_arrow,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                  SizedBox(height: 60),
                  if (!_isTranscribing) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            padding: EdgeInsets.symmetric(
                                horizontal: 30, vertical: 15),
                          ),
                          onPressed: _resetRecording,
                          child: Text('Volver a grabar'),
                        ),
                        SizedBox(width: 20), // Reduced spacing between buttons
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF00FF7F),
                            padding: EdgeInsets.symmetric(
                                horizontal: 30, vertical: 15),
                          ),
                          onPressed: () async {
                            if (_audioBlobUrl != null) {
                              await _processConfirmedAudio();
                            }
                          },
                          child: Text('Confirmar grabación'),
                        ),
                      ],
                    ),
                  ] else ...[
                    CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF00FF7F)),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Procesando audio...',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}
