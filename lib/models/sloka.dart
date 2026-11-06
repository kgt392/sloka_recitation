class Sloka {
  final String id;
  final String title;
  final String text;
  final String? audioPath;
  final DateTime createdAt;

  Sloka({
    required this.id,
    required this.title,
    required this.text,
    this.audioPath,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get hasAudio => audioPath != null && audioPath!.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'text': text,
        'audioPath': audioPath,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Sloka.fromJson(Map<String, dynamic> json) => Sloka(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? 'Untitled Sloka',
        text: json['text'] as String? ?? '',
        audioPath: json['audioPath'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );

  Sloka copyWith({
    String? id,
    String? title,
    String? text,
    String? audioPath,
    bool clearAudio = false,
    DateTime? createdAt,
  }) {
    return Sloka(
      id: id ?? this.id,
      title: title ?? this.title,
      text: text ?? this.text,
      audioPath: clearAudio ? null : (audioPath ?? this.audioPath),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
