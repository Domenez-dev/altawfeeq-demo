import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/api/models.dart';
import 'api_service_provider.dart';

// Filtre actif : 0=الكل  1=مكتملة  2=ملغاة
final sessionFilterProvider = StateProvider<int>((ref) => 0);

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
