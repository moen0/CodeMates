import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/project_member.dart';
import '../models/skill.dart';
import '../models/project.dart';

class ProjectService {
  final supabase = Supabase.instance.client;

  Future<List<Skill>> getSkills() async {
    final response = await supabase.from('skills').select().order('name');
    return response
        .map((row) => Skill.fromMap(Map<String, dynamic>.from(row)))
        .toList();
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

  Future<List<ProjectMember>> getProjectMembers(String projectId) async {
    final response = await supabase
        .from('project_members')
        .select('project_id, user_id, role, joined_at, profiles:user_id(display_name, email)')
        .eq('project_id', projectId);
    return response
        .map((row) => ProjectMember.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }
  Future<List<Project>> getMemberProjects(String userId) async {
    final response = await supabase
        .from('project_members')
        .select('projects(*, profiles:owner_id(display_name, email))')
        .eq('user_id', userId);

    return response
        .map((row) => row['projects'] as Map<String, dynamic>?)
        .whereType<Map<String, dynamic>>()
        .map((map) => Project.fromMap(map))
        .toList();
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

  Future<List<Project>> getOwnedProjects(String userId) async {
    final response = await supabase
        .from('projects')
        .select('id, owner_id, title, description, status, created_at, updated_at')
        .eq('owner_id', userId);
    return response
        .map((row) => Project.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<Map<String, dynamic>?> getProjectByIdWithDetails(String projectId) async {
    final response = await supabase
        .from('projects')
        .select(
          '*, profiles:owner_id(display_name, email), project_skills(*, skills(*)), project_members(*, profiles:user_id(display_name, email))',
        )
        .eq('id', projectId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return Map<String, dynamic>.from(response);
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

  Future<List<Project>> getRecruitingProjects({String? excludeOwnerId}) async {
    var query = supabase
        .from('projects')
        .select('*, profiles:owner_id(display_name, email)')
        .eq('status', 'recruiting');

    if (excludeOwnerId != null) {
      query = query.neq('owner_id', excludeOwnerId);
    }

    final response = await query.order('created_at', ascending: false);
    return response
        .map((row) => Project.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<Map<String, List<Skill>>> getProjectSkillsForProjects(
    List<String> projectIds,
  ) async {
    if (projectIds.isEmpty) {
      return {};
    }

    final response = await supabase
        .from('project_skills')
        .select('project_id, skills(id, name, category)')
        .inFilter('project_id', projectIds);

    final projectSkills = <String, List<Skill>>{};
    for (final row in response) {
      final map = Map<String, dynamic>.from(row);
      final projectId = map['project_id']?.toString();
      final skillMap = map['skills'] as Map<String, dynamic>?;
      if (projectId == null || skillMap == null) {
        continue;
      }

      final skill = Skill.fromMap(skillMap);
      projectSkills.putIfAbsent(projectId, () => <Skill>[]).add(skill);
    }

    return projectSkills;
  }

  Future<void> deleteProject(String projectId) async {
    try {
      final response = await supabase
          .from('projects')
          .delete()
          .eq('id', projectId)
          .select();
      print('Delete response: $response');
    } on PostgrestException catch (e) {
      print('Postgrest error code: ${e.code}');
      print('Postgrest error message: ${e.message}');
      print('Postgrest error details: ${e.details}');
      print('Postgrest error hint: ${e.hint}');
      rethrow;
    } catch (e) {
      print('Other error: $e');
      print('Error type: ${e.runtimeType}');
      rethrow;
    }
  }
}
