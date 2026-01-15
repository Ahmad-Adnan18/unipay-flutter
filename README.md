# UniPay 🎓💸

**Sistem Pembayaran Uang Kuliah (UKT) Digital Berbasis Mobile & Web**

UniPay adalah platform pembayaran digital yang dirancang untuk mempermudah transaksi pembayaran uang kuliah di lingkungan kampus. Sistem ini mengintegrasikan aplikasi mobile untuk mahasiswa dan panel admin web untuk staf keuangan, didukung oleh gateway pembayaran **Midtrans** untuk transaksi non-tunai (QRIS) dan notifikasi WhatsApp otomatis.

---

## 🌟 Fitur Unggulan

### 📱 Aplikasi Mahasiswa (Android/iOS)
*   **Cek Tagihan Real-time:** Notifikasi tagihan SPP/UKT yang belum dibayar.
*   **Pembayaran QRIS:** Generate QR Code dinamis untuk pembayaran via GoPay, OVO, Dana, ShopeePay (dengan Deep Link).
*   **Riwayat Transaksi:** Bukti pembayaran tersimpan otomatis dan bisa diakses kapan saja.
*   **Direct Download Receipt:** Unduh bukti bayar PDF langsung ke penyimpanan HP (HTML Table Layout Professional).
*   **Smart Dashboard:** Tampilan bersih yang memprioritaskan tagihan aktif.

### 🏢 Admin Panel (Web)
*   **Dashboard Statistik:** Grafik total pemasukan dan jumlah tagihan pending.
*   **Pembayaran Mahasiswa:** Manajemen tagihan yang berpusat pada mahasiswa.
*   **WhatsApp Blast Reminder 🚀:** Kirim pengingat tagihan otomatis ke mahasiswa via WhatsApp (Fonnte) dengan fitur **Bulk Action**, **Deep Link**, dan **Anti-Spam Delay**.
*   **Reconciliation Reports 📊:** Export data transaksi ke Excel untuk keperluan rekonsiliasi dan audit keuangan.
*   **Data Prodi:** Manajemen Program Studi untuk standarisasi data (Dropdown selection).
*   **Tagihan Massal:** Buat tagihan untuk satu angkatan atau satu prodi sekaligus dengan mudah.
*   **Student Management:** Kelola data akun mahasiswa dengan foto profil dan status aktif.

---

## 🛠️ Teknologi yang Digunakan

| Layer | Teknologi |
|-------|-----------|
| **Mobile App** | Flutter 3.x, Riverpod, Dio, OpenFilex |
| **Backend** | Laravel 11, FilamentPHP 3.x |
| **Database** | SQLite (dev) / MySQL (prod) |
| **Auth** | Laravel Sanctum |
| **Payment** | Midtrans (QRIS, E-Wallet Deep Link) |
| **Notification** | Fonnte (WhatsApp Gateway) |
| **Export** | Filament Export (OpenSpout) |

---

## 📋 Prasyarat (Requirements)

Sebelum mulai, pastikan sudah terinstall:

| Software | Versi Minimum | Cek Instalasi |
|----------|---------------|---------------|
| **PHP** | 8.2+ | `php -v` |
| **Composer** | 2.x | `composer -V` |
| **Flutter SDK** | 3.2.3+ | `flutter --version` |
| **Git** | Any | `git --version` |

### 🔽 Download & Install (Jika Belum Ada)
- **PHP & Composer**: [Download Laragon](https://laragon.org/download/) (Windows, recommended) atau [XAMPP](https://www.apachefriends.org/)
- **Flutter SDK**: [Panduan Instalasi Flutter](https://docs.flutter.dev/get-started/install)
- **Git**: [Download Git](https://git-scm.com/downloads)
- **Android Studio**: [Download Android Studio](https://developer.android.com/studio) (untuk Android Emulator)
- **VS Code** (Opsional): [Download VS Code](https://code.visualstudio.com/)

---

## 🚀 Panduan Setup Project (Step-by-Step)

### 📥 Step 1: Clone Repository

```bash
https://github.com/Ahmad-Adnan18/unipay-flutter.git
```

---

### 🖥️ Step 2: Setup Backend (Laravel)

#### 2.1 Masuk ke folder backend
```bash
cd backend
```

#### 2.2 Install dependencies PHP
```bash
composer install
```

#### 2.3 Setup Environment
```bash
# Salin file environment
copy .env.example .env
# Atau di Mac/Linux: cp .env.example .env
```

#### 2.4 Generator Key & Config
```bash
php artisan key:generate
```

#### 2.5 Setup Database & Konfigurasi Penting
Edit file `.env` dan pastikan konfigurasi berikut terisi:

**Database:**
```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=unipay_db
DB_USERNAME=root
DB_PASSWORD=
```

**Midtrans (Payment):**
```env
MIDTRANS_SERVER_KEY=SB-Mid-server-xxxx
MIDTRANS_CLIENT_KEY=SB-Mid-client-xxxx
MIDTRANS_IS_PRODUCTION=false
```

**Fonnte (WhatsApp) & Queue:**
```env
FONNTE_TOKEN=your-token-here  # Daftar di fonnte.com
QUEUE_CONNECTION=sync         # Agar export & blast berjalan langsung di local
```

#### 2.6 Jalankan Migrasi Database
```bash
php artisan migrate
```

#### 2.7 Seed Data Dummy & Admin
```bash
php artisan db:seed
php artisan db:seed --class=ProductionAdminSeeder
```
**Login Admin Panel:**
- Email: `admin@gmail.com`
- Password: `password`

#### 2.8 Jalankan Server Backend
```bash
php artisan serve
```

---

### 📱 Step 3: Setup Mobile App (Flutter)

Buka **terminal baru** (jangan tutup terminal backend).

#### 3.1 Masuk ke folder Flutter
```bash
cd unipay
```

#### 3.2 Install dependencies Dart/Flutter
```bash
flutter pub get
```

#### 3.3 Konfigurasi URL API
Edit file `unipay/lib/core/constants.dart`:
```dart
// Sesuaikan dengan IP komputermu jika pakai HP Fisik
// Contoh: http://192.168.1.10:8000/api
```

#### 3.4 Jalankan Aplikasi
```bash
flutter run
```

---

## 📸 Fitur Baru: WhatsApp Blast & Export

### 1. Kirim Tagihan via WhatsApp (Admin)
1. Buka Admin Panel -> Menu **Pembayaran**.
2. Centang nama mahasiswa yang belum lunas.
3. Klik **Bulk Actions** (pojok kiri atas tabel) -> **Kirim WA Tagihan**.
4. Pesan otomatis terkirim dengan link `unipay://bills` (Deep Link).

### 2. Export Laporan Excel
1. Buka Admin Panel -> Menu **Transactions**.
2. Klik tombol **Export Laporan** di header.
3. File Excel akan otomatis terunduh (pastikan `QUEUE_CONNECTION=sync` di `.env`).

---

## 👥 Tim Pengembang

**Tugas Akhir Mata Kuliah Pemrograman Berbasis Platform**
1. Ahmad Adnan
2. Aziz Wahyudin
3. Karan Kemal
4. Intan Eka
---
