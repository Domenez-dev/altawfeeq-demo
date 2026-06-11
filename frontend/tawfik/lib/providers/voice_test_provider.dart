import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/api/models.dart';
import '../services/api_service.dart';
import 'api_service_provider.dart';

class VoiceTestState {
  final String selectedIndicator;
  final bool isRecording;
  final int seconds;
  final double currentPercent;
  final String currentStatus;
  final bool isSubmitting;

  const VoiceTestState({
    this.selectedIndicator = 'شدة الصوت',
    this.isRecording = true,
    this.seconds = 0,
    this.currentPercent = 0.75,
    this.currentStatus = 'جيد',
    this.isSubmitting = false,
  });

  VoiceTestState copyWith({
    String? selectedIndicator,
    bool? isRecording,
    int? seconds,
    double? currentPercent,
    String? currentStatus,
    bool? isSubmitting,
  }) {
    return VoiceTestState(
      selectedIndicator: selectedIndicator ?? this.selectedIndicator,
      isRecording: isRecording ?? this.isRecording,
      seconds: seconds ?? this.seconds,
      currentPercent: currentPercent ?? this.currentPercent,
      currentStatus: currentStatus ?? this.currentStatus,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  String get formattedTime {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class VoiceTestNotifier extends StateNotifier<VoiceTestState> {
  final ApiService _api;
  Timer? _timer;

  VoiceTestNotifier(this._api) : super(const VoiceTestState()) {
    _startTimer();
  }

  void selectIndicator(String indicator) {
    state = state.copyWith(selectedIndicator: indicator);
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(isRecording: false);
  }

  void resume() {
    _startTimer();
  }

  // Retourne SessionResult une fois l'enregistrement soumis
  Future<SessionResult> stop() async {
    _timer?.cancel();
    state = state.copyWith(isRecording: false, isSubmitting: true);
    final result = await _api.submitSession(state.selectedIndicator, state.seconds);
    state = state.copyWith(isSubmitting: false);
    return result;
  }

  void _startTimer() {
    state = state.copyWith(isRecording: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(seconds: state.seconds + 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final voiceTestProvider =
    StateNotifierProvider.autoDispose<VoiceTestNotifier, VoiceTestState>(
  (ref) => VoiceTestNotifier(ref.read(apiServiceProvider)),
);

// Stocke le résultat de la dernière session pour VoiceResultScreen
final lastSessionResultProvider = StateProvider<SessionResult?>((ref) => null);
