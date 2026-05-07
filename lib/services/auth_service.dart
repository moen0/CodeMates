import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  String? get currentUserEmail => _supabase.auth.currentUser?.email;

  bool get isLoggedIn => _supabase.auth.currentSession != null;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<Profile?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    final userId = response.user?.id;
    if (userId == null) {
      return null;
    }

    await _supabase.from('profiles').upsert({
      'id': userId,
      'display_name': displayName,
      'email': email,
    });

    if (response.session == null) {
      return null;
    }

    final profileMap = await _supabase
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .maybeSingle();

    if (profileMap == null) {
      return null;
    }

    return Profile.fromMap(Map<String, dynamic>.from(profileMap));
  }

  Future<Profile?> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final userId = response.user?.id;
    if (userId == null) {
      return null;
    }

    final profileMap = await _supabase
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .maybeSingle();

    if (profileMap == null) {
      return null;
    }

    return Profile.fromMap(Map<String, dynamic>.from(profileMap));
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
