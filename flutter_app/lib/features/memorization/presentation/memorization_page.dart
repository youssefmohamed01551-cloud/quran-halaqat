import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../../students/data/student_repository.dart';
import '../data/memorization_repository.dart';

class MemorizationPage extends ConsumerStatefulWidget {
  const MemorizationPage({super.key});

  @override
  ConsumerState<MemorizationPage> createState() => _MemorizationPageState();
}

class _MemorizationPageState extends ConsumerState<MemorizationPage> {
  final _formKey = GlobalKey<FormState>();
  final _fromAyah = TextEditingController(text: '1');
  final _toAyah = TextEditingController(text: '5');
  final _score = TextEditingController(text: '9');
  final _mistakes = TextEditingController(text: '0');
  final _notes = TextEditingController();
  String? _studentId;
  String _activityType = 'new_memorization';
  int _surahNumber = 1;
  bool _saving = false;

  @override
  void dispose() {
    _fromAyah.dispose();
    _toAyah.dispose();
    _score.dispose();
    _mistakes.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final students = ref.watch(studentsProvider);
    final recent = ref.watch(recentMemorizationProvider);
    final strings = AppStrings.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    strings.memorization,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
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
                      validator: (value) => value == null ? 'اختر الطالب' : null,
                    ),
                    error: (error, _) => Text(error.toString()),
                    loading: () => const LinearProgressIndicator(),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: 220,
                        child: DropdownButtonFormField<String>(
                          value: _activityType,
                          decoration: const InputDecoration(labelText: 'نوع البيان'),
                          items: const [
                            DropdownMenuItem(value: 'new_memorization', child: Text('حفظ جديد')),
                            DropdownMenuItem(value: 'review', child: Text('مراجعة')),
                            DropdownMenuItem(value: 'test', child: Text('اختبار')),
                          ],
                          onChanged: (value) => setState(() => _activityType = value!),
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        child: DropdownButtonFormField<int>(
                          value: _surahNumber,
                          decoration: const InputDecoration(labelText: 'السورة'),
                          items: List.generate(
                            114,
                            (index) => DropdownMenuItem(
                              value: index + 1,
                              child: Text('سورة ${index + 1}'),
                            ),
                          ),
                          onChanged: (value) => setState(() => _surahNumber = value!),
                        ),
                      ),
                      _NumberField(controller: _fromAyah, label: 'من آية'),
                      _NumberField(controller: _toAyah, label: 'إلى آية'),
                      _NumberField(controller: _score, label: 'الدرجة من 10'),
                      _NumberField(controller: _mistakes, label: 'الأخطاء'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notes,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات المعلم',
                      prefixIcon: Icon(Icons.edit_note_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(strings.save),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('آخر السجلات', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        recent.when(
          data: (records) => Column(
            children: records
                .map(
                  (record) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.menu_book_rounded),
                      title: Text('سورة ${record.surahNumber}: ${record.fromAyah}-${record.toAyah}'),
                      subtitle: Text('${record.activityType} • إتقان ${record.masteryPercent}%'),
                      trailing: Text(record.score.toStringAsFixed(1)),
                    ),
                  ),
                )
                .toList(),
          ),
          error: (error, _) => Text(error.toString()),
          loading: () => const LinearProgressIndicator(),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(memorizationRepositoryProvider).createRecord(
            studentId: _studentId!,
            activityType: _activityType,
            surahNumber: _surahNumber,
            fromAyah: int.parse(_fromAyah.text),
            toAyah: int.parse(_toAyah.text),
            score: double.parse(_score.text),
            memorizationMistakes: int.parse(_mistakes.text),
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          );
      ref.invalidate(recentMemorizationProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ سجل الحفظ')),
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

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          if (value == null || value.isEmpty) return label;
          if (num.tryParse(value) == null) return 'رقم غير صالح';
          return null;
        },
      ),
    );
  }
}
