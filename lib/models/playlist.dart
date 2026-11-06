class Playlist {
  final String id;
  final String name;
  final List<String> slokaIds;
  final DateTime createdAt;

  Playlist({
    required this.id,
    required this.name,
    List<String>? slokaIds,
    DateTime? createdAt,
  })  : slokaIds = slokaIds ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slokaIds': slokaIds,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Playlist.fromJson(Map<String, dynamic> json) => Playlist(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Untitled Playlist',
        slokaIds: (json['slokaIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );

  Playlist copyWith({
    String? id,
    String? name,
    List<String>? slokaIds,
    DateTime? createdAt,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      slokaIds: slokaIds ?? this.slokaIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
