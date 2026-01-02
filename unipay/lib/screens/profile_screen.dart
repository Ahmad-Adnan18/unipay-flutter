// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unipay/core/theme.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authNotifier = ref.watch(authProvider.notifier);
    final user = authNotifier.userData;

    // Use initials or 'U' if name unavailable
    final initials = user != null && user['name'] != null
        ? (user['name'] as String).split(' ').take(2).map((e) => e[0].toUpperCase()).join()
        : 'U';

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text('Profil Saya'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Avatar Profile
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryGreen, width: 2),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // User Info
            _buildInfoCard(
              context,
              icon: Icons.person_outline,
              label: 'Nama Lengkap',
              value: user?['name'] ?? 'Mahasiswa',
            ),
             const SizedBox(height: 16),
            _buildInfoCard(
              context,
              icon: Icons.email_outlined,
              label: 'Email',
              value: user?['email'] ?? 'email@mahasiswa.com',
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              context,
              icon: Icons.school_outlined,
              label: 'Program Studi',
              value: 'Teknik Informatika', // Hardcoded for MVP as it's not in User model yet
            ),
            
            const SizedBox(height: 48),
            
            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                   // Show confirmation dialog logic could go here
                   await ref.read(authProvider.notifier).logout();
                   // MainScreen/AuthWrapper handles redirect
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red.shade200),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('KELUAR APLIKASI'),
              ),
            ),
            
            const SizedBox(height: 24),
            Text(
              'UniPay v1.0.0',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, {required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
