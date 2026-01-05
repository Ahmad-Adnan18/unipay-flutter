# 🚀 Panduan Deployment (Online)

Jujur, deploy aplikasi Full Stack (Laravel + Flutter) itu ada triknya.
**JANGAN DEPLOY LARAVEL KE VERCEL** jika kamu pakai database **SQLite**. Kenapa? Karena Vercel itu "Serverless", setiap kali ada request baru, file database akan te-reset. Data kamu akan hilang terus.

Berikut adalah strategi deployment **Paling Aman & Gratis/Murah** untuk tugas kuliah:

---

## 🏛️ Bagian 1: Backend (Laravel) -> Railway / Render
Untuk backend, kita butuh server biasa (bukan serverless) agar database aman.

### Opsi A: Railway (Sangat Mudah, tapi Trial Berbayar/Limited)
1.  Push kodemu ke **GitHub**.
2.  Buka [Railway.app](https://railway.app/). Login via GitHub.
3.  **New Project** -> **Deploy from GitHub repo** -> Pilih repo `unipay-flutter`.
4.  Pilih folder root: `backend`.
5.  Railway akan mendeteksi Laravel. Klik **Add Database** -> **MySQL**.
6.  Di tab **Variables**, sesuaikan env Laravel dengan credentials MySQL yang dikasih Railway (`DB_HOST`, `DB_PASSWORD`, dll).
7.  Deploy! Kamu dapat URL `https://unipay-production.up.railway.app`.

### Opsi B: Render (Gratis tapi agak lambat)
1.  Buka [Render.com](https://render.com/).
2.  **New Web Service** -> Connect GitHub.
3.  Build Command: `composer install --no-dev --optimize-autoloader`.
4.  Start Command: `php artisan serve --host=0.0.0.0 --port=8080`.
5.  Kamu perlu bikin database MySQL terpisah (bisa di [Aiven](https://aiven.io/) gratis) lalu masukkan ke Environment Variables Render.

---

## 📱 Bagian 2: Frontend (Flutter) -> Vercel (Web Version)
Flutter bisa dijadikan Website (Flutter Web). Ini yang **COCOK** di-deploy ke Vercel.

### Cara 1: Deploy Otomatis (Recommended)
1.  Pastikan `unipay/lib/core/constants.dart` sudah diarahkan ke URL Backend yang ONLINE (bukan localhost lagi).
    ```dart
    // Contoh
    static const String baseUrl = 'https://unipay-production.up.railway.app/api'; 
    ```
2.  Masuk ke folder `unipay`.
3.  Buat file `vercel.json` di dalam folder `unipay`:
    ```json
    {
      "build": {
        "env": {
          "FLUTTER_CHANNEL": "stable"
        }
      },
      "routes": [
        { "src": "/[^.]+", "dest": "/", "status": 200 }
      ]
    }
    ```
4.  Push ke GitHub.
5.  Buka **Vercel Dashboard** -> **Add New Project**.
6.  Import Repo GitHub kamu.
7.  **Framework Preset:** None / Other.
8.  **Root Directory:** Pilih `unipay`.
9.  **Build Command:** `flutter build web --release`.
10. **Output Directory:** `build/web`.
11. Deploy!

### Cara 2: Manual (Drag & Drop)
1.  Di laptop, jalankan terminal di folder `unipay`:
    ```bash
    flutter build web --release --no-tree-shake-icons
    ```
2.  Tunggu selesai. Akan muncul folder `build/web`.
3.  Install **Vercel CLI** (`npm i -g vercel`).
4.  Ketik `vercel deploy` di folder `build/web`.
5.  Atau drag folder `web` tersebut ke dashboard Vercel manual.

---

## ⚠️ Peringatan untuk Sidang
Kalau dosen minta "Mana aplikasinya?", lebih baik **Tunjukkan APK di HP Android** (Localhost via IP Laptop).
Deployment itu berisiko error H-1 sidang.

**Saran Saya:**
1.  Tetap gunakan **Localhost** saat presentasi utama (karena paling cepat & stabil).
2.  Deployment hanya sebagai "Nilai Tambah" kalau ditanya "Sudah online belum?".
3.  Kalau mau deploy, fokus ke **Backend**-nya saja dulu online (pakai Railway). Aplikasi HP tetap install manual (APK) tapi nembak ke server online.
