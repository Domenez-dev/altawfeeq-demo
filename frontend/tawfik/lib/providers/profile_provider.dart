import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/api/models.dart';
import 'api_service_provider.dart';

final profileProvider = FutureProvider<UserProfile>((ref) async {
  final api = ref.read(apiServiceProvider);
  return api.getUserProfile();
});
