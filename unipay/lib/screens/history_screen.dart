// lib/screens/history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:unipay/core/theme.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants.dart';
import '../providers/bill_provider.dart';
import '../providers/transaction_provider.dart';

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
          final paidBills = bills.where((bill) => bill['status'] == 'PAID').toList();

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
                        child: Text(
                          'Riwayat Pembayaran',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      
                      if (paidBills.isEmpty)
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
                                    child: Icon(Icons.history_edu, size: 64, color: AppTheme.primaryGreen.withOpacity(0.5)),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'Belum ada riwayat pembayaran',
                                    style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500, fontSize: 16),
                                  ),
                                ],
                              ),
                           ),
                         )
                   ],
                 ),
              ),
              
              if (paidBills.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final bill = paidBills[index];
                        final date = DateTime.parse(bill['updated_at'] ?? bill['created_at']);
                        final dateFormatted = DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(date);
                        
                        // Find successful transaction ID
                        final transactions = bill['transactions'] as List?;
                        final successTx = transactions?.firstWhere(
                          (tx) => tx['payment_status'] == 'settlement', 
                          orElse: () => null
                        );

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
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        currencyFormatter.format(double.parse(bill['amount'])),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryGreen,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.green.shade100),
                                        ),
                                        child: const Text('LUNAS', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                              if (successTx != null) ...[
                                const SizedBox(height: 16),
                                const Divider(height: 1, color: Colors.grey),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: TextButton.icon(
                                    onPressed: () async {
                                      final urlString = await ref.read(transactionProvider.notifier).getDownloadUrl(successTx['id']);
                                      if (urlString != null) {
                                        final url = Uri.parse(urlString);
                                        if (await canLaunchUrl(url)) {
                                          await launchUrl(url, mode: LaunchMode.externalApplication);
                                        }
                                      } else {
                                        if (context.mounted) {
                                           ScaffoldMessenger.of(context).showSnackBar(
                                             const SnackBar(content: Text('Gagal mendapatkan link download')),
                                           );
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.download_rounded, size: 18, color: AppTheme.primaryGreen),
                                    label: const Text('Unduh Bukti Bayar', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                                    style: TextButton.styleFrom(
                                      backgroundColor: AppTheme.primaryGreen.withOpacity(0.05),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              ]
                            ],
                          ),
                        );
                      },
                      childCount: paidBills.length,
                    ),
                  ),
                ),
            ],
          );
        },
        error: (err, stack) => Center(child: Text('Gagal memuat riwayat: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
