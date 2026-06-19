import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/voice_test_provider.dart';
import '../providers/home_provider.dart';
import '../providers/sessions_provider.dart';
import '../providers/reports_provider.dart';
import '../utils/indicator_helpers.dart';
import 'voice_result_screen.dart';

class VoiceTestScreen extends ConsumerWidget {
  const VoiceTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(voiceTestProvider);
    final notifier = ref.read(voiceTestProvider.notifier);

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
          'المؤشر الحالي',
          style: TextStyle(color: context.appColors.textPrimary, fontWeight: FontWeight.bold, fontFamily: 'IBMPlexSansArabic', fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 12),

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
                    value: state.selectedIndicator,
                    isExpanded: true,
                    icon: Icon(Icons.keyboard_arrow_down_rounded, color: context.appColors.textSecondary),
                    style: TextStyle(color: context.appColors.textPrimary, fontFamily: 'IBMPlexSansArabic', fontSize: 16, fontWeight: FontWeight.w500),
                    items: kIndicatorNames.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                    onChanged: (v) { if (v != null) notifier.selectIndicator(v); },
                  ),
                ),
              ),

              // Recording indicator (progress vers une durée confortable, pas un score)
              Expanded(
                flex: 5,
                child: Center(
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(200, 200),
                          painter: _ArcGaugePainter(progress: state.recordingProgress),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              state.isRecording ? Icons.mic_rounded : Icons.mic_none_rounded,
                              size: 56,
                              color: AppTheme.primaryPurple,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.isSubmitting
                                  ? 'جارٍ التحليل...'
                                  : state.isRecording
                                      ? 'جارٍ التسجيل'
                                      : state.isPaused
                                          ? 'متوقف مؤقتاً'
                                          : 'جاهز',
                              style: TextStyle(fontSize: 18, color: context.appColors.textSecondary, fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Live VU meter — bars react to the actual microphone input level,
              // so the user can see that the mic is picking up their voice.
              SizedBox(
                height: 44,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(36, (index) {
                    final mid = 17.5;
                    final dist = (index - mid).abs() / mid;
                    // شكل جرسي: الأعمدة الوسطى تتفاعل بقوة أكبر مع مستوى الصوت.
                    final level = state.isRecording
                        ? (state.inputLevel * (1.0 - dist * 0.5)).clamp(0.0, 1.0)
                        : 0.0;
                    final h = 6.0 + level * 34.0;
                    final active = level > 0.06;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 90),
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      width: 3,
                      height: h,
                      decoration: BoxDecoration(
                        color: active
                            ? AppTheme.primaryPurple.withOpacity(0.75 - dist * 0.2)
                            : AppTheme.primaryPurple.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                state.formattedTime,
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: context.appColors.textPrimary, fontFamily: 'IBMPlexSansArabic'),
              ),

              const SizedBox(height: 6),

              Text(
                'تحدث الآن بصوتك الطبيعي',
                style: TextStyle(fontSize: 15, color: context.appColors.textPrimary, fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.w500),
              ),

              const SizedBox(height: 4),

              Text(
                state.isRecording ? 'التسجيل جار...' : 'متوقف مؤقتاً',
                style: const TextStyle(fontSize: 14, color: AppTheme.primaryPurple, fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.w500),
              ),

              // رسالة الخطأ تبقى ظاهرة (وليست لحظية) حتى يبدأ المستخدم تسجيلاً جديداً.
              if (state.error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.error.withOpacity(0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          state.error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, color: AppTheme.error, fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(flex: 2),

              // Controls
              if (state.isSubmitting)
                const CircularProgressIndicator()
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ControlButton(
                      icon: state.isRecording ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      isMain: false,
                      onPressed: () => state.isRecording ? notifier.pause() : notifier.resume(),
                    ),
                    const SizedBox(width: 24),
                    _ControlButton(
                      icon: Icons.stop_rounded,
                      isMain: true,
                      onPressed: () async {
                        final result = await notifier.stop();
                        if (!context.mounted) return;
                        if (result != null) {
                          ref.read(lastSessionResultProvider.notifier).state = result;
                          // مرّر مسار التسجيل لشاشة النتيجة حتى يمكن الاستماع إليه.
                          ref.read(lastRecordingPathProvider.notifier).state =
                              ref.read(voiceTestProvider).recordingPath;
                          // حدّث التحليلات (الرئيسية/الجلسات/التقارير) لتظهر الجلسة الجديدة فوراً.
                          ref.invalidate(homeDataProvider);
                          ref.invalidate(sessionsProvider);
                          ref.invalidate(reportProvider);
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const VoiceResultScreen()));
                        } else {
                          // فشل التحليل (تسجيل قصير/جودة ضعيفة/خطأ شبكة) — اعرض السبب واسمح بإعادة المحاولة.
                          final err = ref.read(voiceTestProvider).error ?? 'تعذّر تحليل التسجيل، حاول مرة أخرى';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(err, style: const TextStyle(fontFamily: 'IBMPlexSansArabic')),
                              backgroundColor: AppTheme.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 24),
                    _ControlButton(icon: Icons.bar_chart_rounded, isMain: false, onPressed: () {}),
                  ],
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final bool isMain;
  final VoidCallback onPressed;
  const _ControlButton({required this.icon, required this.isMain, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: isMain ? 72 : 56,
        height: isMain ? 72 : 56,
        decoration: BoxDecoration(
          color: isMain ? AppTheme.primaryPurple : context.appColors.cardBackground,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: (isMain ? AppTheme.primaryPurple : Colors.black).withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Icon(icon, color: isMain ? Colors.white : AppTheme.primaryPurple, size: isMain ? 32 : 24),
      ),
    );
  }
}

class _ArcGaugePainter extends CustomPainter {
  final double progress;
  const _ArcGaugePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;
    const strokeWidth = 14.0;
    const startAngle = pi * 0.75;
    const totalSweep = pi * 1.5;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle, totalSweep, false,
      Paint()..color = AppTheme.primaryPurple.withOpacity(0.12)..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle, totalSweep * progress, false,
      Paint()..color = AppTheme.primaryPurple..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcGaugePainter old) => old.progress != progress;
}
