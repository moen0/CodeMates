import 'skill.dart';

class UserSkill {
  final String userId;
  final String skillId;
  final String proficiency;
  final Skill? skill;

  const UserSkill({
    required this.userId,
    required this.skillId,
    required this.proficiency,
    this.skill,
  });

  factory UserSkill.fromMap(Map<String, dynamic> map) {
    final skillMap = map['skill'] ?? map['skills'];
    return UserSkill(
      userId: _stringOrEmpty(map['user_id']),
      skillId: _stringOrEmpty(map['skill_id']),
      proficiency: _stringOrEmpty(map['proficiency']),
      skill: skillMap is Map<String, dynamic> ? Skill.fromMap(skillMap) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'skill_id': skillId,
      'proficiency': proficiency,
    };
  }

  UserSkill copyWith({
    String? userId,
    String? skillId,
    String? proficiency,
    Skill? skill,
  }) {
    return UserSkill(
      userId: userId ?? this.userId,
      skillId: skillId ?? this.skillId,
      proficiency: proficiency ?? this.proficiency,
      skill: skill ?? this.skill,
    );
  }

  static String _stringOrEmpty(dynamic value) => value?.toString() ?? '';
}
