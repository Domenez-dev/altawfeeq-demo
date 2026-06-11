import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/api/models.dart';
import 'api_service_provider.dart';

final homeDataProvider = FutureProvider<HomeData>((ref) async {
  final api = ref.read(apiServiceProvider);
  return api.getHomeData();
});
