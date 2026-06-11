import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/voice_test_provider.dart';
import '../utils/indicator_helpers.dart';
import 'voice_result_screen.dart';

class VoiceTestScreen extends ConsumerWidget {
  const VoiceTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(voiceTestProvider);
    final notifier = ref.read(voiceTestProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'المؤشر الحالي',
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontFamily: 'IBMPlexSansArabic', fontSize: 20),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border.withOpacity(0.3)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: state.selectedIndicator,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textSecondary),
                    style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'IBMPlexSansArabic', fontSize: 16, fontWeight: FontWeight.w500),
                    items: kIndicatorNames.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                    onChanged: (v) { if (v != null) notifier.selectIndicator(v); },
                  ),
                ),
              ),

              // Jauge arc
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
                          painter: _ArcGaugePainter(progress: state.currentPercent),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${(state.currentPercent * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryPurple,
                                fontFamily: 'IBMPlexSansArabic',
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              state.currentStatus,
                              style: const TextStyle(fontSize: 18, color: AppTheme.textSecondary, fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Waveform
              SizedBox(
                height: 44,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(36, (index) {
                    final mid = 17.5;
                    final dist = (index - mid).abs() / mid;
                    final h = 7.0 + (1 - dist) * 32.0;
                    final active = index < 20;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      width: 3,
                      height: h,
                      decoration: BoxDecoration(
                        color: active ? AppTheme.primaryPurple.withOpacity(0.7 - dist * 0.2) : AppTheme.primaryPurple.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                state.formattedTime,
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontFamily: 'IBMPlexSansArabic'),
              ),

              const SizedBox(height: 6),

              const Text(
                'تحدث الآن بصوتك الطبيعي',
                style: TextStyle(fontSize: 15, color: AppTheme.textPrimary, fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.w500),
              ),

              const SizedBox(height: 4),

              Text(
                state.isRecording ? 'التسجيل جار...' : 'متوقف مؤقتاً',
                style: const TextStyle(fontSize: 14, color: AppTheme.primaryPurple, fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.w500),
              ),

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
                        ref.read(lastSessionResultProvider.notifier).state = result;
                        if (context.mounted) {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const VoiceResultScreen()));
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
          color: isMain ? AppTheme.primaryPurple : Colors.white,
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
