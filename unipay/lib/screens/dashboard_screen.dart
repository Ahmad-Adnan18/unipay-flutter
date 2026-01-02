// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:unipay/core/theme.dart';
import '../providers/bill_provider.dart';
import 'payment_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(billsProvider);
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
        automaticallyImplyLeading: false, 
      ),
      body: Container(
        color: AppTheme.backgroundWhite,
        child: billsAsync.when(
          data: (bills) {
            // Filter Unpaid Only
            final unpaidBills = bills.where((bill) => bill['status'] == 'UNPAID').toList();

            if (unpaidBills.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, 
                      size: 80, 
                      color: Colors.green.withOpacity(0.5)
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Hore! Tidak ada tagihan.',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () {
                return ref.refresh(billsProvider.future);
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: unpaidBills.length,
                itemBuilder: (context, index) {
                  final bill = unpaidBills[index];
                  // ... rest of item builder logic (simplified for brevity if needed or kept same)
                  final date = DateTime.parse(bill['due_date']);
                  final dateFormatted = DateFormat('d MMMM yyyy', 'id_ID').format(date);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: Colors.orange.withOpacity(0.2),
                        width: 1,
                      )
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'BELUM DIBAYAR',
                                  style: TextStyle(
                                    color: Colors.orange.shade800,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade300)
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            bill['title'],
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currencyFormatter.format(double.parse(bill['amount'])),
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.w800,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Jatuh Tempo',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  Text(
                                    dateFormatted,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => PaymentScreen(
                                        billId: bill['id'],
                                        billTitle: bill['title'],
                                        amount: double.parse(bill['amount']),
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.qr_code_2),
                                label: const Text('Bayar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryGreen,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
          error: (err, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Gagal memuat tagihan'),
                TextButton(
                  onPressed: () => ref.refresh(billsProvider),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}
