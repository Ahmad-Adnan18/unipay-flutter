// lib/screens/payment_method_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:unipay/core/theme.dart';
import 'payment_screen.dart';

class PaymentMethodScreen extends StatelessWidget {
  final int billId;
  final String billTitle;
  final double amount;

  const PaymentMethodScreen({
    super.key,
    required this.billId,
    required this.billTitle,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: const Text('Pilih Metode Pembayaran'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bill Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryGreen, AppTheme.primaryGreen.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    billTitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormatter.format(amount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // QRIS Section
            _buildSectionHeader('QRIS', 'Scan dengan aplikasi e-wallet apapun'),
            const SizedBox(height: 12),
            _buildPaymentOption(
              context: context,
              icon: Icons.qr_code_2,
              iconColor: Colors.purple,
              title: 'QRIS',
              subtitle: 'GoPay, OVO, DANA, LinkAja, dll',
              paymentType: 'qris',
            ),

            const SizedBox(height: 24),

            // E-Wallet Section
            _buildSectionHeader('E-Wallet', 'Bayar langsung dari aplikasi'),
            const SizedBox(height: 12),
            _buildPaymentOption(
              context: context,
              icon: Icons.account_balance_wallet,
              iconColor: Colors.green,
              title: 'GoPay',
              subtitle: 'Dompet digital Gojek',
              paymentType: 'gopay',
            ),
            const SizedBox(height: 8),
            _buildPaymentOption(
              context: context,
              icon: Icons.shopping_bag,
              iconColor: Colors.orange,
              title: 'ShopeePay',
              subtitle: 'Dompet digital Shopee',
              paymentType: 'shopeepay',
            ),

            const SizedBox(height: 24),

            // Virtual Account Section
            _buildSectionHeader('Virtual Account', 'Transfer via ATM/m-Banking'),
            const SizedBox(height: 12),
            _buildPaymentOption(
              context: context,
              icon: Icons.account_balance,
              iconColor: Colors.blue.shade800,
              title: 'BCA Virtual Account',
              subtitle: 'Transfer dari BCA',
              paymentType: 'va_bca',
            ),
            const SizedBox(height: 8),
            _buildPaymentOption(
              context: context,
              icon: Icons.account_balance,
              iconColor: Colors.orange.shade700,
              title: 'BNI Virtual Account',
              subtitle: 'Transfer dari BNI',
              paymentType: 'va_bni',
            ),
            const SizedBox(height: 8),
            _buildPaymentOption(
              context: context,
              icon: Icons.account_balance,
              iconColor: Colors.blue,
              title: 'BRI Virtual Account',
              subtitle: 'Transfer dari BRI',
              paymentType: 'va_bri',
            ),
            const SizedBox(height: 8),
            _buildPaymentOption(
              context: context,
              icon: Icons.account_balance,
              iconColor: Colors.blue.shade900,
              title: 'Mandiri Virtual Account',
              subtitle: 'Transfer dari Mandiri',
              paymentType: 'va_mandiri',
            ),
            const SizedBox(height: 8),
            _buildPaymentOption(
              context: context,
              icon: Icons.account_balance,
              iconColor: Colors.red.shade700,
              title: 'Permata Virtual Account',
              subtitle: 'Transfer dari Permata',
              paymentType: 'va_permata',
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String paymentType,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentScreen(
                billId: billId,
                billTitle: billTitle,
                amount: amount,
                paymentType: paymentType,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
