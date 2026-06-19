import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../theme/app_theme.dart';
import '../models/api/models.dart';
import '../providers/api_service_provider.dart';
import '../providers/home_provider.dart';
import '../providers/reports_provider.dart';
import '../providers/sessions_provider.dart';
import '../utils/indicator_helpers.dart';
import '../utils/recordings_store.dart';
import '../widgets/recording_player.dart';

/// تفاصيل جلسة قديمة: مؤشراتها التحليلية + إعادة الاستماع لتسجيلها (إن توفّر محلياً)
/// + إمكانية حذفها.
class SessionDetailScreen extends ConsumerWidget {
  final Session session;
  const SessionDetailScreen({super.key, required this.session});

  String _statusFor(double percent) =>
      percent >= 0.7 ? 'جيد' : percent >= 0.4 ? 'متوسط' : 'ضعيف';

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('حذف الجلسة', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.bold)),
        content: Text('هل تريد حذف "${session.title}"؟ لا يمكن التراجع عن هذا الإجراء.',
            style: const TextStyle(fontFamily: 'IBMPlexSansArabic')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: TextStyle(fontFamily: 'IBMPlexSansArabic', color: context.appColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(fontFamily: 'IBMPlexSansArabic', color: AppTheme.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(apiServiceProvider).deleteSession(session.id);
      await deleteSessionRecording(session.id);
      ref.invalidate(sessionsProvider);
      ref.invalidate(homeDataProvider);
      ref.invalidate(reportProvider);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذّر حذف الجلسة: $e', style: const TextStyle(fontFamily: 'IBMPlexSansArabic')),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overallColor = statusColor(_statusFor(session.overallPercent));
    final indicators = session.indicators ?? const [];

    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        backgroundColor: context.appColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.appColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(session.title,
            style: TextStyle(color: context.appColors.textPrimary, fontWeight: FontWeight.bold, fontFamily: 'IBMPlexSansArabic', fontSize: 20)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
            tooltip: 'حذف',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Overall score circle (large so the % never overlaps the ring)
              CircularPercentIndicator(
                radius: 96.0,
                lineWidth: 12.0,
                percent: session.overallPercent.clamp(0.0, 1.0),
                center: Text(
                  '${(session.overallPercent * 100).toInt()}%',
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 30.0, fontWeight: FontWeight.bold, color: overallColor),
                ),
                progressColor: overallColor,
                backgroundColor: overallColor.withOpacity(0.12),
                circularStrokeCap: CircularStrokeCap.round,
              ),
              const SizedBox(height: 12),
              Text('${session.date}  •  ${session.time}',
                  style: TextStyle(fontSize: 13, color: context.appColors.textSecondary, fontFamily: 'IBMPlexSansArabic')),

              const SizedBox(height: 28),

              // Audio playback (only if the recording exists on this device)
              FutureBuilder<File?>(
                future: sessionRecordingFile(session.id),
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const SizedBox(height: 8);
                  }
                  final file = snap.data;
                  if (file != null) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 28),
                      child: RecordingPlayer(path: file.path),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 28),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.volume_off_rounded, size: 18, color: context.appColors.textSecondary.withOpacity(0.7)),
                        const SizedBox(width: 8),
                        Text('تسجيل هذه الجلسة غير متوفر على هذا الجهاز',
                            style: TextStyle(fontSize: 12.5, color: context.appColors.textSecondary, fontFamily: 'IBMPlexSansArabic')),
                      ],
                    ),
                  );
                },
              ),

              // Indicators
              Align(
                alignment: Alignment.centerRight,
                child: Text('المؤشرات الصوتية',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appColors.textPrimary, fontFamily: 'IBMPlexSansArabic')),
              ),
              const SizedBox(height: 12),

              if (indicators.isEmpty)
                Text('لا توجد تفاصيل مؤشرات لهذه الجلسة',
                    style: TextStyle(fontSize: 13, color: context.appColors.textSecondary, fontFamily: 'IBMPlexSansArabic'))
              else
                ...indicators.map((ind) => _IndicatorCard(indicator: ind)),
            ],
          ),
        ),
      ),
    );
  }
}

class _IndicatorCard extends StatelessWidget {
  final IndicatorResult indicator;
  const _IndicatorCard({required this.indicator});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(indicator.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.border.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Icon(indicatorIcon(indicator.name), color: color, size: 20),
                const SizedBox(width: 8),
                Text(indicator.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'IBMPlexSansArabic')),
              ]),
              Row(children: [
                Text('${(indicator.percent * 100).toInt()}%',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color, fontFamily: 'IBMPlexSansArabic')),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: Text(indicator.status,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color, fontFamily: 'IBMPlexSansArabic')),
                ),
              ]),
            ],
          ),
          const SizedBox(height: 12),
          LinearPercentIndicator(
            lineHeight: 8.0,
            percent: indicator.percent.clamp(0.0, 1.0),
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
