// lib/screens/history_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:unipay/core/theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';
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
                                  child: _DownloadReceiptButton(
                                    transactionId: successTx['id'],
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

// Separate stateful widget for download button with loading state
class _DownloadReceiptButton extends ConsumerStatefulWidget {
  final int transactionId;

  const _DownloadReceiptButton({required this.transactionId});

  @override
  ConsumerState<_DownloadReceiptButton> createState() => _DownloadReceiptButtonState();
}

class _DownloadReceiptButtonState extends ConsumerState<_DownloadReceiptButton> {
  bool _isLoading = false;

  Future<void> _downloadReceipt() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final urlString = await ref.read(transactionProvider.notifier).getDownloadUrl(widget.transactionId);
      
      if (urlString != null) {
        bool downloadSuccess = false;
        String? savePath;

        // Try Direct Download Logic
        try {
          Directory? downloadDir;
          if (Platform.isAndroid) {
            // Request permission first
            var status = await Permission.storage.status;
            if (!status.isGranted) {
              status = await Permission.storage.request();
            }
            
            // On Android 13+ (SDK 33), storage permission is not needed/grantable for media files but might be needed for other files or user-selected folders
            // Use standard download folder
            downloadDir = Directory('/storage/emulated/0/Download');
            if (!await downloadDir.exists()) {
               downloadDir = await getExternalStorageDirectory();
            }
          } else {
            downloadDir = await getDownloadsDirectory();
          }

          if (downloadDir != null) {
            if (!await downloadDir.exists()) await downloadDir.create(recursive: true);
            
            final fileName = 'Unipay_Receipt_${widget.transactionId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
            savePath = '${downloadDir.path}/$fileName';

            // Download using Dio
            final dio = Dio();
            await dio.download(urlString, savePath);
            downloadSuccess = true;
          }
        } catch (e) {
          // Fallback to browser if direct download fails (e.g. permission denied)
          debugPrint('Direct download failed: $e');
        }

        if (downloadSuccess && savePath != null) {
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(
                 content: Text('Disimpan di: $savePath'),
                 duration: const Duration(seconds: 5),
                 behavior: SnackBarBehavior.floating,
                 action: SnackBarAction(
                   label: 'BUKA',
                   textColor: Colors.white,
                   onPressed: () => OpenFilex.open(savePath!),
                 ),
               ),
             );
           }
        } else {
           // Fallback: Open in Browser
           final url = Uri.parse(urlString);
           final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
           
           if (!launched && mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(
                 content: Text('Tidak dapat membuka browser. Coba lagi nanti.'),
                 behavior: SnackBarBehavior.floating,
               ),
             );
           }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal mendapatkan link download. Coba lagi nanti.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: _isLoading ? null : _downloadReceipt,
      icon: _isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGreen),
            )
          : const Icon(Icons.download_rounded, size: 18, color: AppTheme.primaryGreen),
      label: Text(
        _isLoading ? 'Mengunduh...' : 'Unduh Bukti Bayar',
        style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
      ),
      style: TextButton.styleFrom(
        backgroundColor: AppTheme.primaryGreen.withOpacity(0.05),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
