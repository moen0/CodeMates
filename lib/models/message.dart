import 'profile.dart';

class Message {
  final String id;
  final String projectId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final Profile? sender;

  const Message({
    required this.id,
    required this.projectId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.sender,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    final senderMap = map['sender'] ?? map['profiles'];
    return Message(
      id: _stringOrEmpty(map['id']),
      projectId: _stringOrEmpty(map['project_id']),
      senderId: _stringOrEmpty(map['sender_id']),
      content: _stringOrEmpty(map['content']),
      createdAt: _parseDate(map['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      sender: senderMap is Map<String, dynamic> ? Profile.fromMap(senderMap) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'sender_id': senderId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Message copyWith({
    String? id,
    String? projectId,
    String? senderId,
    String? content,
    DateTime? createdAt,
    Profile? sender,
  }) {
    return Message(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      sender: sender ?? this.sender,
    );
  }

  static String _stringOrEmpty(dynamic value) => value?.toString() ?? '';

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

