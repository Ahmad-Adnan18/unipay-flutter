import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'bill_provider.dart';
import '../services/news_service.dart';

enum NotificationType { bill, news }

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime date;
  final NotificationType type;
  final bool isRead;
  final dynamic originalData;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    required this.type,
    required this.isRead,
    this.originalData,
  });
}

class NotificationState {
  final List<NotificationItem> notifications;
  final int unreadCount;
  final bool isLoading;

  NotificationState({
    required this.notifications,
    required this.unreadCount,
    this.isLoading = true,
  });

  NotificationState copyWith({
    List<NotificationItem>? notifications,
    int? unreadCount,
    bool? isLoading,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier(ref);
});

class NotificationNotifier extends StateNotifier<NotificationState> {
  final Ref _ref;
  DateTime? _lastCheckTime;

  NotificationNotifier(this._ref) : super(NotificationState(notifications: [], unreadCount: 0)) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheckStr = prefs.getString('last_notification_check_time');
    if (lastCheckStr != null) {
      _lastCheckTime = DateTime.parse(lastCheckStr);
    }
    // Listen to changes in dependencies
    _ref.listen<AsyncValue<List<dynamic>>>(billsProvider, (_, __) => _refreshNotifications());
    _ref.listen<AsyncValue<List<dynamic>>>(newsProvider, (_, __) => _refreshNotifications());
    
    // Initial fetch
    _refreshNotifications();
  }

  Future<void> _refreshNotifications() async {
    final billsAsync = _ref.read(billsProvider);
    final newsAsync = _ref.read(newsProvider);

    if (billsAsync.isLoading || newsAsync.isLoading) {
      state = state.copyWith(isLoading: true);
      return;
    }

    final List<NotificationItem> items = [];
    int unreadCount = 0;

    // 1. Process Bills (Persistent Action Items)
    // "Read" status for bills is irrelevant if they are UNPAID. 
    // BUT to avoid annoyance, we can say they are "read" if the user has seen the specific bill notification before?
    // Current Logic: UNPAID bills are ALWAYS urgent. Let's count them as "unread" until paid?
    // Industry standard: Critical alerts (Bills) persist as badge until resolved.
    
    billsAsync.whenData((bills) {
      final unpaidBills = bills.where((b) => b['status'] == 'UNPAID');
      for (var bill in unpaidBills) {
        final billDate = DateTime.parse(bill['created_at']);
        // Bill notification is "Seen" if it's older than last check.
        // But we might want it to be persistently Unread? 
        // Let's follow "Mark All as Read" behavior: if user clears it, it clears.
        final isMsgRead = _lastCheckTime != null && billDate.isBefore(_lastCheckTime!);

        items.add(NotificationItem(
          id: 'bill_${bill['id']}',
          title: 'Tagihan Belum Lunas',
          message: 'Segera bayar tagihan ${bill['title']}',
          date: billDate, 
          type: NotificationType.bill,
          isRead: isMsgRead, 
          originalData: bill,
        ));
      }
    });

    // 2. Process News (Temporal Items)
    newsAsync.whenData((newsList) {
      for (var news in newsList) {
        final newsDate = DateTime.parse(news['created_at']);
        final isMsgRead = _lastCheckTime != null && newsDate.isBefore(_lastCheckTime!);
        
        items.add(NotificationItem(
          id: 'news_${news['id']}',
          title: 'Berita Baru: ${news['title']}',
          message: news['content'] != null 
              ? (news['content'].length > 50 ? '${news['content'].substring(0, 50)}...' : news['content'])
              : 'Ketuk untuk membaca selengkapnya',
          date: newsDate,
          type: NotificationType.news,
          isRead: isMsgRead,
          originalData: news,
        ));
      }
    });

    // Sort by Date Descending
    items.sort((a, b) => b.date.compareTo(a.date));

    // Recalculate unreadCount based on items list
    unreadCount = items.where((i) => !i.isRead).length;

    state = NotificationState(
      notifications: items,
      unreadCount: unreadCount,
      isLoading: false,
    );
  }

  Future<void> markAllAsRead() async {
    final now = DateTime.now();
    _lastCheckTime = now;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_notification_check_time', now.toIso8601String());
    
    // Re-run refresh to update 'isRead' status for News. 
    // Note: Bills might stay "Unread" (i.e., !isRead = true) in the logic above because I hardcoded `isRead: false`.
    // Let's adjustment logic: Even bills should be "marked as read" in the sense of "I saw the notification"
    // but clearly distinguishing "Paid" vs "Seen" is better.
    // Implementation change: Let's allow marking Bills as "seen" (isRead=true) so the red dot goes away, 
    // but the notification remains in the list.
    
    // Quick fix: Update logic in _refreshNotifications to respect _lastCheckTime for Bills too?
    // No, standard UX: "Payment Due" usually stays red. 
    // User requested "Industry Standard". 
    // Standard: 
    // - Bank App: Unpaid bill = Permanent Red badge or separate "1" on bills icon.
    // - Notification Center: "New Bill Issued" (temporal).
    // Since we don't have "Event Sourcing", we are faking it. 
    // Let's make `markAllAsRead` clear the badge for NOW.
    
    _refreshNotifications();
  }
  
  // Refined Logic for _refreshNotifications to support "markAllAsRead" effect on Bills
  // If bill.created_at < _lastCheckTime, then it is "Read" (Seen).
}
