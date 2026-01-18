import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unipay/core/theme.dart';
import 'package:intl/intl.dart';
import '../providers/notification_provider.dart';
import 'bills_screen.dart';
import 'news_detail_screen.dart';
import 'payment_method_screen.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationProvider);
    final notifications = notificationState.notifications;
    final groupedNotifications = _groupNotifications(notifications);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: 0, 
        elevation: 0, 
        backgroundColor: Colors.transparent, 
        systemOverlayStyle: SystemUiOverlayStyle.light
      ),
      body: notificationState.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                 child: Stack(
                   alignment: Alignment.center,
                   clipBehavior: Clip.none,
                   children: [
                      // Background
                      Container(
                        height: 120, // Slightly shorter than profile
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.primaryGreen, AppTheme.primaryGreen.withOpacity(0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                        ),
                      ),
                      
                      // Title
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 20,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                             const Text(
                               'Notifikasi', 
                               style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                             ),
                          ],
                        )
                      ),

                      // Mark Read Actions floating below header? 
                      // Or just keep it clean. Let's put Mark Read as a small icon top right?
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 10,
                        right: 20,
                        child: notifications.isNotEmpty 
                          ? IconButton(
                              onPressed: () {
                                ref.read(notificationProvider.notifier).markAllAsRead();
                              },
                              icon: const Icon(Icons.done_all, color: Colors.white),
                              tooltip: 'Tandai Dibaca',
                            )
                          : const SizedBox(),
                      ),
                      
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 10,
                        left: 10,
                        child: IconButton(
                           onPressed: () => Navigator.pop(context),
                           icon: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                      ),
                   ],
                 ),
              ),

              if (notifications.isEmpty)
                 SliverFillRemaining(
                   child: _buildEmptyState(),
                 ),

              if (notifications.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 40),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                         final group = groupedNotifications[index];
                         return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(4, 0, 0, 12),
                                child: Text(
                                  group.header,
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              ...group.items.map((item) => _buildModernNotificationItem(context, item)),
                              const SizedBox(height: 12),
                            ],
                         );
                      },
                      childCount: groupedNotifications.length,
                    ),
                  ),
                ),
            ],
          ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ]
            ),
            child: Icon(Icons.notifications_none_rounded, size: 64, color: AppTheme.primaryGreen.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          Text(
            'Tidak ada notifikasi',
            style: TextStyle(color: Colors.grey.shade800, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Belum ada info terbaru untukmu saat ini',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildModernNotificationItem(BuildContext context, NotificationItem item) {
    final isUnread = !item.isRead;
    final isBill = item.type == NotificationType.bill;

    return GestureDetector(
      onTap: () => _handleTap(context, item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread ? Colors.white : const Color(0xFFFCFCFC),
          borderRadius: BorderRadius.circular(20),
          border: isUnread 
            ? Border.all(color: AppTheme.primaryGreen.withOpacity(0.3), width: 1)
            : Border.all(color: Colors.transparent),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF141414).withOpacity(0.04), // Very subtle shadow
              blurRadius: 16,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Icon
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isBill ? const Color(0xFFFFF4EC) : const Color(0xFFEAF9F6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        isBill ? Icons.receipt_long_rounded : Icons.campaign_rounded,
                        color: isBill ? const Color(0xFFFF8A00) : AppTheme.primaryGreen,
                        size: 24,
                      ),
                    ),
                    if (isUnread)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(width: 16),
                
                // 2. Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isBill ? Colors.orange.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isBill ? 'TAGIHAN' : 'INFO KAMPUS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isBill ? Colors.orange.shade700 : Colors.blue.shade700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Text(
                            DateFormat('HH:mm').format(item.date),
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                          color: const Color(0xFF2D3142),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.message,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // 3. Action Button (Only for Bills)
            if (isBill)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _handlePayment(context, item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Bayar Sekarang',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, NotificationItem item) {
    if (item.type == NotificationType.bill) {
      if (item.originalData != null) {
         _handlePayment(context, item);
      } else {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const BillsScreen()));
      }
    } else {
       if (item.originalData != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => NewsDetailScreen(news: item.originalData)));
       }
    }
  }

  void _handlePayment(BuildContext context, NotificationItem item) {
    final bill = item.originalData;
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (_) => PaymentMethodScreen(
          billId: bill['id'], 
          billTitle: bill['title'], // Handle null safety if needed
          amount: double.tryParse(bill['amount'].toString()) ?? 0,
        )
      )
    );
  }

  List<_NotificationGroup> _groupNotifications(List<NotificationItem> items) {
    final Map<String, List<NotificationItem>> groups = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (var item in items) {
      final date = DateTime(item.date.year, item.date.month, item.date.day);
      String header;

      if (date == today) {
        header = 'Hari Ini';
      } else if (date == yesterday) {
        header = 'Kemarin';
      } else {
        header = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
      }

      if (!groups.containsKey(header)) {
        groups[header] = [];
      }
      groups[header]!.add(item);
    }

    return groups.entries.map((e) => _NotificationGroup(e.key, e.value)).toList();
  }
}

class _NotificationGroup {
  final String header;
  final List<NotificationItem> items;
  _NotificationGroup(this.header, this.items);
}

