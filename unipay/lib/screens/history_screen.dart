// lib/screens/history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:unipay/core/theme.dart';
import '../providers/bill_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(billsProvider);
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text('Riwayat Pembayaran'),
        elevation: 0,
      ),
      body: billsAsync.when(
        data: (bills) {
          final paidBills = bills.where((bill) => bill['status'] == 'PAID').toList();

          if (paidBills.isEmpty) {
             return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 80, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada riwayat pembayaran.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
             );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(billsProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: paidBills.length,
              itemBuilder: (context, index) {
                final bill = paidBills[index];
                final date = DateTime.parse(bill['updated_at'] ?? bill['created_at']); // Fallback logic
                final dateFormatted = DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(date);

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.green),
                    ),
                    title: Text(
                      bill['title'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(dateFormatted),
                    trailing: Text(
                      currencyFormatter.format(double.parse(bill['amount'])),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
        error: (err, stack) => Center(child: Text('Error: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
