import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/di/providers.dart';
import '../domain/student.dart';

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return StudentRepository(ref.watch(supabaseProvider));
});

final studentsProvider = FutureProvider.autoDispose<List<Student>>((ref) async {
  return ref.watch(studentRepositoryProvider).listStudents();
});

class StudentRepository {
  const StudentRepository(this._client);

  final SupabaseClient _client;

  Future<List<Student>> listStudents({String? search}) async {
    var query = _client.from('students').select(
          'id, full_name, avatar_url, birth_date, level, status, '
          'circle_students!left(circles(name), left_at)',
        );

    if (search != null && search.trim().isNotEmpty) {
      query = query.ilike('full_name', '%${search.trim()}%');
    }

    final data = await query.order('full_name');
    return data.map(Student.fromJson).toList();
  }
}
