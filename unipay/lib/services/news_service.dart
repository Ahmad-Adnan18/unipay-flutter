import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';

final newsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final client = ref.read(apiClientProvider).client;
  final response = await client.get('/news');
  return List<Map<String, dynamic>>.from(response.data['data']);
});
