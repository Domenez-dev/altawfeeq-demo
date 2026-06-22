import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../models/api/models.dart';
import '../providers/voice_test_provider.dart';
import '../utils/indicator_helpers.dart';
import '../widgets/recording_player.dart';
import 'indicator_details_screen.dart';

class VoiceResultScreen extends ConsumerWidget {
  const VoiceResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(lastSessionResultProvider);
    final recordingPath = ref.watch(lastRecordingPathProvider);

    if (result == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // التصنيف ثلاثي المستويات (سليم معرفياً / ضعف إدراكي بسيط / مريض) بالعربية.
    final clsColor = classificationColor(result.classification, overallPercent: result.overallPercent);
    final clsLabel = classificationLabelFor(result.classification, overallPercent: result.overallPercent);
    final clsDesc = classificationDescriptionFor(result.classification, overallPercent: result.overallPercent);
    final clsIcon = classificationIcon(result.classification, overallPercent: result.overallPercent);

    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        backgroundColor: context.appColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.appColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              'نتيجة الجلسة',
              style: TextStyle(color: context.appColors.textPrimary, fontWeight: FontWeight.bold, fontFamily: 'IBMPlexSansArabic', fontSize: 20),
            ),
            Text(
              result.date,
              style: TextStyle(color: context.appColors.textSecondary, fontFamily: 'IBMPlexSansArabic', fontSize: 12),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // أيقونة دائرية بلون التصنيف
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: clsColor,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: clsColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Icon(clsIcon, color: Colors.white, size: 44),
              ),

              const SizedBox(height: 16),

              // النتيجة المبدئية للفحص (بالعربية)
              Text(
                clsLabel,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: clsColor, fontFamily: 'IBMPlexSansArabic'),
              ),
              const SizedBox(height: 6),
              Text(
                'النتيجة الإجمالية: ${(result.overallPercent * 100).toInt()}%',
                style: TextStyle(fontSize: 15, color: context.appColors.textSecondary, fontFamily: 'IBMPlexSansArabic'),
              ),

              const SizedBox(height: 12),

              // وصف موجز للتصنيف
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: clsColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: clsColor.withOpacity(0.25)),
                ),
                child: Text(
                  clsDesc,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: context.appColors.textPrimary, fontFamily: 'IBMPlexSansArabic', height: 1.5),
                ),
              ),

              if (recordingPath != null) ...[
                const SizedBox(height: 16),
                RecordingPlayer(path: recordingPath),
              ],

              const SizedBox(height: 20),

              // Results list
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: context.appColors.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.appColors.border.withOpacity(0.3)),
                  ),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    // قائمة المؤشرات قابلة للتمرير حتى تظهر كل العناصر (الطبقة
                    // والاضطراب) على الشاشات الصغيرة بدل أن تُقتطع.
                    physics: const ClampingScrollPhysics(),
                    itemCount: result.indicators.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (_, i) => _ResultItem(indicator: result.indicators[i]),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IndicatorDetailsScreen())),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('عرض التفاصيل', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'IBMPlexSansArabic')),
              ),

              const SizedBox(height: 16),

              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryPurple,
                  backgroundColor: AppTheme.primaryPurple.withOpacity(0.05),
                  side: const BorderSide(color: Colors.transparent),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('جلسة جديدة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'IBMPlexSansArabic')),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultItem extends StatelessWidget {
  final IndicatorResult indicator;
  const _ResultItem({required this.indicator});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(indicator.status);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(indicator.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.appColors.textPrimary, fontFamily: 'IBMPlexSansArabic')),
          ),
          Expanded(
            flex: 1,
            child: Text('${(indicator.percent * 100).toInt()}%', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.appColors.textPrimary, fontFamily: 'IBMPlexSansArabic')),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Text(indicator.status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color, fontFamily: 'IBMPlexSansArabic')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
