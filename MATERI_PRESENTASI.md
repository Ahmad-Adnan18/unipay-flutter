# Materi Presentasi Tugas Akhir: UniPay
**Mata Kuliah:** Pemrograman Berbasis Platform
**Topik:** Aplikasi Pembayaran Uang Kuliah (UKT) Digital
**Oleh:** [Nama Anda] - [NIM Anda]

---

## 1. Pendahuluan (Latar Belakang)
**Masalah:**
*   **Antrian Manual:** Proses pembayaran di loket kampus sering menyebabkan antrian panjang.
*   **Human Error:** Pencatatan manual rawan kesalahan input data.
*   **Tidak Real-time:** Mahasiswa sering harus menunggu validasi manual berhari-hari untuk melihat status "Lunas".
*   **Kehilangan Bukti:** Kertas slip pembayaran mudah hilang atau rusak.

**Solusi yang Ditawarkan:**
*   **UniPay**: Sebuah sistem pembayaran digital terintegrasi yang menghubungkan Mahasiswa (Mobile App) dan Bagian Keuangan (Web Admin) secara real-time.

---

## 2. Arsitektur Sistem (Platform-Based Tech Stack)
Sistem ini dibangun menggunakan konsep **Client-Server Architecture** yang memisahkan frontend dan backend secara *loose-coupled*.

### A. Mobile Application (Client Side)
*   **Framework:** Flutter (Dart).
*   **Platform:** Android & iOS (Cross-platform).
*   **Fitur Utama:**
    *   Melihat tagihan (Unpaid Bills).
    *   Generate QR Code Pembayaran.
    *   Cek Riwayat Transaksi.
*   **Teknologi:** `flutter_riverpod` (State Management), `dio` (API Request).

### B. Backend API (Server Side)
*   **Framework:** Laravel 11 (PHP).
*   **Fungsi:** Restful API Provider.
*   **Security:** Laravel Sanctum (Token based Authentication).
*   **Database:** MySQL (Relational DB).
*   **Role:** Menyimpan data User, Tagihan (Bill), dan Transaksi.

### C. Payment Gateway (3rd Party)
*   **Provider:** Midtrans (Sandbox/Production).
*   **Metode:** QRIS (GoPay, OVO, Dana, ShopeePay).
*   **Mekanisme:** Webhook / Polling untuk update status pembayaran otomatis.

---

## 3. Alur Kerja Sistem (Flowchart)
1.  **Admin (Web)** membuat tagihan untuk Mahasiswa A.
2.  **Mahasiswa (App)** menerima notifikasi/tagihan di Dashboard.
3.  Mahasiswa menekan tombol **"Bayar"**, aplikasi meminta QR Code ke Server.
4.  Server menghubungi **Midtrans** untuk generate QRIS.
5.  Mahasiswa scan QRIS dan membayar lewat e-Wallet.
6.  **Midtrans** memberitahu Server bahwa pembayaran sukses (Settlement).
7.  Server mengupdate database lokal menjadi **"PAID"**.
8.  Tampilan di Aplikasi Mahasiswa berubah menjadi **"LUNAS"** secara otomatis.

---

## 4. Demonstrasi Fitur Unggulan

### 📱 Sisi Mahasiswa (Flutter App)
*   **Smart Dashboard:** Hanya menampilkan tagihan yang *belum lunas* agar fokus.
*   **Instant Verification:** Tidak perlu upload bukti transfer. Pembayaran dideteksi sistem otomatis dalam hitungan detik.
*   **Profile:** Manajemen data diri dan keamanan logout.

### 🖥️ Sisi Admin (FilamentPHP Panel)
*   **Dashboard Statistik:** Grafik total pemasukan kampus secara real-time.
*   **Manajemen Tagihan:** Form mudah untuk membuat tagihan SPP/UKT.
*   **Monitoring:** Live monitoring status transaksi mahasiswa.

---

## 5. Implementasi Kode (Snippet Penting)

**Contoh Logic Pembayaran (Flutter):**
*Menggunakan Polling untuk mengecek status pembayaran secara berkala tanpa refresh manual.*

```dart
Future<void> _checkStatusPeriodically() async {
  _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
    final status = await ref.read(transactionController).checkStatus(_orderId);
    if (status == 'settlement') {
      timer.cancel(); // Stop jika sudah bayar
      _showSuccessDialog();
    }
  });
}
```

**Contoh Logic API (Laravel):**
*Idempotency Key untuk mencegah double-payment.*
```php
public function store(Request $request) {
    // Cek apakah sudah ada transaksi pending yang belum kadaluarsa?
    $pendingTx = Transaction::where('bill_id', $bill->id)
        ->where('payment_status', 'pending')
        ->first();
        
    if ($pendingTx) {
        return response()->json($pendingTx); // Return transaksi lama, jangan buat baru
    }
    
    // ... Buat transaksi baru ke Midtrans
}
```

---

## 6. Kesimpulan
UniPay berhasil mengimplementasikan solusi **End-to-End** untuk masalah pembayaran kampus.
*   **Efisien:** Memangkas waktu antrian.
*   **Akurat:** Menghilangkan human error admin.
*   **Modern:** Sesuai dengan gaya hidup mahasiswa (Cashless).

---
*Terima Kasih.*
