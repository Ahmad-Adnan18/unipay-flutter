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
*   **Pembayaran Mahasiswa:** Manajemen tagihan yang berpusat pada mahasiswa. Lihat total tagihan per mahasiswa dengan mudah.
*   **Data Prodi:** Manajemen Program Studi untuk standarisasi data (Dropdown selection).
*   **Tagihan Massal:** Buat tagihan untuk satu angkatan atau satu prodi sekaligus dengan mudah.
*   **Monitoring Transaksi:** Cek status pembayaran secara real-time.
*   **Student Management:** Kelola data akun mahasiswa dengan foto profil dan status aktif.

---

## 🛠️ Teknologi yang Digunakan

| Layer | Teknologi |
|-------|-----------|
| **Mobile App** | Flutter 3.x, Riverpod, Dio |
| **Backend** | Laravel 11, FilamentPHP 3 |
| **Database** | SQLite (dev) / MySQL (prod) |
| **Auth** | Laravel Sanctum |
| **Payment** | Midtrans (QRIS) |

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

# Atau di Mac/Linux:
# cp .env.example .env
```

#### 2.4 Generate Application Key
```bash
php artisan key:generate
```

#### 2.5 Setup Database (Pilih Salah Satu)

**Opsi A: SQLite (Lebih Mudah - Recommended untuk Development)**
```bash
# Buat file database SQLite
# Windows:
type nul > database\database.sqlite

# Mac/Linux:
# touch database/database.sqlite
```

Pastikan file `.env` sudah berisi:
```env
DB_CONNECTION=sqlite
```

**Opsi B: MySQL**
1. Buat database baru di MySQL (nama: `unipay_db`)
2. Update file `.env`:
```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=unipay_db
DB_USERNAME=root
DB_PASSWORD=
```

#### 2.6 Jalankan Migrasi Database
```bash
php artisan migrate
```

#### 2.7 (Opsional) Seed Data Dummy
```bash
php artisan db:seed
```

#### 2.8 Buat Akun Admin untuk Filament
```bash
php artisan make:filament-user
```
Ikuti prompt untuk membuat akun admin (email, name, password).

#### 2.9 Jalankan Server Backend
```bash
php artisan serve
```

**✅ Backend berjalan di:** `http://127.0.0.1:8000`  
**✅ Admin Panel:** `http://127.0.0.1:8000/admin`

> ⚠️ **PENTING:** Jangan tutup terminal ini! Biarkan server berjalan.

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

#### 3.3 Jalankan Emulator atau Hubungkan Device

**Opsi A: Android Emulator**
1. Buka Android Studio
2. Pergi ke **Tools > Device Manager**
3. Klik **Play** pada emulator yang tersedia

**Opsi B: Physical Device (HP Android)**
1. Aktifkan **Developer Options** di HP
2. Aktifkan **USB Debugging**
3. Hubungkan HP via USB
4. Pilih **Transfer Files** atau **File Transfer**

#### 3.4 Cek Device yang Terhubung
```bash
flutter devices
```
Pastikan ada minimal 1 device yang terdeteksi.

#### 3.5 Jalankan Aplikasi
```bash
flutter run -d chrome
```

**✅ Aplikasi akan terbuild dan terinstall otomatis di device/emulator.**

---

## 🔧 Konfigurasi Penting

### Konfigurasi API URL (Untuk Physical Device)

Jika menggunakan **HP fisik**, kamu perlu update `baseUrl` di file:
```
unipay/lib/core/constants.dart
```

Ubah ke alamat IP komputer kamu:
```dart
String get baseUrl {
  try {
    if (Platform.isAndroid) {
      return 'http://192.168.x.x:8000/api';  // Ganti dengan IP komputer
    }
    return 'http://127.0.0.1:8000/api';
  } catch (e) {
    return 'http://127.0.0.1:8000/api';
  }
}
```

> 💡 **Cara cek IP komputer:**
> - Windows: Buka CMD, ketik `ipconfig`, lihat **IPv4 Address**
> - Mac/Linux: `ifconfig` atau `ip addr`

### Konfigurasi Midtrans (Payment Gateway)

Edit file `backend/.env` dan masukkan Midtrans keys:
```env
MIDTRANS_SERVER_KEY=SB-Mid-server-xxxxx
MIDTRANS_CLIENT_KEY=SB-Mid-client-xxxxx
MIDTRANS_IS_PRODUCTION=false
```

> 📝 Dapatkan keys di: [Midtrans Dashboard](https://dashboard.sandbox.midtrans.com/) (Sandbox untuk testing)

---

## 📸 Cara Testing Pembayaran (Sandbox)

1. Buka Aplikasi **UniPay**, pilih tagihan, klik **Bayar**.
2. Akan muncul **QR Code**.
3. **Cara 1 (Simulator Mobile):** Scan QR tersebut pakai aplikasi Simulator (Android).
4. **Cara 2 (Paling Ampuh - Mock Notification):**
    *   Lihat **Order ID** di layar aplikasi (misal: `UKT-123-xxxxx`).
    *   Buka [Midtrans Mock Notification](https://simulator.sandbox.midtrans.com/index).
    *   Pilih **Mock Notification**, masukkan **Order ID**, pilih Status **Settlement**, klik **Apply**.
5. Kembali ke Aplikasi, status akan berubah menjadi **LUNAS** seketika (via Polling).
6. **Unduh Bukti Bayar:** Pergi ke menu Riwayat, pilih tagihan Lunas, klik "Unduh Bukti Bayar" untuk dapat PDF.

---

## ❓ Troubleshooting (Masalah Umum)

### ❌ Error: "Connection refused" atau "Failed to connect"
**Solusi:**
- Pastikan `php artisan serve` masih berjalan di terminal
- Untuk emulator Android, gunakan IP `10.0.2.2` bukan `127.0.0.1`
- Untuk physical device, gunakan IP komputer (bukan localhost)

### ❌ Error: "SQLSTATE - no such table"
**Solusi:**
```bash
cd backend
php artisan migrate:fresh
```

### ❌ Error: "flutter command not found"
**Solusi:**
- Pastikan Flutter sudah di-add ke PATH
- Restart terminal setelah instalasi Flutter
- Jalankan `flutter doctor` untuk cek instalasi

### ❌ Error: "No devices found"
**Solusi:**
- Pastikan emulator sudah running atau HP terhubung
- Untuk HP: aktifkan USB Debugging
- Jalankan `flutter devices` untuk cek device

### ❌ Admin Panel kosong / error
**Solusi:**
```bash
cd backend
php artisan filament:upgrade
php artisan optimize:clear
```

---

## 📁 Struktur Project

```
unipay-flutter/
├── backend/              # Backend Laravel
│   ├── app/             # Kode aplikasi (Controllers, Models, dll)
│   ├── database/        # Migrations & Seeders
│   ├── routes/          # API Routes
│   └── .env             # Environment config
│
└── unipay/              # Mobile App Flutter
    ├── lib/
    │   ├── core/        # Config, Theme, API Client
    │   ├── models/      # Data Models
    │   ├── providers/   # State Management (Riverpod)
    │   └── screens/     # UI Screens
    └── pubspec.yaml     # Dependencies
```

---

## 📝 Akun Demo

### Admin Panel (Web)
- **Email:** Buat sendiri via `php artisan make:filament-user`
- **URL:** `http://127.0.0.1:8000/admin`

### Mahasiswa (Mobile App)
Setelah menjalankan `php artisan db:seed`, gunakan akun berikut untuk login:
- **Email:** `test@example.com`
- **Password:** `password`

> 💡 **Catatan:** Jika password tidak berhasil, reset via Tinker:
> ```bash
> php artisan tinker
> ```
> ```php
> $user = \App\Models\User::where('email', 'test@example.com')->first();
> $user->password = bcrypt('password');
> $user->save();
> exit
> ```

---

## 👥 Tim Pengembang

**Tugas Akhir Mata Kuliah Pemrograman Berbasis Platform**
1. Ahmad Adnan 
2. Aziz Wahyudin
3. Karan Kemal
4. Intan Eka
---

## 📞 Butuh Bantuan?

Jika masih ada kendala:
1. Pastikan semua prasyarat sudah terinstall dengan benar
2. Jalankan `flutter doctor` dan selesaikan semua issue
3. Cek error message di terminal untuk debugging
4. Hubungi tim pengembang
