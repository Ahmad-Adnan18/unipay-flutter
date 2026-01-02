// lib/screens/payment_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:intl/intl.dart';
import 'package:unipay/core/theme.dart';
import '../providers/transaction_provider.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final int billId;
  final String billTitle;
  final double amount;

  const PaymentScreen({
    super.key,
    required this.billId,
    required this.billTitle,
    required this.amount,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _setBrightness(1.0);
    Future.microtask(() {
      // ignore: unused_result
      ref.read(transactionProvider.notifier).createTransaction(widget.billId);
    });
  }

  @override
  void dispose() {
    _stopPolling();
    _resetBrightness();
    super.dispose();
  }

  void _startPolling(String orderId) {
    if (_pollingTimer != null) return;
    
    // Poll every 5 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await _checkStatus(orderId);
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _checkStatus(String orderId) async {
    final status = await ref.read(transactionProvider.notifier).checkStatus(orderId);
    
    if (mounted) {
       if (status == 'settlement' || status == 'capture') {
         _stopPolling();
         _showSuccessDialog();
       } else if (status == 'expire') {
         _stopPolling();
         await ref.refresh(transactionProvider.notifier).createTransaction(widget.billId);
       }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 80),
              const SizedBox(height: 16),
              Text(
                'Pembayaran Berhasil!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Terima kasih. Pembayaran Anda telah dikonfirmasi.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); 
                    Navigator.of(context).pop(); 
                  },
                  child: const Text('KEMBALI KE DASHBOARD'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _setBrightness(double brightness) async {
    try {
      // ignore: deprecated_member_use
      await ScreenBrightness().setScreenBrightness(brightness);
    } catch (e) {
      debugPrint('Failed to set brightness: $e');
    }
  }

  Future<void> _resetBrightness() async {
    try {
      // ignore: deprecated_member_use
      await ScreenBrightness().resetScreenBrightness();
    } catch (e) {
      debugPrint('Failed to reset brightness: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionState = ref.watch(transactionProvider);
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    ref.listen(transactionProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        final orderId = next.value!['order_id'];
        _startPolling(orderId);
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      appBar: AppBar(
        title: const Text('Pembayaran'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ticket Container
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Text(
                        widget.billTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currencyFormatter.format(widget.amount),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(thickness: 1, height: 1),
                      const SizedBox(height: 24),
                      
                      transactionState.when(
                        data: (data) {
                          if (data == null) return const SizedBox.shrink();
                          
                          final qrString = data['qr_string'];
                          final expiryTime = DateTime.parse(data['expiry_time']);
                          final isExpired = DateTime.now().isAfter(expiryTime);

                          if (isExpired) {
                             return Column(
                               children: [
                                 Icon(Icons.broken_image_outlined, size: 80, color: Colors.grey.shade400),
                                 const SizedBox(height: 16),
                                 const Text('QR Code Kadaluwarsa'),
                                 const SizedBox(height: 16),
                                 ElevatedButton(
                                   onPressed: () async {
                                     await ref.refresh(transactionProvider.notifier).createTransaction(widget.billId);
                                   }, 
                                   child: const Text('Generate Ulang')
                                 )
                               ],
                             );
                          }

                          return Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade200, width: 2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: QrImageView(
                                  data: qrString,
                                  version: QrVersions.auto,
                                  size: 220.0,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.qr_code_scanner, color: Colors.grey, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Scan QRIS untuk membayar',
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Order ID: ${data['order_id']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold, 
                                    fontFamily: 'Courier',
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                        error: (err, stack) => Column(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 48),
                            const SizedBox(height: 16),
                            const Text('Terjadi Kesalahan', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(err.toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () async {
                                 await ref.read(transactionProvider.notifier).createTransaction(widget.billId);
                              },
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                        loading: () => const Padding(
                          padding: EdgeInsets.all(48.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              // Manual Check Button outside ticket
              transactionState.hasValue && transactionState.value != null ?
              TextButton.icon(
                 onPressed: () async {
                   final data = transactionState.value!;
                   await _checkStatus(data['order_id']);
                   if (mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(
                         content: Text('Memeriksa status pembayaran...'),
                         behavior: SnackBarBehavior.floating,
                       ),
                     );
                   }
                 },
                 icon: const Icon(Icons.sync, color: Colors.white),
                 label: const Text(
                   'Cek Status Pembayaran', 
                   style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                 ),
               ) : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}
