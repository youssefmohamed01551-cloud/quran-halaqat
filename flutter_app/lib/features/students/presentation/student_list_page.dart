import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../data/student_repository.dart';

class StudentListPage extends ConsumerWidget {
  const StudentListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(studentsProvider);
    final strings = AppStrings.of(context);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(studentsProvider),
      child: students.when(
        data: (items) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: strings.search,
                prefixIcon: const Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 16),
            ...items.map(
              (student) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: student.avatarUrl == null ? null : NetworkImage(student.avatarUrl!),
                    child: student.avatarUrl == null ? const Icon(Icons.person_outline) : null,
                  ),
                  title: Text(student.fullName),
                  subtitle: Text('${student.circleName ?? '-'} • ${student.level} • ${student.status}'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
              ),
            ),
          ],
        ),
        error: (error, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [Text(error.toString())],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
