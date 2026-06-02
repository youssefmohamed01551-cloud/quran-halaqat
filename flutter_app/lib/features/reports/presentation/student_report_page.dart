import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../data/report_repository.dart';

class StudentReportPage extends ConsumerWidget {
  const StudentReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaries = ref.watch(progressSummaryProvider);

    return summaries.when(
      data: (items) {
        if (items.isEmpty) {
          return const Center(child: Text('لا توجد بيانات تقارير بعد'));
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('تقارير الأداء', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: BarChart(
                    BarChartData(
                      barGroups: items.take(6).toList().asMap().entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.avgMasteryPercent,
                              width: 18,
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        );
                      }).toList(),
                      titlesData: const FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: const FlGridData(show: true),
                      borderData: FlBorderData(show: false),
                      maxY: 100,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...items.map(
              (summary) => Card(
                child: ListTile(
                  leading: const Icon(Icons.analytics_outlined),
                  title: Text(summary.fullName),
                  subtitle: Text(
                    'إتقان ${summary.avgMasteryPercent.toStringAsFixed(1)}% • '
                    'حضور ${summary.attendanceLast30Days.toStringAsFixed(1)}% • '
                    '${summary.totalPoints} نقطة',
                  ),
                  trailing: IconButton(
                    tooltip: 'PDF',
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    onPressed: () async {
                      final bytes = await ref.read(reportRepositoryProvider).buildStudentPdf(summary);
                      await Printing.layoutPdf(onLayout: (_) async => bytes);
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
      error: (error, _) => Center(child: Text(error.toString())),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}
