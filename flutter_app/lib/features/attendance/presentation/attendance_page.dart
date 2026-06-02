import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../students/data/student_repository.dart';
import '../data/attendance_repository.dart';

class AttendancePage extends ConsumerStatefulWidget {
  const AttendancePage({super.key});

  @override
  ConsumerState<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends ConsumerState<AttendancePage> {
  String? _studentId;
  String _status = 'present';
  bool _saving = false;
  final Map<String, bool> _checks = {
    'fajr': false,
    'dhuhr': false,
    'asr': false,
    'maghrib': false,
    'isha': false,
    'morning_adhkar': false,
    'evening_adhkar': false,
    'honesty': false,
    'trustworthiness': false,
    'kindness_to_parents': false,
    'discipline': false,
    'teacher_respect': false,
    'charity': false,
    'fasting': false,
    'helped_others': false,
  };

  @override
  Widget build(BuildContext context) {
    final students = ref.watch(studentsProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('الحضور والمحاسبة اليومية', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                students.when(
                  data: (items) => DropdownButtonFormField<String>(
                    value: _studentId,
                    decoration: const InputDecoration(
                      labelText: 'الطالب',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    items: items
                        .map(
                          (student) => DropdownMenuItem(
                            value: student.id,
                            child: Text(student.fullName),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _studentId = value),
                  ),
                  error: (error, _) => Text(error.toString()),
                  loading: () => const LinearProgressIndicator(),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'present', icon: Icon(Icons.check), label: Text('حاضر')),
                      ButtonSegment(value: 'late', icon: Icon(Icons.schedule), label: Text('متأخر')),
                      ButtonSegment(value: 'absent', icon: Icon(Icons.close), label: Text('غائب')),
                      ButtonSegment(value: 'excused_absent', icon: Icon(Icons.info_outline), label: Text('بعذر')),
                    ],
                    selected: {_status},
                    onSelectionChanged: (value) => setState(() => _status = value.first),
                  ),
                ),
                const SizedBox(height: 20),
                Text('الصلوات', style: Theme.of(context).textTheme.titleMedium),
                _CheckWrap(
                  checks: _checks,
                  keysAndLabels: const {
                    'fajr': 'الفجر',
                    'dhuhr': 'الظهر',
                    'asr': 'العصر',
                    'maghrib': 'المغرب',
                    'isha': 'العشاء',
                  },
                  onChanged: _setCheck,
                ),
                const SizedBox(height: 12),
                Text('الأذكار والسلوك', style: Theme.of(context).textTheme.titleMedium),
                _CheckWrap(
                  checks: _checks,
                  keysAndLabels: const {
                    'morning_adhkar': 'أذكار الصباح',
                    'evening_adhkar': 'أذكار المساء',
                    'honesty': 'الصدق',
                    'trustworthiness': 'الأمانة',
                    'kindness_to_parents': 'بر الوالدين',
                    'discipline': 'الانضباط',
                    'teacher_respect': 'احترام المعلم',
                  },
                  onChanged: _setCheck,
                ),
                const SizedBox(height: 12),
                Text('الأعمال الصالحة', style: Theme.of(context).textTheme.titleMedium),
                _CheckWrap(
                  checks: _checks,
                  keysAndLabels: const {
                    'charity': 'صدقة',
                    'fasting': 'صيام',
                    'helped_others': 'مساعدة الآخرين',
                  },
                  onChanged: _setCheck,
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FilledButton.icon(
                    onPressed: _saving || _studentId == null ? null : _save,
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_rounded),
                    label: const Text('حفظ المتابعة'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _setCheck(String key, bool value) {
    setState(() => _checks[key] = value);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final repo = ref.read(attendanceRepositoryProvider);
      await repo.markAttendance(studentId: _studentId!, status: _status);
      await repo.saveAccountability(studentId: _studentId!, checks: _checks);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ الحضور والمحاسبة')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _CheckWrap extends StatelessWidget {
  const _CheckWrap({
    required this.checks,
    required this.keysAndLabels,
    required this.onChanged,
  });

  final Map<String, bool> checks;
  final Map<String, String> keysAndLabels;
  final void Function(String key, bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: keysAndLabels.entries
          .map(
            (entry) => FilterChip(
              selected: checks[entry.key] ?? false,
              avatar: Icon((checks[entry.key] ?? false) ? Icons.check_circle : Icons.circle_outlined),
              label: Text(entry.value),
              onSelected: (value) => onChanged(entry.key, value),
            ),
          )
          .toList(),
    );
  }
}
