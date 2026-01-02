# UniPay 🎓💸
**Sistem Pembayaran Uang Kuliah (UKT) Digital Berbasis Mobile & Web**

UniPay adalah platform pembayaran digital yang dirancang untuk mempermudah transaksi pembayaran uang kuliah di lingkungan kampus. Sistem ini mengintegrasikan aplikasi mobile untuk mahasiswa dan panel admin web untuk staf keuangan, didukung oleh gateway pembayaran **Midtrans** untuk transaksi non-tunai (QRIS).

---

## 🌟 Fitur Unggulan

### 📱 Aplikasi Mahasiswa (Android/iOS)
*   **Cek Tagihan Real-time:** Notifikasi tagihan SPP/UKT yang belum dibayar.
*   **Pembayaran QRIS:** Generate QR Code dinamis untuk pembayaran via GoPay, OVO, Dana, dll.
*   **Riwayat Transaksi:** Bukti pembayaran tersimpan otomatis dan bisa diakses kapan saja.
*   **Smart Dashboard:** Tampilan bersih yang memprioritaskan tagihan aktif.

### 🏢 Admin Panel (Web)
*   **Dashboard Statistik:** Grafik total pemasukan dan jumlah tagihan pending.
*   **Manajemen Tagihan:** Buat, edit, dan pantau tagihan mahasiswa.
*   **Monitoring Transaksi:** Cek status pembayaran secara real-time.
*   **Student Management:** Kelola data akun mahasiswa.

---

## 🛠️ Teknologi yang Digunakan

### Frontend (Mobile App)
*   **Flutter:** Framework UI cross-platform.
*   **State Management:** Riverpod.
*   **Networking:** Dio.
*   **Storage:** Shared Preferences (Token).

### Backend (API & Admin)
*   **Laravel 11:** Framework PHP modern.
*   **FilamentPHP:** Admin Panel builder yang powerful.
*   **Database:** MySQL.
*   **Authentication:** Laravel Sanctum.

### Payment Gateway
*   **Midtrans:** Penyedia layanan pembayaran (QRIS).

---

## 🚀 Panduan Instalasi (Development)

### Prasyarat
*   PHP >= 8.2
*   Composer
*   Flutter SDK
*   MySQL

### 1. Setup Backend (Laravel)
```bash
cd backend
composer install
cp .env.example .env
# Konfigurasi database & Midtrans keys di .env
php artisan key:generate
php artisan migrate
php artisan db:seed # (Opsional: jika ada seeder)
php artisan serve
```
*Akses Admin Panel:* `http://localhost:8000/admin`

### 2. Setup Mobile App (Flutter)
```bash
cd unipay
flutter pub get
# Pastikan Emulator berjalan atau Device terhubung
flutter run
```

---

## 📝 Akun Demo (Default)

### Admin Panel
*   **Email:** `admin@unipay.com`
*   **Password:** `password`

### Mahasiswa (Test)
*   *Daftar sendiri melalui Admin Panel atau Database Seeder.*

---

## 📸 Cara Testing Pembayaran (Sandbox)
1.  Buka Aplikasi **UniPay**, pilih tagihan, klik **Bayar**.
2.  Akan muncul **QR Code**.
3.  Screenshot atau foto QR Code tersebut.
4.  Buka **[Midtrans Simulator](https://simulator.sandbox.midtrans.com/qris/index)**.
5.  Upload foto QR Code dan klik **Pay**.
6.  Kembali ke Aplikasi, status akan berubah menjadi **LUNAS** secara otomatis.

---
**Tugas Akhir Mata Kuliah Pemrograman Berbasis Platform**
