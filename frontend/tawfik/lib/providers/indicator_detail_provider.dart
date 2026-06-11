import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/api/models.dart';
import 'api_service_provider.dart';

// Indicateur sélectionné dans le dropdown de la page تفاصيل المؤشر
final selectedIndicatorProvider = StateProvider<String>((ref) => 'شدة الصوت');

// Se recharge automatiquement quand selectedIndicatorProvider change
final indicatorDetailProvider = FutureProvider<IndicatorDetail>((ref) async {
  final name = ref.watch(selectedIndicatorProvider);
  final api = ref.read(apiServiceProvider);
  return api.getIndicatorDetail(name);
});
