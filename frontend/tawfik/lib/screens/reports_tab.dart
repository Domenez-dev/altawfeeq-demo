import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../models/api/models.dart';
import '../providers/reports_provider.dart';
import '../widgets/error_retry.dart';

class ReportsTab extends ConsumerWidget {
  const ReportsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(reportPeriodProvider);
    final reportAsync = ref.watch(reportProvider);
    final periodLabels = ['أسبوعي', 'شهري', 'كل الفترة'];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: const Text('التقارير', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontFamily: 'IBMPlexSansArabic', fontSize: 20)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Period tabs
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.border.withOpacity(0.3)),
              ),
              child: Row(
                children: List.generate(3, (i) => Expanded(
                  child: GestureDetector(
                    onTap: () => ref.read(reportPeriodProvider.notifier).state = i,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: period == i ? AppTheme.primaryPurple : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        periodLabels[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: period == i ? Colors.white : AppTheme.textSecondary,
                          fontWeight: period == i ? FontWeight.bold : FontWeight.normal,
                          fontFamily: 'IBMPlexSansArabic',
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                )),
              ),
            ),

            const SizedBox(height: 24),

            // Week navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, size: 16), onPressed: () {}),
                const Text('هذا الأسبوع', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'IBMPlexSansArabic')),
                IconButton(icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16), onPressed: () {}),
              ],
            ),

            const SizedBox(height: 16),

            reportAsync.when(
              loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
              error: (e, _) => SizedBox(
                height: 280,
                child: ErrorRetryView(error: e, onRetry: () => ref.invalidate(reportProvider)),
              ),
              data: (report) => _ReportContent(report: report),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _ReportContent extends StatelessWidget {
  final WeeklyReport report;
  const _ReportContent({required this.report});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Line chart card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('متوسط التقدم', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontFamily: 'IBMPlexSansArabic')),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${(report.averagePercent * 100).toInt()}%',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontFamily: 'IBMPlexSansArabic'),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '+${(report.comparedToLastWeek * 100).toInt()}% عن الأسبوع الماضي',
                    style: TextStyle(fontSize: 12, color: AppTheme.success, fontWeight: FontWeight.w600, fontFamily: 'IBMPlexSansArabic'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 150,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (report.chartData.length - 1).toDouble(),
                    minY: 0,
                    maxY: 100,
                    lineBarsData: [
                      LineChartBarData(
                        spots: report.chartData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                        isCurved: true,
                        color: AppTheme.primaryPurple,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: true, color: AppTheme.primaryPurple.withOpacity(0.1)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Donut chart card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('توزيع المؤشرات', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontFamily: 'IBMPlexSansArabic')),
              const SizedBox(height: 20),
              Row(
                children: [
                  SizedBox(
                    height: 100,
                    width: 100,
                    child: Stack(
                      children: [
                        PieChart(PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 30,
                          sections: [
                            PieChartSectionData(color: AppTheme.success, value: report.goodCount.toDouble(), title: '', radius: 15),
                            PieChartSectionData(color: AppTheme.warning, value: report.averageCount.toDouble(), title: '', radius: 15),
                            PieChartSectionData(color: AppTheme.error, value: report.weakCount.toDouble(), title: '', radius: 15),
                          ],
                        )),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('${(report.averagePercent * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              Text('متوسط', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: Column(
                      children: [
                        _LegendItem(color: AppTheme.success, label: 'جيد', count: report.goodCount),
                        const SizedBox(height: 12),
                        _LegendItem(color: AppTheme.warning, label: 'متوسط', count: report.averageCount),
                        const SizedBox(height: 12),
                        _LegendItem(color: AppTheme.error, label: 'ضعيف', count: report.weakCount),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Sessions count card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('عدد الجلسات', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'IBMPlexSansArabic')),
                  const SizedBox(height: 4),
                  Text('جلسات', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary, fontFamily: 'IBMPlexSansArabic')),
                ],
              ),
              Text(report.sessionsCount.toString(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'IBMPlexSansArabic')),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  const _LegendItem({required this.color, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 14, fontFamily: 'IBMPlexSansArabic')),
        ]),
        Text(count.toString(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'IBMPlexSansArabic')),
      ],
    );
  }
}
