import 'package:supabase_flutter/supabase_flutter.dart';

class MatchResult {
  const MatchResult({required this.scores, required this.userHasSkills});

  final Map<String, int> scores;
  final bool userHasSkills;
}

class MatchingService {
  final _supabase = Supabase.instance.client;

  // Beregn match  mot ett prosjekt
  Future<int> calculateMatch(String userId, String projectId) async {
    final userSkillWeights = await _getUserSkillWeights(userId);
    final projectSkillIds = await _getProjectSkillIds(projectId);
    return _calculateScore(userSkillWeights, projectSkillIds);
  }

  // Beregn match mot flere prosjekter i ett kall
  Future<MatchResult> calculateMatchesForUser(
    String userId,
    List<String> projectIds,
  ) async {
    if (projectIds.isEmpty) {
      final userSkillWeights = await _getUserSkillWeights(userId);
      return MatchResult(
        scores: const <String, int>{},
        userHasSkills: userSkillWeights.isNotEmpty,
      );
    }

    final userSkillWeights = await _getUserSkillWeights(userId);
    final userHasSkills = userSkillWeights.isNotEmpty;

    final response = await _supabase
        .from('project_skills')
        .select('project_id, skill_id')
        .inFilter('project_id', projectIds);

    final projectSkillMap = <String, List<int>>{};
    for (final row in response) {
      final map = Map<String, dynamic>.from(row);
      final projectId = map['project_id']?.toString();
      final skillId = map['skill_id'] as int?;
      if (projectId == null || skillId == null) {
        continue;
      }

      projectSkillMap.putIfAbsent(projectId, () => <int>[]).add(skillId);
    }

    final scores = <String, int>{};
    for (final projectId in projectIds) {
      final skillIds = projectSkillMap[projectId] ?? <int>[];
      scores[projectId] = _calculateScore(userSkillWeights, skillIds);
    }

    return MatchResult(scores: scores, userHasSkills: userHasSkills);
  }

  // Hent brukerens skills med proficiency-vekt
  Future<Map<int, double>> _getUserSkillWeights(String userId) async {
    final response = await _supabase
        .from('user_skills')
        .select('skill_id, proficiency')
        .eq('user_id', userId);

    final weights = <int, double>{};
    for (final row in response) {
      final map = Map<String, dynamic>.from(row);
      final rawSkillId = map['skill_id'];
      final skillId = _toInt(rawSkillId);
      if (skillId == null) {
        continue;
      }

      final weight = _proficiencyWeight(map['proficiency']?.toString());
      // Hvis duplikat finnes, behold høyeste nivå
      final existing = weights[skillId];
      if (existing == null || weight > existing) {
        weights[skillId] = weight;
      }
    }

    return weights;
  }

  // Hent prosjektets ønskede ferdigheter
  Future<List<int>> _getProjectSkillIds(String projectId) async {
    final response = await _supabase
        .from('project_skills')
        .select('skill_id')
        .eq('project_id', projectId);

    final skillIds = <int>[];
    for (final row in response) {
      final map = Map<String, dynamic>.from(row);
      final skillId = _toInt(map['skill_id']);
      if (skillId != null) {
        skillIds.add(skillId);
      }
    }

    return skillIds;
  }

  int _calculateScore(Map<int, double> userSkillWeights, List<int> projectSkillIds) {
    if (projectSkillIds.isEmpty) {
      return 100;
    }

    if (userSkillWeights.isEmpty) {
      return 0;
    }

    final uniqueProjectSkills = projectSkillIds.toSet();
    var matchedWeightSum = 0.0;

    for (final skillId in uniqueProjectSkills) {
      matchedWeightSum += userSkillWeights[skillId] ?? 0.0;
    }

    final score = matchedWeightSum / uniqueProjectSkills.length;
    return (score * 100).round().clamp(0, 100);
  }

  double _proficiencyWeight(String? proficiency) {
    switch (proficiency) {
      case 'advanced':
        return 1.0;
      case 'intermediate':
        return 0.6;
      default:
        return 0.3;
    }
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

}

