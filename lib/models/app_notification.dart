class AppNotification {
  final int id;
  final String type;
  final String title;
  final String? body;
  final bool read;
  final int? relatedId;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    this.read = false,
    this.relatedId,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as int,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String?,
      read: json['read'] as bool? ?? false,
      relatedId: json['related_id'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'body': body,
      'read': read,
      'related_id': relatedId,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  bool get isRead => read;
  bool get isUnread => !read;

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      read: read ?? this.read,
      relatedId: relatedId,
      createdAt: createdAt,
    );
  }
}
