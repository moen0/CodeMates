import 'profile.dart';
import 'project.dart';

class ProjectMember {
  final String projectId;
  final String userId;
  final String role;
  final DateTime joinedAt;
  final Profile? user;
  final Project? project;

  const ProjectMember({
    required this.projectId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.user,
    this.project,
  });

  factory ProjectMember.fromMap(Map<String, dynamic> map) {
    final userMap = map['user'] ?? map['profiles'];
    final projectMap = map['project'] ?? map['projects'];
    return ProjectMember(
      projectId: _stringOrEmpty(map['project_id']),
      userId: _stringOrEmpty(map['user_id']),
      role: _stringOrEmpty(map['role']),
      joinedAt: _parseDate(map['joined_at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      user: userMap is Map<String, dynamic> ? Profile.fromMap(userMap) : null,
      project: projectMap is Map<String, dynamic> ? Project.fromMap(projectMap) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'project_id': projectId,
      'user_id': userId,
      'role': role,
      'joined_at': joinedAt.toIso8601String(),
    };
  }

  ProjectMember copyWith({
    String? projectId,
    String? userId,
    String? role,
    DateTime? joinedAt,
    Profile? user,
    Project? project,
  }) {
    return ProjectMember(
      projectId: projectId ?? this.projectId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      user: user ?? this.user,
      project: project ?? this.project,
    );
  }

  static String _stringOrEmpty(dynamic value) => value?.toString() ?? '';

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

