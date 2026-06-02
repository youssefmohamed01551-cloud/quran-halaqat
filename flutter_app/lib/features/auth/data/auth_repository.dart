import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/di/providers.dart';
import '../../../core/error/app_exception.dart';
import '../domain/app_profile.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseProvider));
});

final currentProfileProvider = FutureProvider<AppProfile?>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  final user = repo.currentUser;
  if (user == null) return null;
  return repo.fetchCurrentProfile();
});

class AuthRepository {
  const AuthRepository(this._client);

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on AuthException catch (error) {
      throw AppException(error.message, cause: error);
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<AppProfile> fetchCurrentProfile() async {
    final id = currentUser?.id;
    if (id == null) throw const AppException('No active session');

    final data = await _client
        .from('profiles')
        .select('id, organization_id, role, full_name, avatar_url, email, is_active')
        .eq('id', id)
        .single();

    return AppProfile.fromJson(data);
  }
}
