import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';
import '../models/api/models.dart';
import '../services/api_service.dart';
import '../utils/recordings_store.dart';
import '../utils/wav.dart';
import 'api_service_provider.dart';

// إعدادات الالتقاط: PCM أحادي 16-bit بتردد 44.1kHz (يطابق ما يتوقعه الخادم).
const int _sampleRate = 44100;
const int _numChannels = 1;

// مدة تسجيل مستهدفة مريحة (الخادم يرفض ما هو أقل من ثانيتين).
const int _targetSeconds = 6;

// أقصى قيمة لعيّنة s16le. نستخدمها لتطبيع مستوى الإدخال إلى 0..1.
const int _maxSampleValue = 32767;

// عتبة "الصمت": إذا لم تتجاوز أعلى عيّنة في التسجيل كله هذه القيمة فالميكروفون
// لم يلتقط صوتاً فعلياً (مكتوم/مصدر خاطئ/بعيد جداً). محافِظة عمداً (~ -42dBFS)
// حتى لا نرفض صوتاً خافتاً لكنه صالح — الخادم يبقى البوّابة الحقيقية للجودة.
const int _silencePeakThreshold = 260;

class VoiceTestState {
  final String selectedIndicator;
  final bool isRecording;   // الميكروفون نشط حالياً (غير متوقف مؤقتاً)
  final bool isPaused;      // التسجيل بدأ لكنه متوقف مؤقتاً
  final int seconds;
  final bool isSubmitting;  // جارٍ رفع الملف وانتظار التحليل
  final String? error;      // رسالة خطأ عربية لعرضها للمستخدم
  final String? recordingPath; // مسار آخر تسجيل محفوظ (لإعادة الاستماع)
  final double inputLevel;  // مستوى الإدخال الحالي من الميكروفون 0..1 (لمؤشر VU)

  const VoiceTestState({
    this.selectedIndicator = 'شدة الصوت',
    this.isRecording = false,
    this.isPaused = false,
    this.seconds = 0,
    this.isSubmitting = false,
    this.error,
    this.recordingPath,
    this.inputLevel = 0.0,
  });

  VoiceTestState copyWith({
    String? selectedIndicator,
    bool? isRecording,
    bool? isPaused,
    int? seconds,
    bool? isSubmitting,
    String? error,
    String? recordingPath,
    double? inputLevel,
    bool clearError = false,
  }) {
    return VoiceTestState(
      selectedIndicator: selectedIndicator ?? this.selectedIndicator,
      isRecording: isRecording ?? this.isRecording,
      isPaused: isPaused ?? this.isPaused,
      seconds: seconds ?? this.seconds,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      recordingPath: recordingPath ?? this.recordingPath,
      inputLevel: inputLevel ?? this.inputLevel,
    );
  }

  /// تقدّم التسجيل نحو مدة مريحة (~6 ثوانٍ) لرسم القوس — مؤشر بصري فقط، ليس نتيجة.
  double get recordingProgress => (seconds / _targetSeconds).clamp(0.0, 1.0);

  String get formattedTime {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class VoiceTestNotifier extends StateNotifier<VoiceTestState> {
  final ApiService _api;
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _timer;
  StreamSubscription<Uint8List>? _audioSub;
  final BytesBuilder _pcmBuffer = BytesBuilder(copy: false);
  int _peakAbs = 0;            // أعلى عيّنة (قيمة مطلقة) في التسجيل الحالي
  DateTime _lastLevelEmit = DateTime.fromMillisecondsSinceEpoch(0);

  VoiceTestNotifier(this._api) : super(const VoiceTestState()) {
    // ابدأ التسجيل فور فتح الشاشة.
    _start();
  }

  void selectIndicator(String indicator) {
    state = state.copyWith(selectedIndicator: indicator);
  }

  /// يبدأ تسجيلاً جديداً (يُستدعى عند فتح الشاشة وعند "جلسة جديدة" بعد خطأ).
  ///
  /// نستخدم startStream بدل start(path:) لأن record_linux 2.1.0 يتعطّل عند
  /// الإيقاف في المسار المبني على ملف؛ هنا نلتقط الـ PCM الخام ونكتب WAV بأنفسنا.
  Future<void> _start() async {
    try {
      if (!await _recorder.hasPermission()) {
        state = state.copyWith(
          isRecording: false,
          isPaused: false,
          error: 'لم يتم منح إذن الوصول إلى الميكروفون',
        );
        return;
      }

      _pcmBuffer.clear();
      _peakAbs = 0;

      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _sampleRate,
          numChannels: _numChannels,
        ),
      );

      _audioSub = stream.listen(
        _onAudioChunk,
        onError: (Object e) {
          state = state.copyWith(error: 'خطأ أثناء التقاط الصوت: $e');
        },
        cancelOnError: false,
      );

      state = state.copyWith(
        isRecording: true,
        isPaused: false,
        seconds: 0,
        inputLevel: 0.0,
        clearError: true,
      );
      _startTimer();
    } catch (e) {
      state = state.copyWith(
        isRecording: false,
        isPaused: false,
        error: 'تعذّر بدء التسجيل: $e',
      );
    }
  }

  Future<void> pause() async {
    if (!state.isRecording) return;
    _timer?.cancel();
    await _recorder.pause();
    state = state.copyWith(isRecording: false, isPaused: true);
  }

  /// زر التشغيل: يستأنف تسجيلاً متوقفاً مؤقتاً، أو يبدأ تسجيلاً جديداً بعد خطأ/توقف.
  Future<void> resume() async {
    if (state.isPaused) {
      await _recorder.resume();
      state = state.copyWith(isRecording: true, isPaused: false);
      _startTimer();
    } else if (!state.isRecording) {
      await _start();
    }
  }

  /// يوقف التسجيل، يحفظ WAV في تخزين التطبيق، يرفعه للتحليل، ويُعيد [SessionResult].
  ///
  /// يُعيد null عند الفشل ويضع رسالة الخطأ في [VoiceTestState.error] لتعرضها الشاشة.
  Future<SessionResult?> stop() async {
    _timer?.cancel();

    if (!state.isRecording && !state.isPaused) {
      // لم يبدأ تسجيل أصلاً (مثلاً رُفض إذن الميكروفون).
      state = state.copyWith(error: state.error ?? 'لا يوجد تسجيل لتحليله');
      return null;
    }

    state = state.copyWith(isRecording: false, isPaused: false, isSubmitting: true);

    try {
      await _recorder.stop();
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: 'تعذّر إنهاء التسجيل: $e');
      return null;
    }
    await _audioSub?.cancel();
    _audioSub = null;

    final pcm = _pcmBuffer.takeBytes();
    if (pcm.isEmpty) {
      state = state.copyWith(isSubmitting: false, error: 'لم يُسجَّل أي صوت، حاول مرة أخرى');
      return null;
    }

    // فحص محلي سريع للصمت قبل الرفع: إن لم يلتقط الميكروفون أي صوت فعلي،
    // نعطي المستخدم نفس إرشاد الخادم فوراً دون انتظار جولة شبكة.
    if (_peakAbs < _silencePeakThreshold) {
      state = state.copyWith(
        isSubmitting: false,
        inputLevel: 0.0,
        error: 'لم نسمع صوتاً واضحاً. اقترب من الميكروفون وتحدّث بصوت أعلى ثم أعد المحاولة.',
      );
      return null;
    }

    String path;
    try {
      path = await _saveWav(pcm);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: 'تعذّر حفظ التسجيل: $e');
      return null;
    }

    try {
      final result = await _api.analyzeRecording(path);
      // أعد تسمية الملف باسم الجلسة (session_<id>.wav) حتى يمكن إيجاده وتشغيله
      // لاحقاً من سجل الجلسات القديمة.
      var finalPath = path;
      try {
        finalPath = await sessionRecordingPath(result.sessionId);
        await File(path).rename(finalPath);
      } catch (_) {
        finalPath = path;
      }
      state = state.copyWith(isSubmitting: false, recordingPath: finalPath, clearError: true);
      return result;
    } on AnalysisException catch (e) {
      state = state.copyWith(isSubmitting: false, recordingPath: path, error: e.message);
      return null;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, recordingPath: path, error: 'تعذّر تحليل التسجيل: $e');
      return null;
    }
  }

  /// يستقبل كل دفعة PCM: يخزّنها، يحدّث ذروة المستوى، ويُحدّث مؤشر VU (مُخمّد).
  void _onAudioChunk(Uint8List chunk) {
    _pcmBuffer.add(chunk);

    // أعلى عيّنة (قيمة مطلقة) في هذه الدفعة من بيانات s16le.
    var chunkPeak = 0;
    for (var i = 0; i + 1 < chunk.length; i += 2) {
      var sample = chunk[i] | (chunk[i + 1] << 8);
      if (sample > _maxSampleValue) sample -= 65536; // unsigned → signed
      final abs = sample.abs();
      if (abs > chunkPeak) chunkPeak = abs;
    }
    if (chunkPeak > _peakAbs) _peakAbs = chunkPeak;

    // خمّد تحديث الحالة إلى ~12 مرة/ثانية لتجنّب إعادة بناء الواجهة بإفراط.
    final now = DateTime.now();
    if (now.difference(_lastLevelEmit) >= const Duration(milliseconds: 80)) {
      _lastLevelEmit = now;
      state = state.copyWith(
        inputLevel: (chunkPeak / _maxSampleValue).clamp(0.0, 1.0),
      );
    }
  }

  /// يكتب الـ PCM الملتقط كملف WAV مؤقت في مجلد التسجيلات (تخزين دائم).
  /// تُعاد تسميته باسم الجلسة بعد نجاح التحليل.
  Future<String> _saveWav(Uint8List pcm) async {
    final recDir = await recordingsDir();
    final path = p.join(recDir.path, 'rec_${DateTime.now().millisecondsSinceEpoch}.wav');
    final bytes = buildWavBytes(pcm, sampleRate: _sampleRate, channels: _numChannels);
    await File(path).writeAsBytes(bytes, flush: true);
    return path;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(seconds: state.seconds + 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioSub?.cancel();
    _recorder.dispose();
    super.dispose();
  }
}

final voiceTestProvider =
    StateNotifierProvider.autoDispose<VoiceTestNotifier, VoiceTestState>(
  (ref) => VoiceTestNotifier(ref.read(apiServiceProvider)),
);

// يخزّن نتيجة آخر جلسة لعرضها في VoiceResultScreen.
final lastSessionResultProvider = StateProvider<SessionResult?>((ref) => null);

// يخزّن مسار آخر تسجيل صوتي لإعادة الاستماع إليه في VoiceResultScreen.
final lastRecordingPathProvider = StateProvider<String?>((ref) => null);
