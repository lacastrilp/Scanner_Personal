class CVSection {
  final String id;
  final String title;
  final String description;
  final List<String> fields;
  String? audioUrl;
  String? transcription;
  bool isCompleted = false;

  CVSection({
    required this.id,
    required this.title,
    required this.description,
    required this.fields,
    this.audioUrl,
    this.transcription,
  });
}