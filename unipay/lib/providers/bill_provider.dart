// lib/providers/bill_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';

final billsProvider = FutureProvider<List<dynamic>>((ref) async {
  final client = ref.read(apiClientProvider).client;
  final response = await client.get('/bills');
  return response.data['data'];
});
