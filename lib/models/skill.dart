class Skill {
  final String id;
  final String name;
  final String? category;

  const Skill({
    required this.id,
    required this.name,
    this.category,
  });

  factory Skill.fromMap(Map<String, dynamic> map) {
    return Skill(
      id: _stringOrEmpty(map['id']),
      name: _stringOrEmpty(map['name']),
      category: _nullableString(map['category']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
    };
  }

  Skill copyWith({
    String? id,
    String? name,
    String? category,
  }) {
    return Skill(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
    );
  }

  static String _stringOrEmpty(dynamic value) => value?.toString() ?? '';

  static String? _nullableString(dynamic value) {
    final text = value?.toString();
    return (text == null || text.isEmpty) ? null : text;
  }
}

