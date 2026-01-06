// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unipay/core/theme.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});


  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authNotifier = ref.watch(authProvider.notifier);
    final user = authNotifier.userData;

    final initials = user != null && user['name'] != null
        ? (user['name'] as String).split(' ').take(2).map((e) => e[0].toUpperCase()).join()
        : 'U';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      extendBodyBehindAppBar: true,
      appBar: AppBar(toolbarHeight: 0, elevation: 0, backgroundColor: Colors.transparent, systemOverlayStyle: SystemUiOverlayStyle.light),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Background
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryGreen, AppTheme.primaryGreen.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                  ),
                ),
                
                // AppBar Placeholder
                //  Positioned(
                //   top: 50,
                //   left: 20,
                //   child: GestureDetector(
                //     onTap: () => Navigator.pop(context),
                //     child: const Icon(Icons.arrow_back, color: Colors.white),
                //   )
                // ),
                 const Positioned(
                  top: 50,
                  child: Text('Profil Saya', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))
                ),

                // Avatar & Name (Centered)
                Positioned(
                  bottom: -60,
                  child: Column(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                          ],
                          image: user?['profile_photo_url'] != null
                              ? DecorationImage(
                                  image: NetworkImage(user!['profile_photo_url']),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: user?['profile_photo_url'] == null 
                            ? Center(
                                child: Text(
                                  initials,
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 70),

            Text(
              user?['name'] ?? 'Mahasiswa',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Text(
              user?['email'] ?? '-',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: Text(
                'Mahasiswa Aktif',
                style: TextStyle(color: AppTheme.primaryGreen, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 32),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                    _buildSectionHeader("Informasi Akademik"),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                           BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                        ]
                      ),
                      child: Column(
                        children: [
                           _buildListTile(Icons.badge_outlined, 'NIM', user?['nim'] ?? '-'),
                           Divider(height: 1, indent: 56, color: Colors.grey.shade100),
                           _buildListTile(Icons.school_outlined, 'Program Studi', user?['major'] ?? '-'),
                           Divider(height: 1, indent: 56, color: Colors.grey.shade100),
                           _buildListTile(Icons.calendar_today_outlined, 'Semester', user?['semester']?.toString() ?? '-'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    _buildSectionHeader("Kontak"),
                    const SizedBox(height: 12),
                     Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                           BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                        ]
                      ),
                      child: Column(
                        children: [
                           _buildListTile(Icons.phone_outlined, 'No HP', user?['phone'] ?? '-'),
                           Divider(height: 1, indent: 56, color: Colors.grey.shade100),
                           _buildListTile(Icons.location_on_outlined, 'Alamat', user?['address'] ?? '-'),
                        ],
                      ),
                    ),
                 ],
              ),
            ),
            
            const SizedBox(height: 48),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                     await ref.read(authProvider.notifier).logout();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Keluar Aplikasi', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title, 
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    );
  }

  Widget _buildListTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primaryGreen, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
