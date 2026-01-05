// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:unipay/core/theme.dart';
import '../providers/bill_provider.dart';
import '../providers/auth_provider.dart';
import '../services/news_service.dart';
import '../widgets/ktm_card.dart';
import 'payment_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider.notifier);
    final user = authState.userData;
    final billsAsync = ref.watch(billsProvider);
    final newsAsync = ref.watch(newsProvider);
    
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () {
            ref.refresh(newsProvider);
            return ref.refresh(billsProvider.future);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                      child: Text(
                        user?['name']?[0] ?? 'S',
                        style: TextStyle(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo, ${user?['name']?.split(' ')?.first ?? 'Mahasiswa'}! 👋',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now()),
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {}, // TODO: Notifications
                      icon: const Icon(Icons.notifications_outlined),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // KTM Digital Card
                KtmCard(
                  name: user?['name'] ?? 'Mahasiswa',
                  nim: user?['nim'] ?? '-',
                  major: user?['major'] ?? '-',
                  photoUrl: user?['profile_photo_url'],
                ),
                
                const SizedBox(height: 24),

                // Quick Actions
                const Text(
                  'Akses Cepat',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildQuickAction(context, Icons.receipt_long, 'Tagihan', Colors.blue, 
                      onTap: () {
                         // Scroll to bills or navigate
                      }),
                    _buildQuickAction(context, Icons.history, 'Riwayat', Colors.orange,
                      onTap: () {
                        // Navigate logic handled by main screen usually
                      }),
                    _buildQuickAction(context, Icons.newspaper, 'Berita', Colors.purple,
                      onTap: () {}),
                    _buildQuickAction(context, Icons.help_outline, 'Bantuan', Colors.green,
                      onTap: () {}),
                  ],
                ),

                const SizedBox(height: 32),

                // Unpaid Bills Section
                const Text(
                  'Tagihan Belum Lunas',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                billsAsync.when(
                  data: (bills) {
                    final unpaidBills = bills.where((bill) => bill['status'] == 'UNPAID').toList();
                    if (unpaidBills.isEmpty) {
                      return _buildEmptyState();
                    }
                    return ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: unpaidBills.length,
                      itemBuilder: (context, index) {
                         final bill = unpaidBills[index];
                         return _buildBillCard(context, bill, currencyFormatter);
                      },
                    );
                  },
                  error: (err, _) => const Text('Gagal memuat tagihan'),
                  loading: () => const Center(child: CircularProgressIndicator()),
                ),

                const SizedBox(height: 24),
                
                // News Carousel
                const Text(
                  'Kabar Kampus',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 160,
                  child: newsAsync.when(
                    data: (newsList) {
                      if (newsList.isEmpty) return const Center(child: Text("Belum ada berita"));
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: newsList.length,
                        itemBuilder: (context, index) {
                          final news = newsList[index];
                          return Container(
                            width: 250,
                            margin: const EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: const Offset(0,2))
                              ]
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                      image: news['image_url'] != null ? DecorationImage(
                                        image: NetworkImage(news['image_url']),
                                        fit: BoxFit.cover,
                                      ) : null,
                                    ),
                                    child: news['image_url'] == null 
                                      ? Center(child: Icon(Icons.image, color: Colors.grey.shade400)) 
                                      : null,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        news['title'],
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        news['created_at'],
                                        style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_,__) => const SizedBox(),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, IconData icon, String label, Color color, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade400, size: 40),
          const SizedBox(height: 8),
          const Text("Semua pembayaran lunas!", style: TextStyle(color: Colors.grey))
        ],
      ),
    );
  }

  Widget _buildBillCard(BuildContext context, Map<String, dynamic> bill, NumberFormat formatter) {
     final date = DateTime.parse(bill['due_date']);
     final dateFormatted = DateFormat('d MMM yyyy', 'id_ID').format(date);
     
     return Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200)
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      bill['title'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)
                    ),
                    child: const Text('UNPAID', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
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
                         style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 18),
                       ),
                     ],
                   ),
                   ElevatedButton(
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
                     style: ElevatedButton.styleFrom(
                       backgroundColor: AppTheme.primaryGreen,
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                     ),
                     child: const Text('Bayar'),
                   )
                ],
              )
            ],
          ),
        ),
     );
  }
}
