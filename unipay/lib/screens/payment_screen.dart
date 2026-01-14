// lib/screens/payment_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:unipay/core/theme.dart';
import '../providers/transaction_provider.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final int billId;
  final String billTitle;
  final double amount;
  final String paymentType;

  const PaymentScreen({
    super.key,
    required this.billId,
    required this.billTitle,
    required this.amount,
    required this.paymentType,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  bool _isCheckingStatus = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(transactionProvider.notifier).createTransaction(widget.billId, widget.paymentType);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _checkStatus(String orderId) async {
    if (_isCheckingStatus) return;
    
    setState(() => _isCheckingStatus = true);
    
    final status = await ref.read(transactionProvider.notifier).checkStatus(orderId);
    
    if (mounted) {
      setState(() => _isCheckingStatus = false);
      
      if (status == 'settlement' || status == 'capture') {
        _showSuccessDialog();
      } else if (status == 'expire') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi kadaluwarsa. Silakan buat transaksi baru.')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status: ${status ?? 'pending'} - Belum ada pembayaran'),
            behavior: SnackBarBehavior.floating,
          ),
        );
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
                    Navigator.of(context).pop(); // Pop to bills screen
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

  String _getPaymentTypeLabel(String type) {
    switch (type) {
      case 'qris': return 'QRIS';
      case 'gopay': return 'GoPay';
      case 'shopeepay': return 'ShopeePay';
      case 'va_bca': return 'BCA Virtual Account';
      case 'va_bni': return 'BNI Virtual Account';
      case 'va_bri': return 'BRI Virtual Account';
      case 'va_mandiri': return 'Mandiri Virtual Account';
      case 'va_permata': return 'Permata Virtual Account';
      default: return type.toUpperCase();
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

    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: Text(_getPaymentTypeLabel(widget.paymentType)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Payment Card
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
                          return _buildPaymentContent(data);
                        },
                        error: (err, stack) => _buildErrorContent(err),
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
              
              // Check Status Button
              transactionState.hasValue && transactionState.value != null
                ? ElevatedButton.icon(
                    onPressed: _isCheckingStatus 
                      ? null 
                      : () => _checkStatus(transactionState.value!['order_id']),
                    icon: _isCheckingStatus 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.refresh),
                    label: Text(_isCheckingStatus ? 'Memeriksa...' : 'Cek Status Pembayaran'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryGreen,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  )
                : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentContent(Map<String, dynamic> data) {
    final paymentType = data['payment_type'] ?? widget.paymentType;
    
    // QRIS or E-Wallet with QR
    if (paymentType == 'qris' || (data['qr_string'] != null && data['qr_string'].toString().isNotEmpty)) {
      return _buildQrisContent(data);
    }
    
    // Virtual Account
    if (paymentType.toString().startsWith('va_')) {
      return _buildVaContent(data);
    }
    
    // E-Wallet with deeplink
    if (paymentType == 'gopay' || paymentType == 'shopeepay') {
      return _buildEwalletContent(data);
    }
    
    return const Text('Metode pembayaran tidak dikenali');
  }

  Widget _buildQrisContent(Map<String, dynamic> data) {
    final qrString = data['qr_string'] ?? '';
    
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: qrString.toString().startsWith('http')
            ? Image.network(
                qrString,
                width: 220,
                height: 220,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    width: 220,
                    height: 220,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return SizedBox(
                    width: 220,
                    height: 220,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, color: Colors.grey.shade400, size: 48),
                          const SizedBox(height: 8),
                          Text('Gagal memuat QR', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  );
                },
              )
            : QrImageView(
                data: qrString,
                version: QrVersions.auto,
                size: 220.0,
              ),
        ),
        const SizedBox(height: 16),
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
  }

  Widget _buildVaContent(Map<String, dynamic> data) {
    final instructions = data['payment_instructions'] ?? {};
    final vaNumber = instructions['va_number'] ?? '-';
    final bank = instructions['bank'] ?? '';
    
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.account_balance, size: 40, color: Colors.blue.shade700),
        ),
        const SizedBox(height: 24),
        Text(
          'Nomor Virtual Account',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              vaNumber,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                fontFamily: 'Courier',
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.copy, size: 20),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: vaNumber));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nomor VA disalin!')),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            bank.toString().toUpperCase(),
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Transfer ke nomor VA di atas melalui ATM/m-Banking ${bank.toString().toUpperCase()}',
                  style: TextStyle(color: Colors.amber.shade900, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEwalletContent(Map<String, dynamic> data) {
    final instructions = data['payment_instructions'] ?? {};
    final deeplink = instructions['deeplink'] ?? '';
    final qrUrl = instructions['qr_url'] ?? data['qr_string'] ?? '';
    final paymentType = data['payment_type'] ?? widget.paymentType;
    
    return Column(
      children: [
        // Show QR if available
        if (qrUrl.toString().isNotEmpty) ...[
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.network(
              qrUrl,
              width: 180,
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Scan QR dengan aplikasi ${paymentType == 'gopay' ? 'Gojek' : 'Shopee'}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text('atau', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
        ],
        
        // Deeplink button
        if (deeplink.toString().isNotEmpty)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final uri = Uri.parse(deeplink);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Tidak dapat membuka aplikasi ${paymentType == 'gopay' ? 'Gojek' : 'Shopee'}')),
                    );
                  }
                }
              },
              icon: Icon(paymentType == 'gopay' ? Icons.account_balance_wallet : Icons.shopping_bag),
              label: Text('Buka ${paymentType == 'gopay' ? 'Gojek' : 'Shopee'}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: paymentType == 'gopay' ? Colors.green : Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
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
  }

  Widget _buildErrorContent(Object err) {
    final errorMessage = err.toString();
    final isAlreadyPaid = errorMessage.contains('400') || errorMessage.toLowerCase().contains('lunas');

    if (isAlreadyPaid) {
      return Column(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 80),
          const SizedBox(height: 16),
          Text(
            'Tagihan Lunas',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 8),
          const Text('Tagihan ini sudah dibayar.', textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('KEMBALI'),
          ),
        ],
      );
    }

    return Column(
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 48),
        const SizedBox(height: 16),
        const Text('Terjadi Kesalahan', style: TextStyle(fontWeight: FontWeight.bold)),
        Text(errorMessage.replaceAll('Exception:', ''), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            ref.read(transactionProvider.notifier).createTransaction(widget.billId, widget.paymentType);
          },
          child: const Text('Coba Lagi'),
        ),
      ],
    );
  }
}
