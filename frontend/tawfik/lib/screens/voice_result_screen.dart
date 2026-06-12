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

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text(
              'نتيجة الجلسة',
              style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontFamily: 'IBMPlexSansArabic', fontSize: 20),
            ),
            Text(
              result.date,
              style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'IBMPlexSansArabic', fontSize: 12),
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
              const SizedBox(height: 32),

              // Success icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.success,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppTheme.success.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
              ),

              const SizedBox(height: 24),

              const Text(
                'تمت الجلسة بنجاح',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontFamily: 'IBMPlexSansArabic'),
              ),
              const SizedBox(height: 8),
              Text('إجمالي التقدم', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary, fontFamily: 'IBMPlexSansArabic')),
              const SizedBox(height: 8),
              Text(
                '${(result.overallPercent * 100).toInt()}%',
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple, fontFamily: 'IBMPlexSansArabic'),
              ),

              if (recordingPath != null) ...[
                const SizedBox(height: 20),
                RecordingPlayer(path: recordingPath),
              ],

              const SizedBox(height: 32),

              // Results list
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.border.withOpacity(0.3)),
                  ),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
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
            child: Text(indicator.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary, fontFamily: 'IBMPlexSansArabic')),
          ),
          Expanded(
            flex: 1,
            child: Text('${(indicator.percent * 100).toInt()}%', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontFamily: 'IBMPlexSansArabic')),
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
