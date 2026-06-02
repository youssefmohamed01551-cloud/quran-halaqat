import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/di/providers.dart';
import '../../../core/error/app_exception.dart';
import '../domain/memorization_record.dart';

final memorizationRepositoryProvider = Provider<MemorizationRepository>((ref) {
  return MemorizationRepository(ref.watch(supabaseProvider));
});

final recentMemorizationProvider = FutureProvider.autoDispose<List<MemorizationRecord>>((ref) async {
  return ref.watch(memorizationRepositoryProvider).recentRecords();
});

class MemorizationRepository {
  const MemorizationRepository(this._client);

  final SupabaseClient _client;

  Future<List<MemorizationRecord>> recentRecords() async {
    final data = await _client
        .from('daily_memorization_records')
        .select()
        .order('record_date', ascending: false)
        .limit(25);

    return data.map(MemorizationRecord.fromJson).toList();
  }

  Future<void> createRecord({
    required String studentId,
    required String activityType,
    required int surahNumber,
    required int fromAyah,
    required int toAyah,
    required double score,
    int memorizationMistakes = 0,
    int tajweedMistakes = 0,
    int waqfIbtidaMistakes = 0,
    double pageCount = 0,
    String? notes,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AppException('No active session');

    final profile = await _client
        .from('profiles')
        .select('organization_id')
        .eq('id', userId)
        .single();

    final teacher = await _client
        .from('teachers')
        .select('id')
        .eq('profile_id', userId)
        .maybeSingle();

    final enrollment = await _client
        .from('circle_students')
        .select('circle_id, circles(teacher_id)')
        .eq('student_id', studentId)
        .isFilter('left_at', null)
        .single();

    final totalMistakes = memorizationMistakes + tajweedMistakes + waqfIbtidaMistakes;
    final circle = enrollment['circles'] as Map<String, dynamic>?;
    final teacherId = (teacher?['id'] as String?) ?? (circle?['teacher_id'] as String?);
    if (teacherId == null) {
      throw const AppException('Teacher id could not be resolved for this record');
    }

    await _client.from('daily_memorization_records').insert({
      'organization_id': profile['organization_id'],
      'circle_id': enrollment['circle_id'],
      'student_id': studentId,
      'teacher_id': teacherId,
      'record_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'activity_type': activityType,
      'surah_number': surahNumber,
      'from_ayah': fromAyah,
      'to_ayah': toAyah,
      'page_count': pageCount,
      'total_mistakes': totalMistakes,
      'memorization_mistakes': memorizationMistakes,
      'tajweed_mistakes': tajweedMistakes,
      'waqf_ibtida_mistakes': waqfIbtidaMistakes,
      'teacher_notes': notes,
      'score': score,
      'created_by': userId,
    });
  }
}
