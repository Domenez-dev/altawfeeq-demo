import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/api/models.dart';
import 'api_service_provider.dart';

// Indicateur sélectionné dans le dropdown de la page تفاصيل المؤشر
final selectedIndicatorProvider = StateProvider<String>((ref) => 'شدة الصوت');

// Se recharge automatiquement quand selectedIndicatorProvider change.
// autoDispose : le provider est jeté quand on quitte l'écran, donc rouvrir la
// page تفاصيل المؤشر relance la requête et affiche les nouvelles séances
// (sinon le résultat resterait en cache et le graphe ne se mettrait pas à jour).
final indicatorDetailProvider = FutureProvider.autoDispose<IndicatorDetail>((ref) async {
  final name = ref.watch(selectedIndicatorProvider);
  final api = ref.read(apiServiceProvider);
  return api.getIndicatorDetail(name);
});
