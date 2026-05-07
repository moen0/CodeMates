import 'profile.dart';
import 'project.dart';

class Application {
  final String id;
  final String projectId;
  final String applicantId;
  final String? message;
  final String status;
  final DateTime createdAt;
  final Profile? applicant;
  final Project? project;

  const Application({
    required this.id,
    required this.projectId,
    required this.applicantId,
    required this.status,
    required this.createdAt,
    this.message,
    this.applicant,
    this.project,
  });

  factory Application.fromMap(Map<String, dynamic> map) {
    final applicantMap = map['applicant'] ?? map['profiles'];
    final projectMap = map['project'] ?? map['projects'];
    return Application(
      id: _stringOrEmpty(map['id']),
      projectId: _stringOrEmpty(map['project_id']),
      applicantId: _stringOrEmpty(map['applicant_id']),
      message: _nullableString(map['message']),
      status: _stringOrEmpty(map['status']),
      createdAt: _parseDate(map['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      applicant: applicantMap is Map<String, dynamic> ? Profile.fromMap(applicantMap) : null,
      project: projectMap is Map<String, dynamic> ? Project.fromMap(projectMap) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'applicant_id': applicantId,
      'message': message,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Application copyWith({
    String? id,
    String? projectId,
    String? applicantId,
    String? message,
    String? status,
    DateTime? createdAt,
    Profile? applicant,
    Project? project,
  }) {
    return Application(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      applicantId: applicantId ?? this.applicantId,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      applicant: applicant ?? this.applicant,
      project: project ?? this.project,
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';

  static String _stringOrEmpty(dynamic value) => value?.toString() ?? '';

  static String? _nullableString(dynamic value) {
    final text = value?.toString();
    return (text == null || text.isEmpty) ? null : text;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

