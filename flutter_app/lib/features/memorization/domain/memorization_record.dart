class MemorizationRecord {
  const MemorizationRecord({
    required this.id,
    required this.studentId,
    required this.recordDate,
    required this.activityType,
    required this.surahNumber,
    required this.fromAyah,
    required this.toAyah,
    required this.score,
    required this.masteryPercent,
    this.teacherNotes,
  });

  final String id;
  final String studentId;
  final DateTime recordDate;
  final String activityType;
  final int surahNumber;
  final int fromAyah;
  final int toAyah;
  final double score;
  final double masteryPercent;
  final String? teacherNotes;

  factory MemorizationRecord.fromJson(Map<String, dynamic> json) {
    return MemorizationRecord(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      recordDate: DateTime.parse(json['record_date'] as String),
      activityType: json['activity_type'] as String,
      surahNumber: json['surah_number'] as int,
      fromAyah: json['from_ayah'] as int,
      toAyah: json['to_ayah'] as int,
      score: NumberParser.doubleValue(json['score']),
      masteryPercent: NumberParser.doubleValue(json['mastery_percent']),
      teacherNotes: json['teacher_notes'] as String?,
    );
  }
}

class NumberParser {
  const NumberParser._();

  static double doubleValue(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.parse(value);
    return 0;
  }
}
