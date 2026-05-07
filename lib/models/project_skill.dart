import 'skill.dart';

class ProjectSkill {
  final String projectId;
  final String skillId;
  final bool required;
  final Skill? skill;

  const ProjectSkill({
    required this.projectId,
    required this.skillId,
    required this.required,
    this.skill,
  });

  factory ProjectSkill.fromMap(Map<String, dynamic> map) {
    final skillMap = map['skill'] ?? map['skills'];
    return ProjectSkill(
      projectId: _stringOrEmpty(map['project_id']),
      skillId: _stringOrEmpty(map['skill_id']),
      required: _parseBool(map['required']),
      skill: skillMap is Map<String, dynamic> ? Skill.fromMap(skillMap) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'project_id': projectId,
      'skill_id': skillId,
      'required': required,
    };
  }

  ProjectSkill copyWith({
    String? projectId,
    String? skillId,
    bool? required,
    Skill? skill,
  }) {
    return ProjectSkill(
      projectId: projectId ?? this.projectId,
      skillId: skillId ?? this.skillId,
      required: required ?? this.required,
      skill: skill ?? this.skill,
    );
  }

  static String _stringOrEmpty(dynamic value) => value?.toString() ?? '';

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().toLowerCase();
    return text == 'true' || text == '1';
  }
}

