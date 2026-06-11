import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/api/models.dart';
import 'api_service_provider.dart';

// 0=أسبوعي  1=شهري  2=كل الفترة
final reportPeriodProvider = StateProvider<int>((ref) => 0);

final reportProvider = FutureProvider<WeeklyReport>((ref) async {
  final periodIndex = ref.watch(reportPeriodProvider);
  final api = ref.read(apiServiceProvider);
  final periods = ['weekly', 'monthly', 'all'];
  return api.getReport(period: periods[periodIndex]);
});
