import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../providers/indicator_detail_provider.dart';
import '../utils/indicator_helpers.dart';
import '../widgets/error_retry.dart';

class IndicatorDetailsScreen extends ConsumerWidget {
  const IndicatorDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndicator = ref.watch(selectedIndicatorProvider);
    final detailAsync = ref.watch(indicatorDetailProvider);

    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        backgroundColor: context.appColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.appColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'تفاصيل المؤشر',
          style: TextStyle(color: context.appColors.textPrimary, fontWeight: FontWeight.bold, fontFamily: 'IBMPlexSansArabic', fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.appColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.appColors.border.withOpacity(0.3)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedIndicator,
                          isExpanded: true,
                          icon: Icon(Icons.keyboard_arrow_down_rounded, color: context.appColors.textSecondary),
                          style: TextStyle(color: context.appColors.textPrimary, fontFamily: 'IBMPlexSansArabic', fontSize: 16, fontWeight: FontWeight.w500),
                          items: kIndicatorNames.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                          onChanged: (v) {
                            if (v != null) ref.read(selectedIndicatorProvider.notifier).state = v;
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    detailAsync.when(
                      loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
                      error: (e, _) => SizedBox(
                        height: 260,
                        child: ErrorRetryView(error: e, onRetry: () => ref.invalidate(indicatorDetailProvider)),
                      ),
                      data: (detail) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Chart
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: context.appColors.cardBackground,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: SizedBox(
                              height: 180,
                              child: LineChart(
                                LineChartData(
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    horizontalInterval: 25,
                                    getDrawingHorizontalLine: (_) => FlLine(color: context.appColors.border.withOpacity(0.3), strokeWidth: 1),
                                  ),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        interval: 25,
                                        reservedSize: 36,
                                        getTitlesWidget: (v, _) => Text('${v.toInt()}%', style: TextStyle(color: context.appColors.textSecondary, fontSize: 10, fontFamily: 'IBMPlexSansArabic')),
                                      ),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 28,
                                        getTitlesWidget: (v, _) {
                                          final idx = v.toInt();
                                          if (idx >= 0 && idx < detail.history.length) {
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 8),
                                              child: Text(detail.history[idx].date, style: TextStyle(color: context.appColors.textSecondary, fontSize: 10, fontFamily: 'IBMPlexSansArabic')),
                                            );
                                          }
                                          return const SizedBox.shrink();
                                        },
                                      ),
                                    ),
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  minX: 0,
                                  maxX: (detail.history.length - 1).toDouble(),
                                  minY: 0,
                                  maxY: 100,
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: detail.history.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.value)).toList(),
                                      isCurved: true,
                                      color: AppTheme.primaryPurple,
                                      barWidth: 3,
                                      isStrokeCapRound: true,
                                      dotData: FlDotData(
                                        show: true,
                                        getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(radius: 4, color: AppTheme.primaryPurple, strokeWidth: 2, strokeColor: Colors.white),
                                      ),
                                      belowBarData: BarAreaData(show: true, color: AppTheme.primaryPurple.withOpacity(0.08)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          _InfoCard(title: 'تحليل', body: detail.analysis),
                          const SizedBox(height: 16),

                          // Natural range
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: context.appColors.cardBackground,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 20, height: 20,
                                  decoration: BoxDecoration(border: Border.all(color: context.appColors.border, width: 1.5), borderRadius: BorderRadius.circular(4)),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('المجال الطبيعي', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.appColors.textPrimary, fontFamily: 'IBMPlexSansArabic')),
                                    const SizedBox(height: 4),
                                    Text(detail.naturalRange, style: TextStyle(fontSize: 14, color: context.appColors.textSecondary, fontFamily: 'IBMPlexSansArabic')),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),
                          _InfoCard(title: 'النتائج', body: detail.results),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: AppTheme.primaryPurple.withOpacity(0.4),
                ),
                child: const Text('استمع إلى تسجيل الجلسة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'IBMPlexSansArabic')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String body;
  const _InfoCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appColors.textPrimary, fontFamily: 'IBMPlexSansArabic')),
          const SizedBox(height: 8),
          Text(body, style: TextStyle(fontSize: 14, color: context.appColors.textSecondary, fontFamily: 'IBMPlexSansArabic', height: 1.5)),
        ],
      ),
    );
  }
}
