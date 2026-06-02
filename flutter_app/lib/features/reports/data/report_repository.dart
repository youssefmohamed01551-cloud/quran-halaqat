import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/di/providers.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(ref.watch(supabaseProvider));
});

final progressSummaryProvider = FutureProvider.autoDispose<List<StudentProgressSummary>>((ref) async {
  return ref.watch(reportRepositoryProvider).loadProgressSummaries();
});

class ReportRepository {
  const ReportRepository(this._client);

  final SupabaseClient _client;

  Future<List<StudentProgressSummary>> loadProgressSummaries() async {
    final data = await _client
        .from('student_progress_summary')
        .select()
        .order('avg_mastery_percent', ascending: false);
    return data.map(StudentProgressSummary.fromJson).toList();
  }

  Future<Uint8List> buildStudentPdf(StudentProgressSummary summary) async {
    final pdf = pw.Document();
    final regularFont = await PdfGoogleFonts.notoNaskhArabicRegular();
    final boldFont = await PdfGoogleFonts.notoNaskhArabicBold();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          textDirection: pw.TextDirection.rtl,
          theme: pw.ThemeData.withFont(
            base: regularFont,
            bold: boldFont,
          ),
        ),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'تقرير متابعة الطالب',
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
              ),
              pw.Container(
                width: 56,
                height: 56,
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.teal),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text('Logo'),
              ),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            children: [
              _row('الاسم', summary.fullName),
              _row('المستوى', summary.level),
              _row('الحالة', summary.status),
              _row('متوسط الإتقان', '${summary.avgMasteryPercent.toStringAsFixed(1)}%'),
              _row('الحضور آخر 30 يوم', '${summary.attendanceLast30Days.toStringAsFixed(1)}%'),
              _row('النقاط', summary.totalPoints.toString()),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Text('ملاحظة المعلم', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text('يوصى بالاستمرار على خطة مراجعة أسبوعية مع اختبار قصير في نهاية كل أسبوع.'),
        ],
      ),
    );

    return pdf.save();
  }

  pw.TableRow _row(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(value),
        ),
      ],
    );
  }
}

class StudentProgressSummary {
  const StudentProgressSummary({
    required this.studentId,
    required this.fullName,
    required this.level,
    required this.status,
    required this.totalPoints,
    required this.avgMasteryPercent,
    required this.memorizationEntries,
    required this.attendanceLast30Days,
  });

  final String studentId;
  final String fullName;
  final String level;
  final String status;
  final int totalPoints;
  final double avgMasteryPercent;
  final int memorizationEntries;
  final double attendanceLast30Days;

  factory StudentProgressSummary.fromJson(Map<String, dynamic> json) {
    return StudentProgressSummary(
      studentId: json['student_id'] as String,
      fullName: json['full_name'] as String,
      level: json['level'] as String,
      status: json['status'] as String,
      totalPoints: (json['total_points'] as num?)?.toInt() ?? 0,
      avgMasteryPercent: (json['avg_mastery_percent'] as num?)?.toDouble() ?? 0,
      memorizationEntries: (json['memorization_entries'] as num?)?.toInt() ?? 0,
      attendanceLast30Days: (json['attendance_last_30_days'] as num?)?.toDouble() ?? 0,
    );
  }
}
