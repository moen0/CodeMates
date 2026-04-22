import 'package:supabase_flutter/supabase_flutter.dart';

class ProjectService {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getSkills() async {
    final response = await supabase.from('skills').select().order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> createProject({
    required String title,
    required String description,
    required int maxMembers,
    required String selectedType,
    required String selectedGoal,
    required List<int> selectedSkillIds,
  }) async {
    final userId = supabase.auth.currentUser!.id;

    final project = await supabase
        .from('projects')
        .insert({
          'owner_id': userId,
          'title': title,
          'description': description,
          'max_members': maxMembers,
          'project_type': selectedType,
          'goal': selectedGoal,
        })
        .select('id')
        .single();

    if (selectedSkillIds.isEmpty) {
      return;
    }

    await supabase
        .from('project_skills')
        .insert(
          selectedSkillIds
              .map(
                (skillId) => {'project_id': project['id'], 'skill_id': skillId},
              )
              .toList(),
        );
  }

  Future<List<Map<String, dynamic>>> getProjectMembers(String projectId) async {
    final response = await supabase
        .from('project_members')
        .select('user_id, profiles:user_id(display_name, email)')
        .eq('project_id', projectId);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateProject({
    required String projectId,
    required String title,
    required String description,
    String? meetingLink,
  }) async {
    await supabase.from('projects').update({
      'title': title,
      'description': description,
      'meeting_link': meetingLink?.trim().isEmpty == true ? null : meetingLink?.trim(),
    }).eq('id', projectId);
  }

  String resolveSkillCategory(Map<String, dynamic> skill) {
    final rawCategory =
        skill['category'] ?? skill['type'] ?? skill['group'] ?? skill['area'];
    if (rawCategory is String && rawCategory.trim().isNotEmpty) {
      return _normalizeCategory(rawCategory);
    }

    final name = (skill['name']?.toString() ?? '').toLowerCase();
    if (name.contains('dart') ||
        name.contains('java') ||
        name.contains('python') ||
        name.contains('kotlin') ||
        name.contains('swift') ||
        name.contains('javascript') ||
        name.contains('typescript') ||
        name.contains('c#') ||
        name.contains('go') ||
        name.contains('rust')) {
      return 'language';
    }
    if (name.contains('flutter') ||
        name.contains('react') ||
        name.contains('vue') ||
        name.contains('css') ||
        name.contains('html') ||
        name.contains('tailwind')) {
      return 'frontend';
    }
    if (name.contains('node') ||
        name.contains('spring') ||
        name.contains('api') ||
        name.contains('server') ||
        name.contains('backend')) {
      return 'backend';
    }
    if (name.contains('ml') ||
        name.contains('ai') ||
        name.contains('data') ||
        name.contains('tensorflow') ||
        name.contains('pytorch')) {
      return 'dataAi';
    }
    if (name.contains('docker') ||
        name.contains('kubernetes') ||
        name.contains('ci/cd') ||
        name.contains('devops') ||
        name.contains('terraform')) {
      return 'devops';
    }
    if (name.contains('sql') ||
        name.contains('postgres') ||
        name.contains('mysql') ||
        name.contains('mongodb') ||
        name.contains('database')) {
      return 'database';
    }
    if (name.contains('figma') ||
        name.contains('ux') ||
        name.contains('ui') ||
        name.contains('design')) {
      return 'design';
    }
    if (name.contains('ios') ||
        name.contains('android') ||
        name.contains('mobile') ||
        name.contains('react native')) {
      return 'mobile';
    }

    return 'other';
  }

  String _normalizeCategory(String rawCategory) {
    final value = rawCategory.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    switch (value) {
      case 'language':
      case 'languages':
      case 'programminglanguage':
      case 'programminglanguages':
        return 'language';
      case 'frontend':
      case 'front':
        return 'frontend';
      case 'backend':
      case 'back':
        return 'backend';
      case 'dataai':
      case 'data':
      case 'ai':
      case 'machinelearning':
        return 'dataAi';
      case 'devops':
        return 'devops';
      case 'database':
      case 'databases':
      case 'db':
        return 'database';
      case 'design':
      case 'uxui':
      case 'uiux':
        return 'design';
      case 'mobile':
        return 'mobile';
      default:
        return 'other';
    }
  }
}
