import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:unipay/core/theme.dart';
import 'package:unipay/providers/bill_provider.dart';
import 'package:unipay/screens/payment_method_screen.dart';

class BillsScreen extends ConsumerWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(billsProvider);
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: billsAsync.when(
        data: (bills) {
          // You might still want to show all bills or just UNPAID, based on user request "halaman khusus untuk menampilkan semua tagihan"
          // Let's sort UNPAID first
          final sortedBills = List<Map<String, dynamic>>.from(bills);
          sortedBills.sort((a, b) {
            if (a['status'] == 'UNPAID' && b['status'] != 'UNPAID') return -1;
            if (a['status'] != 'UNPAID' && b['status'] == 'UNPAID') return 1;
            return 0;
          });

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                 child: Stack(
                   alignment: Alignment.center,
                   clipBehavior: Clip.none,
                   children: [
                      Container(
                        height: 130, 
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.primaryGreen, AppTheme.primaryGreen.withOpacity(0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                        ),
                      ),
                      
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 20,
                        child: const Text(
                          'Semua Tagihan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      
                      if (sortedBills.isEmpty)
                         Positioned.fill(
                           top: 220,
                           child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.receipt_long, size: 64, color: AppTheme.primaryGreen.withOpacity(0.5)),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'Belum ada tagihan',
                                    style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500, fontSize: 16),
                                  ),
                                ],
                              ),
                           ),
                         )
                   ],
                 ),
              ),
              
              if (sortedBills.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final bill = sortedBills[index];
                        return _buildBillCard(context, bill, currencyFormatter);
                      },
                      childCount: sortedBills.length,
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Gagal memuat tagihan: $err')),
      ),
    );
  }

  Widget _buildBillCard(BuildContext context, Map<String, dynamic> bill, NumberFormat formatter) {
     final date = DateTime.parse(bill['created_at']); // Or due_date
     final dateFormatted = DateFormat('d MMM yyyy', 'id_ID').format(date);
     final isPaid = bill['status'] == 'PAID';

     return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
             BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill['title'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(dateFormatted, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPaid ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: Text(
                    bill['status'], 
                    style: TextStyle(
                      color: isPaid ? Colors.green : Colors.orange, 
                      fontSize: 10, 
                      fontWeight: FontWeight.bold
                    )
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Colors.grey), // Light divider like HistoryScreen
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     const Text('Total Tagihan', style: TextStyle(fontSize: 10, color: Colors.grey)),
                     Text(
                       formatter.format(double.parse(bill['amount'])),
                       style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 16),
                     ),
                   ],
                 ),
                 if (!isPaid)
                   ElevatedButton(
                     onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => PaymentMethodScreen(
                              billId: bill['id'],
                              billTitle: bill['title'],
                              amount: double.parse(bill['amount']),
                            ),
                          ),
                        );
                     },
                     style: ElevatedButton.styleFrom(
                       backgroundColor: AppTheme.primaryGreen,
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                       elevation: 0,
                     ),
                     child: const Text('Bayar'),
                   )
              ],
            )
          ],
        ),
     );
  }
}
