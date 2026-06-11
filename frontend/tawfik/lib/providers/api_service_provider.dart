import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

// Instance unique de ApiService accessible partout
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
