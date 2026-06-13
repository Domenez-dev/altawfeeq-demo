import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../theme/app_theme.dart';
import '../models/api/models.dart';
import '../providers/home_provider.dart';
import '../utils/indicator_helpers.dart';
import '../widgets/error_retry.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeAsync = ref.watch(homeDataProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'الرئيسية',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontFamily: 'IBMPlexSansArabic',
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none_rounded, color: AppTheme.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: homeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetryView(error: e, onRetry: () => ref.invalidate(homeDataProvider)),
        data: (data) => _HomeContent(data: data),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final HomeData data;
  const _HomeContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(child: Text('👋', style: TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مرحباً ${data.userName}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      fontFamily: 'IBMPlexSansArabic',
                    ),
                  ),
                  Text(
                    'مستعد لليوم الجديد؟',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      fontFamily: 'IBMPlexSansArabic',
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Progress card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primaryPurple, AppTheme.lightPurple],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryPurple.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'جلسة اليوم',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'IBMPlexSansArabic',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'إجمالي التقدم',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'IBMPlexSansArabic',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data.completedIndicators} / ${data.totalIndicators} مؤشرات',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        fontFamily: 'IBMPlexSansArabic',
                      ),
                    ),
                  ],
                ),
                CircularPercentIndicator(
                  radius: 92.0,
                  lineWidth: 8.0,
                  percent: data.todayProgress,
                  center: Text(
                    '${(data.todayProgress * 100).toInt()}%',
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  progressColor: Colors.white,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  circularStrokeCap: CircularStrokeCap.round,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          Text(
            'المؤشرات اليوم',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              fontFamily: 'IBMPlexSansArabic',
            ),
          ),

          const SizedBox(height: 16),

          ...data.indicators.map((indicator) => _IndicatorRow(indicator: indicator)),
        ],
      ),
    );
  }
}

class _IndicatorRow extends StatelessWidget {
  final IndicatorResult indicator;
  const _IndicatorRow({required this.indicator});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(indicator.status);
    final icon = indicatorIcon(indicator.name);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: AppTheme.border.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    indicator.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'IBMPlexSansArabic'),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(indicator.percent * 100).toInt()}%',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color, fontFamily: 'IBMPlexSansArabic'),
                  ),
                  if (indicator.status == 'جيد') ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        indicator.status,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color, fontFamily: 'IBMPlexSansArabic'),
                      ),
                    ),
                  ],
                ],
              ),
              Icon(icon, color: color, size: 22),
            ],
          ),
          const SizedBox(height: 12),
          LinearPercentIndicator(
            lineHeight: 8.0,
            percent: indicator.percent,
            progressColor: color,
            backgroundColor: color.withOpacity(0.1),
            padding: EdgeInsets.zero,
            linearStrokeCap: LinearStrokeCap.roundAll,
          ),
        ],
      ),
    );
  }
}
