# 🛡️ PANDUAN LENGKAP: Setting Backup Multi-Server

Dokumen ini adalah panduan teknis untuk mengaktifkan backup otomatis ke **Lokasi Eksternal** (Server Lain / Google Drive / AWS S3).
Tujuannya adalah menerapkan **Prinsip 3-2-1 Backup**:
*   **3** Salinan data.
*   **2** Media penyimpanan berbeda.
*   **1** Lokasi off-site (di luar gedung/server utama).

---

## 1. Persiapan Awal
Pastikan project Anda sudah terinstall `spatie/laravel-backup` (Sudah default di project UniPay ini).

## 2. Pilihan Metode Backup Eksternal

### Opsi A: Backup ke Server Lain (via FTP/SFTP)
*Cocok jika kampus punya server fisik cadangan di gedung lain.*

1.  **Buka file** `config/filesystems.php`.
2.  Tambahkan disk baru di array `disks`:
    ```php
    'ftp_backup' => [
        'driver' => 'ftp',
        'host' => '192.168.1.100', // IP Server Cadangan
        'username' => 'user_backup',
        'password' => 'password_rahasia',
        'root' => '/home/backup/unipay', // Folder tujuan di server sana
    ],
    ```
3.  **Buka file** `config/backup.php`.
4.  Tambahkan disk tadi ke daftar tujuan:
    ```php
    'destination' => [
        'disks' => [
            'backups',      // Simpan di server utama (Local)
            'ftp_backup',   // DAN Simpan di server cadangan
        ],
    ],
    ```

### Opsi B: Backup ke Cloud (Amazon S3 / IDCloudHost / DigitalOcean)
*Cocok untuk keamanan maksimal anti-bencana (Kebakaran/Banjir).*

1.  **Install Driver S3** (Jalankan di terminal):
    ```bash
    composer require league/flysystem-aws-s3-v3 "^3.0"
    ```
2.  **Setting .env**:
    Isi kredensial storage objek Anda (Bisa beli di IDCloudHost/AWS - Murah, mulai Rp 50rb/bulan):
    ```env
    AWS_ACCESS_KEY_ID=xxxxxx
    AWS_SECRET_ACCESS_KEY=xxxxxx
    AWS_DEFAULT_REGION=us-east-1
    AWS_BUCKET=unipay-backups
    AWS_ENDPOINT=https://is3.cloudhost.id (Contoh jika pakai IDCloudHost)
    ```
3.  **Buka file** `config/filesystems.php`, pastikan disk `s3` sudah aktif (biasanya sudah bawaan Laravel).
4.  **Buka file** `config/backup.php`.
5.  Tambahkan `s3` ke daftar tujuan:
    ```php
    'destination' => [
        'disks' => [
            'backups',  // Local
            's3',       // Cloud
        ],
    ],
    ```

### Opsi C: Backup ke Google Drive
*Gratis, tapi setup agak rumit karena butuh Google Cloud Console.*

1.  **Install Adapter Google Drive**:
    ```bash
    composer require masbug/flysystem-google-drive-ext
    ```
2.  **Dapatkan** `ClientId`, `ClientSecret`, dan `RefreshToken` dari Google Cloud Console.
3.  **Setting** di `config/filesystems.php` (butuh konfigurasi driver custom).
    *(Saran: Lebih baik gunakan Opsi A atau B untuk kestabilan jangka panjang di environment produksi).*

---

## 3. Uji Coba

Setelah setting selesai, jalankan perintah ini di terminal server:

```bash
php artisan backup:run
```

Jika sukses, sistem akan melaporkan:
> Copying zip to disk named backups... Success.
> Copying zip to disk named ftp_backup... Success.

Sekarang data Anda sudah ada di 2 alam berbeda. Aman sentosa! 🔒🚀
