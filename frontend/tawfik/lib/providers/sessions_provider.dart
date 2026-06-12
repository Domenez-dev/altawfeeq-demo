import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/api/models.dart';
import 'api_service_provider.dart';

// Filtre actif : 0=الكل  1=مكتملة  2=ملغاة
final sessionFilterProvider = StateProvider<int>((ref) => 0);

/// مجموعة معرّفات الجلسات المحدّدة (لوضع التحديد والحذف الجماعي).
/// وضع التحديد فعّال طالما المجموعة غير فارغة.
class SessionSelectionNotifier extends StateNotifier<Set<int>> {
  SessionSelectionNotifier() : super(const {});

  void toggle(int id) {
    final next = {...state};
    if (!next.add(id)) next.remove(id);
    state = next;
  }

  void clear() => state = const {};
}

final sessionSelectionProvider =
    StateNotifierProvider<SessionSelectionNotifier, Set<int>>(
  (ref) => SessionSelectionNotifier(),
);

final sessionsProvider = FutureProvider<List<Session>>((ref) async {
  final api = ref.read(apiServiceProvider);
  return api.getSessions();
});

// Liste filtrée dérivée des deux providers ci-dessus
final filteredSessionsProvider = Provider<AsyncValue<List<Session>>>((ref) {
  final filter = ref.watch(sessionFilterProvider);
  final sessionsAsync = ref.watch(sessionsProvider);

  return sessionsAsync.whenData((sessions) {
    if (filter == 1) return sessions.where((s) => s.overallPercent >= 0.5).toList();
    if (filter == 2) return sessions.where((s) => s.overallPercent < 0.5).toList();
    return sessions;
  });
});
