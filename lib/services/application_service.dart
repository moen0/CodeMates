import 'package:supabase_flutter/supabase_flutter.dart';

class ApplicationService {
  final supabase = Supabase.instance.client;

  // Send søknad
  Future<void> apply(String projectId, String message) async {
    final userId = supabase.auth.currentUser!.id;

    await supabase.from('applications').insert({
      'project_id': projectId,
      'applicant_id': userId,
      'message': message,
    });
  }

  Future<List<Map<String, dynamic>>> getProjectApplications(String projectId) async {
    final response = await supabase
        .from('applications')
        .select('*, profiles:applicant_id(display_name, email, bio)')
        .eq('project_id', projectId)
        .eq('status', 'pending');
    return List<Map<String, dynamic>>.from(response);
  }

  // Hent mine sendte søknader
  Future<List<Map<String, dynamic>>> getMyApplications() async {
    final userId = supabase.auth.currentUser!.id;
    final response = await supabase
        .from('applications')
        .select('*, projects:project_id(title, status)')
        .eq('applicant_id', userId);
    return List<Map<String, dynamic>>.from(response);
  }

  // Godkjenn søknad
  Future<void> accept(String applicationId, String projectId, String applicantId) async {
    // Oppdater søknadsstatus
    await supabase
        .from('applications')
        .update({'status': 'accepted'})
        .eq('id', applicationId);

    // Legg til som medlem
    await supabase.from('project_members').insert({
      'project_id': projectId,
      'user_id': applicantId,
    });

    // Sjekk om prosjektet er fullt
    await _checkAndUpdateStatus(projectId);
  }

  // Avslå søknad
  Future<void> reject(String applicationId) async {
    await supabase
        .from('applications')
        .update({'status': 'rejected'})
        .eq('id', applicationId);
  }

  // Sjekk om prosjektet er fullt, oppdater status
  Future<void> _checkAndUpdateStatus(String projectId) async {
    final project = await supabase
        .from('projects')
        .select('max_members')
        .eq('id', projectId)
        .single();

    final members = await supabase
        .from('project_members')
        .select('user_id')
        .eq('project_id', projectId);

    // +1 for eieren som ikke er i project_members
    if (members.length + 1 >= project['max_members']) {
      await supabase
          .from('projects')
          .update({'status': 'active'})
          .eq('id', projectId);
    }
  }
}