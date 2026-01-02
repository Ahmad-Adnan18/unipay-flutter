// lib/providers/transaction_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';

final transactionProvider = StateNotifierProvider<TransactionNotifier, AsyncValue<Map<String, dynamic>?>>((ref) {
  return TransactionNotifier(ref);
});

class TransactionNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  final Ref _ref;

  TransactionNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> createTransaction(int billId) async {
    state = const AsyncValue.loading();
    try {
      final client = _ref.read(apiClientProvider).client;
      final response = await client.post('/pay', data: {
        'bill_id': billId,
      });

      state = AsyncValue.data(response.data['data']);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<String?> checkStatus(String orderId) async {
    try {
      final client = _ref.read(apiClientProvider).client;
      final response = await client.get('/transactions/$orderId/status');
      final data = response.data['data'];
      return data['status'];
    } catch (e) {
      return null;
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}
