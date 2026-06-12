import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// زر صغير لإعادة الاستماع إلى تسجيل صوتي محفوظ محلياً (ملف WAV على الجهاز).
///
/// يُستخدم في شاشة نتيجة الجلسة وفي شاشة تفاصيل جلسة قديمة.
class RecordingPlayer extends StatefulWidget {
  final String path;
  const RecordingPlayer({super.key, required this.path});

  @override
  State<RecordingPlayer> createState() => _RecordingPlayerState();
}

class _RecordingPlayerState extends State<RecordingPlayer> {
  final AudioPlayer _player = AudioPlayer();
  PlayerState _state = PlayerState.stopped;

  bool get _isPlaying => _state == PlayerState.playing;

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((s) {
      if (!mounted) return;
      setState(() => _state = s);
    });
  }

  Future<void> _toggle() async {
    try {
      if (_isPlaying) {
        await _player.pause();
      } else if (_state == PlayerState.paused) {
        // يستأنف من نفس الموضع بعد الإيقاف المؤقت.
        await _player.resume();
      } else {
        // يبدأ التشغيل من البداية (أول مرة أو بعد الانتهاء).
        await _player.play(DeviceFileSource(widget.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذّر تشغيل التسجيل: $e', style: const TextStyle(fontFamily: 'IBMPlexSansArabic')),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.primaryPurple.withOpacity(0.08),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: AppTheme.primaryPurple,
              size: 26,
            ),
            const SizedBox(width: 8),
            Text(
              _isPlaying ? 'إيقاف مؤقت' : 'استمع إلى تسجيلك',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryPurple,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
