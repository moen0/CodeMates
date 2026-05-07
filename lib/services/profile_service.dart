import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

import '../models/profile.dart';
import '../models/skill.dart';
import '../models/user_skill.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Profile?> getProfile(String userId) async {
    final response = await _supabase
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return Profile.fromMap(Map<String, dynamic>.from(response));
  }

  Future<Profile?> getCurrentProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return null;
    }

    return getProfile(userId);
  }

  Future<void> updateProfile(Profile profile) async {
    await _supabase.from('profiles').upsert(profile.toMap());
  }

  Future<List<UserSkill>> getUserSkills(String userId) async {
    final response = await _supabase
        .from('user_skills')
        .select('*, skills(*)')
        .eq('user_id', userId);

    return response
        .map((row) => UserSkill.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> addUserSkill({
    required String userId,
    required String skillId,
    required String proficiency,
  }) async {
    await _supabase.from('user_skills').insert({
      'user_id': userId,
      'skill_id': skillId,
      'proficiency': proficiency,
    });
  }

  Future<void> removeUserSkill({
    required String userId,
    required String skillId,
  }) async {
    await _supabase
        .from('user_skills')
        .delete()
        .eq('user_id', userId)
        .eq('skill_id', skillId);
  }

  Future<void> updateUserSkillProficiency({
    required String userId,
    required String skillId,
    required String proficiency,
  }) async {
    await _supabase
        .from('user_skills')
        .update({'proficiency': proficiency})
        .eq('user_id', userId)
        .eq('skill_id', skillId);
  }

  Future<List<Skill>> getAllSkills() async {
    final response = await _supabase.from('skills').select().order('name');

    return response
        .map((row) => Skill.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<int> getOwnedProjectsCount(String userId) async {
    final response = await _supabase
        .from('projects')
        .select('id')
        .eq('owner_id', userId);
    return response.length;
  }

  Future<int> getMemberProjectsCount(String userId) async {
    final response = await _supabase
        .from('project_members')
        .select('project_id')
        .eq('user_id', userId);
    return response.length;
  }

  Future<String> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String extension,
  }) async {
    final safeExt = extension.toLowerCase();
    final fileName = 'avatar.$safeExt';
    final storagePath = '$userId/$fileName';

    await _supabase.storage.from('avatars').uploadBinary(
      storagePath,
      bytes,
      fileOptions: const FileOptions(upsert: true),
    );

    final publicUrl =
        _supabase.storage.from('avatars').getPublicUrl(storagePath);
    final bustedUrl = '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';

    await _supabase
        .from('profiles')
        .update({'avatar_url': bustedUrl})
        .eq('id', userId);

    return bustedUrl;
  }

  Future<void> removeAvatar({required String userId}) async {
    final candidates = [
      'avatar.jpg',
      'avatar.jpeg',
      'avatar.png',
      'avatar.webp',
    ];

    for (final candidate in candidates) {
      try {
        await _supabase.storage
            .from('avatars')
            .remove(['$userId/$candidate']);
      } catch (_) {
        // Ignore individual failures.
      }
    }

    await _supabase
        .from('profiles')
        .update({'avatar_url': null})
        .eq('id', userId);
  }

  Future<void> clearUserSkills(String userId) async {
    await _supabase.from('user_skills').delete().eq('user_id', userId);
  }
}
