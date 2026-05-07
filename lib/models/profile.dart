class Profile {
  final String id;
  final String displayName;
  final String email;
  final String? bio;
  final String? avatarUrl;
  final DateTime? createdAt;
  final String? university;
  final String? studyProgram;
  final int? year;
  final String? githubUrl;
  final String? linkedinUrl;
  final String? websiteUrl;
  final bool? availability;

  const Profile({
    required this.id,
    required this.displayName,
    required this.email,
    this.bio,
    this.avatarUrl,
    this.createdAt,
    this.university,
    this.studyProgram,
    this.year,
    this.githubUrl,
    this.linkedinUrl,
    this.websiteUrl,
    this.availability,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: _stringOrEmpty(map['id']),
      displayName: _stringOrEmpty(map['display_name']),
      email: _stringOrEmpty(map['email']),
      bio: _nullableString(map['bio']),
      avatarUrl: _nullableString(map['avatar_url']),
      createdAt: _parseDate(map['created_at']),
      university: _nullableString(map['university']),
      studyProgram: _nullableString(map['study_program']),
      year: _parseInt(map['year']),
      githubUrl: _nullableString(map['github_url']),
      linkedinUrl: _nullableString(map['linkedin_url']),
      websiteUrl: _nullableString(map['website_url']),
      availability: _parseBool(map['availability']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'display_name': displayName,
      'email': email,
      'bio': bio,
      'avatar_url': avatarUrl,
      'created_at': createdAt?.toIso8601String(),
      'university': university,
      'study_program': studyProgram,
      'year': year,
      'github_url': githubUrl,
      'linkedin_url': linkedinUrl,
      'website_url': websiteUrl,
      'availability': availability,
    };
  }

  Profile copyWith({
    String? id,
    String? displayName,
    String? email,
    String? bio,
    String? avatarUrl,
    DateTime? createdAt,
    String? university,
    String? studyProgram,
    int? year,
    String? githubUrl,
    String? linkedinUrl,
    String? websiteUrl,
    bool? availability,
  }) {
    return Profile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      university: university ?? this.university,
      studyProgram: studyProgram ?? this.studyProgram,
      year: year ?? this.year,
      githubUrl: githubUrl ?? this.githubUrl,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      availability: availability ?? this.availability,
    );
  }

  String get displayLabel {
    if (displayName.trim().isNotEmpty) return displayName;
    if (email.trim().isNotEmpty) return email;
    return 'Ukjent';
  }

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

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static bool? _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().trim().toLowerCase();
    if (text == null || text.isEmpty) return null;
    return text == 'true' || text == '1' || text == 'yes';
  }
}
