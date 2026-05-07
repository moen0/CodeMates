import 'profile.dart';
import 'project_skill.dart';

class Project {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Profile? owner;
  final List<ProjectSkill>? skills;
  final int? maxMembers;
  final String? meetingLink;
  final String? projectType;
  final String? goal;

  const Project({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.owner,
    this.skills,
    this.maxMembers,
    this.meetingLink,
    this.projectType,
    this.goal,
  });

  factory Project.fromMap(Map<String, dynamic> map) {
    final ownerMap = map['owner'] ?? map['profiles'];
    final skillsMap = map['skills'] ?? map['project_skills'];
    return Project(
      id: _stringOrEmpty(map['id']),
      ownerId: _stringOrEmpty(map['owner_id']),
      title: _stringOrEmpty(map['title']),
      description: _stringOrEmpty(map['description']),
      status: _stringOrEmpty(map['status']),
      createdAt: _parseDate(map['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: _parseDate(map['updated_at']),
      owner: ownerMap is Map<String, dynamic> ? Profile.fromMap(ownerMap) : null,
      skills: skillsMap is List
          ? skillsMap
              .whereType<Map<String, dynamic>>()
              .map(ProjectSkill.fromMap)
              .toList()
          : null,
      maxMembers: _parseInt(map['max_members']),
      meetingLink: _nullableString(map['meeting_link']),
      projectType: _nullableString(map['project_type']),
      goal: _nullableString(map['goal']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'owner_id': ownerId,
      'title': title,
      'description': description,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'max_members': maxMembers,
      'meeting_link': meetingLink,
      'project_type': projectType,
      'goal': goal,
    };
  }

  Project copyWith({
    String? id,
    String? ownerId,
    String? title,
    String? description,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Profile? owner,
    List<ProjectSkill>? skills,
    int? maxMembers,
    String? meetingLink,
    String? projectType,
    String? goal,
  }) {
    return Project(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      owner: owner ?? this.owner,
      skills: skills ?? this.skills,
      maxMembers: maxMembers ?? this.maxMembers,
      meetingLink: meetingLink ?? this.meetingLink,
      projectType: projectType ?? this.projectType,
      goal: goal ?? this.goal,
    );
  }

  bool get isOpen => status == 'open';
  bool get isClosed => status == 'closed';
  bool get isCompleted => status == 'completed';

  static String _stringOrEmpty(dynamic value) => value?.toString() ?? '';

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString();
    return (text == null || text.isEmpty) ? null : text;
  }
}

