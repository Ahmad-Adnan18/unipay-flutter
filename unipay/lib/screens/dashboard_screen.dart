// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:unipay/core/theme.dart';
import 'package:unipay/providers/nav_provider.dart';
import 'package:unipay/screens/bills_screen.dart';
import 'package:unipay/screens/help_screen.dart';
import 'package:unipay/screens/news_detail_screen.dart';
import 'package:unipay/screens/news_list_screen.dart';
import '../providers/bill_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../services/news_service.dart';
import '../widgets/ktm_card.dart';
import 'payment_method_screen.dart';
import 'notification_screen.dart';

import 'package:flutter/services.dart';

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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light, // for iOS
      ),
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: SafeArea(
          child: RefreshIndicator(
          onRefresh: () {
            ref.refresh(newsProvider);
            return ref.refresh(billsProvider.future);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
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
                    Consumer(
                      builder: (context, ref, child) {
                        final notifState = ref.watch(notificationProvider);
                        final hasUnread = notifState.unreadCount > 0;
                        
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen()));
                              },
                              icon: const Icon(Icons.notifications_outlined),
                            ),
                            if (hasUnread)
                              Positioned(
                                right: 10,
                                top: 10,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
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
                         // Switch to Bills tab (Index 1)
                         ref.read(bottomNavIndexProvider.notifier).state = 1;
                      }),
                    _buildQuickAction(context, Icons.history, 'Riwayat', Colors.orange,
                      onTap: () {
                        // Switch to History tab (Index 2)
                        ref.read(bottomNavIndexProvider.notifier).state = 2;
                      }),
                    _buildQuickAction(context, Icons.newspaper, 'Berita', Colors.purple,
                      onTap: () {
                         Navigator.push(context, MaterialPageRoute(builder: (context) => const NewsListScreen()));
                      }),
                    _buildQuickAction(context, Icons.help_outline, 'Bantuan', Colors.green,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpScreen()));
                      }),
                  ],
                ),

                const SizedBox(height: 32),

                // Unpaid Bills Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tagihan Belum Lunas',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    // Show "Lihat Semua" only if we have logic for it, or rely on Quick Action.
                    // For now, let's keep it clean or add it if bills count > 3
                  ],
                ),
                const SizedBox(height: 12),
                billsAsync.when(
                  data: (bills) {
                    final unpaidBills = bills.where((bill) => bill['status'] == 'UNPAID').toList();
                    if (unpaidBills.isEmpty) {
                      return _buildEmptyState();
                    }
                    
                    // Show max 3 bills logic
                    final displayBills = unpaidBills.take(3).toList();
                    
                    return Column(
                      children: [
                        ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: displayBills.length,
                          itemBuilder: (context, index) {
                             final bill = displayBills[index];
                             return _buildBillCard(context, bill, currencyFormatter);
                          },
                        ),
                        if (unpaidBills.length > 3)
                          TextButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const BillsScreen()));
                            }, 
                            child: const Text("Lihat Semua Tagihan"),
                          ),
                      ],
                    );
                  },
                  error: (err, _) => const Text('Gagal memuat tagihan'),
                  loading: () => const Center(child: CircularProgressIndicator()),
                ),

                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // News Carousel
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Kabar Kampus',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 160,
                  child: newsAsync.when(
                    data: (newsList) {
                      if (newsList.isEmpty) return const Center(child: Text("Belum ada berita"));
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        itemCount: newsList.length,
                        itemBuilder: (context, index) {
                          final news = newsList[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => NewsDetailScreen(news: news)));
                            },
                            child: Container(
                              width: 280,
                              margin: const EdgeInsets.only(right: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08), 
                                    blurRadius: 12, 
                                    offset: const Offset(0,4)
                                  )
                                ]
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Stack(
                                  children: [
                                    // Background Image
                                    Positioned.fill(
                                      child: news['image_url'] != null 
                                        ? Image.network(
                                            news['image_url'],
                                            fit: BoxFit.cover,
                                          )
                                        : Container(color: Colors.grey.shade200),
                                    ),
                                    
                                    // Gradient Overlay
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withOpacity(0.1),
                                              Colors.black.withOpacity(0.8),
                                            ],
                                            stops: const [0.5, 0.7, 1.0],
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Content
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primaryGreen,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Text(
                                                'KABAR KAMPUS',
                                                style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              news['title'],
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold, 
                                                fontSize: 14,
                                                height: 1.3
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              news['created_at'],
                                              style: TextStyle(color: Colors.grey.shade300, fontSize: 10),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
    ));
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
              border: Border.all(color: color.withOpacity(0.2)), 
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
     // ignore: unused_local_variable
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
