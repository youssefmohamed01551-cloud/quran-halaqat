import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/di/providers.dart';
import '../../../core/error/app_exception.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(ref.watch(supabaseProvider));
});

class AttendanceRepository {
  const AttendanceRepository(this._client);

  final SupabaseClient _client;

  Future<void> markAttendance({
    required String studentId,
    required String status,
    int minutesLate = 0,
    String? excuseNote,
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

    final circle = enrollment['circles'] as Map<String, dynamic>?;
    final teacherId = (teacher?['id'] as String?) ?? (circle?['teacher_id'] as String?);
    if (teacherId == null) throw const AppException('Teacher id could not be resolved');

    await _client.from('attendance_records').upsert(
      {
        'organization_id': profile['organization_id'],
        'circle_id': enrollment['circle_id'],
        'student_id': studentId,
        'teacher_id': teacherId,
        'attendance_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'status': status,
        'minutes_late': minutesLate,
        'excuse_note': excuseNote,
      },
      onConflict: 'student_id,attendance_date',
    );
  }

  Future<void> saveAccountability({
    required String studentId,
    required Map<String, bool> checks,
    int readingMinutes = 0,
    double dailyPages = 0,
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

    final circle = enrollment['circles'] as Map<String, dynamic>?;
    final teacherId = (teacher?['id'] as String?) ?? (circle?['teacher_id'] as String?);
    if (teacherId == null) throw const AppException('Teacher id could not be resolved');

    await _client.from('daily_accountability').upsert(
      {
        'organization_id': profile['organization_id'],
        'circle_id': enrollment['circle_id'],
        'student_id': studentId,
        'teacher_id': teacherId,
        'record_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'fajr': checks['fajr'] ?? false,
        'dhuhr': checks['dhuhr'] ?? false,
        'asr': checks['asr'] ?? false,
        'maghrib': checks['maghrib'] ?? false,
        'isha': checks['isha'] ?? false,
        'morning_adhkar': checks['morning_adhkar'] ?? false,
        'evening_adhkar': checks['evening_adhkar'] ?? false,
        'honesty': checks['honesty'] ?? false,
        'trustworthiness': checks['trustworthiness'] ?? false,
        'kindness_to_parents': checks['kindness_to_parents'] ?? false,
        'discipline': checks['discipline'] ?? false,
        'teacher_respect': checks['teacher_respect'] ?? false,
        'daily_pages': dailyPages,
        'reading_minutes': readingMinutes,
        'charity': checks['charity'] ?? false,
        'fasting': checks['fasting'] ?? false,
        'helped_others': checks['helped_others'] ?? false,
      },
      onConflict: 'student_id,record_date',
    );
  }
}
