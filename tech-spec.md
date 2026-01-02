Ini adalah **PRD v2.0 (Revised & Robust Edition)** untuk **UniPay**.

Versi ini telah **dianalisis ulang** untuk menutupi celah logika (loop holes), mencegah *double payment*, menangani kegagalan jaringan, dan memastikan konsistensi data antara Aplikasi, Backend, dan Midtrans.

---

# PRD v2.0: UniPay (Robust Tuition Payment System)

**Version:** 2.0 (Anti-Error Edition)
**Date:** 2 Januari 2026
**Focus:** Reliability, Data Integrity, & Error Handling
**Tech Stack:** Flutter, Laravel 11, Midtrans Core API (Direct QRIS)

---

## 1. Analisis Risiko & Mitigasi (Perbedaan dari v1.0)

Sebelum masuk ke teknis, berikut adalah potensi error fatal di v1.0 dan solusinya di v2.0:

| Potensi Error | Solusi di v2.0 |
| --- | --- |
| **Double Transaction:** User klik "Bayar", keluar app, lalu klik "Bayar" lagi. Terbuat 2 order ID berbeda untuk tagihan yang sama. | **Idempotency Check:** Backend akan cek dulu apakah ada transaksi status `pending` untuk tagihan tersebut. Jika ada, kembalikan QR yang *existing*, jangan buat baru. |
| **Ghost Payment:** User bayar saat server down/webhook gagal. Di Midtrans lunas, di App masih tagihan. | **Sync Button (Manual Trigger):** Tambahkan tombol "Saya Sudah Bayar" di UI yang memaksa Backend menembak API Midtrans untuk cek status terbaru (Active inquiry). |
| **Infinite Polling:** Aplikasi terus-menerus cek status sampai baterai habis jika user tidak bayar-bayar. | **Smart Polling:** Batasi polling maksimal 2-3 menit. Setelah itu, tampilkan tombol "Cek Status" manual. |
| **QR Expired:** User scan QR yang sudah kadaluwarsa (misal > 15 menit). | **Auto-Expire UI:** UI Flutter harus punya timer mundur. Jika 00:00, tombol berubah jadi "Generate Ulang". |

---

## 2. Arsitektur Data Flow (Updated)

**Happy Path:**

1. Flutter -> Req Pay -> **Backend Cek Pending Transaction** -> (Jika Ada: Return Old QR) / (Jika Tidak: Hit Midtrans -> Return New QR).
2. Flutter -> Render QR.
3. User -> Bayar via E-Wallet.
4. Midtrans -> Webhook ke Backend -> Update DB `bills` = PAID.
5. Flutter -> Polling Status -> Dapat `SETTLEMENT` -> Show Success.

**Fallback Path (Jika Webhook Gagal):**

1. User -> Bayar -> Sukses di E-Wallet -> Webhook Midtrans Gagal (RTO).
2. Flutter -> Polling masih `PENDING`.
3. User -> Klik tombol "Refresh Status" / "Saya Sudah Bayar".
4. Flutter -> Req Status -> **Backend Hit Midtrans Get Status** -> Update DB -> Return `SETTLEMENT`.

---

## 3. Struktur Database (Optimized)

Penambahan kolom untuk *audit trail* dan pencegahan error.

### A. `bills` (Master Tagihan)

* `id`, `user_id`, `amount`, `title`, `due_date`.
* `status`: `UNPAID`, `PAID`.
* `locked_at`: `Timestamp` (Nullable). *Untuk mencegah race condition jika perlu.*

### B. `transactions` (Log Pembayaran)

* `id` (PK)
* `bill_id` (FK)
* `order_id` (Unique String) -> Format: `UKT-{bill_id}-{random_str}` (Jangan pakai Timestamp saja, bisa tabrakan).
* `qr_string` (Text) -> Simpan string QR agar bisa direturn ulang jika user kembali ke menu pembayaran.
* `expiry_time` (Timestamp) -> Waktu QR kadaluwarsa (biasanya +15 menit dari create).
* `payment_status`: `pending`, `settlement`, `expire`, `cancel`, `deny`.
* `midtrans_response` (JSON) -> Simpan *raw response* dari Midtrans untuk debugging jika ada masalah.

---

## 4. Logika Bisnis Backend (Crucial)

### Logic A: `createPayment(bill_id)`

*Endpoint ini tidak boleh asal buat transaksi baru.*

1. **Cek Tagihan:** Apakah `bill_id` statusnya `PAID`? Jika ya, return Error "Tagihan Lunas".
2. **Cek Pending Transaction:** Cari di tabel `transactions` where `bill_id` = input AND `payment_status` = `pending` AND `expiry_time` > NOW().
* **Jika Ada:** Return data transaksi tersebut (`qr_string`, `order_id`) yang sudah ada di DB. **(Hemat kuota API call & Mencegah double QR)**.
* **Jika Tidak Ada / Expired:**
1. Set status transaksi lama (jika ada) jadi `expire`.
2. Hit Midtrans Core API (Charge QRIS).
3. Simpan Transaksi Baru.
4. Return Data Baru.





### Logic B: `checkStatus(order_id)` (Sync Manual)

*Digunakan saat polling atau tombol refresh ditekan.*

1. Ambil data transaksi dari DB.
2. Jika status DB == `settlement`, return `settlement`.
3. **Active Inquiry:** Jika status DB == `pending`, Hit API **GET /v2/{order_id}/status** ke Midtrans.
4. Jika respon Midtrans != status DB, update status DB sesuai Midtrans.
5. Jika status akhirnya `settlement`, update tabel `bills` jadi `PAID` juga.
6. Return status terbaru.

---

## 5. Spesifikasi API & Response Code

### `POST /api/pay`

* **200 OK:** Transaksi berhasil dibuat/diambil.
```json
{
  "data": {
    "order_id": "UKT-101-X8Z92",
    "qr_string": "000201010212...",
    "amount": 5000000,
    "expiry_time": "2026-01-02 14:30:00" // Backend harus kirim ini
  }
}

```


* **400 Bad Request:** Tagihan sudah lunas.

### `GET /api/transactions/{order_id}/check`

* **200 OK:**
```json
{
  "data": {
    "status": "settlement", // atau pending, expire
    "paid_at": "2026-01-02 14:15:00"
  }
}

```



---

## 6. Implementasi Flutter (Error-Proof UI)

### A. State Management (Payment Screen)

Gunakan state enum: `Initial`, `Loading`, `QR_Ready`, `Success`, `Error`.

### B. Countdown Timer Widget

* Ambil `expiry_time` dari API response.
* Hitung selisih dengan `DateTime.now()`.
* Tampilkan hitung mundur.
* **Event:** Jika waktu habis (00:00), *disable* tampilan QR, munculkan tombol "Generate QR Baru". Jangan biarkan user scan QR expired!

### C. Smart Polling Logic

```dart
// Pseudo Code Flutter
void startPolling(String orderId) {
  int retryCount = 0;
  const maxRetries = 24; // 24 x 5 detik = 2 menit polling

  _timer = Timer.periodic(Duration(seconds: 5), (timer) async {
    retryCount++;
    
    // 1. Cek Status
    var status = await api.checkStatus(orderId);
    
    // 2. Jika Sukses
    if (status == 'settlement') {
      timer.cancel();
      navigateToSuccessScreen();
    } 
    // 3. Jika Expired/Cancel
    else if (status == 'expire') {
      timer.cancel();
      showExpiredUI();
    }
    // 4. Jika Max Retry tercapai (Timeout Polling)
    else if (retryCount >= maxRetries) {
      timer.cancel();
      // Ubah UI jadi tombol manual
      setState(() { showManualCheckButton = true; }); 
    }
  });
}

```

### D. Tombol "Saya Sudah Bayar" (Manual Check)

Jika polling berhenti (timeout) tapi user merasa sudah bayar, tombol ini akan memanggil API `checkStatus` satu kali. Ini solusi pamungkas jika webhook/polling macet.

### E. Screen Brightness

* `initState`: Set brightness 100%.
* `dispose`: Kembalikan brightness ke sistem default (jangan biarkan HP user silau terus setelah keluar aplikasi).

---

## 7. Skenario Uji Coba (QA Checklist)

Saat demo atau testing, lakukan skenario ini untuk membuktikan sistem anti-error:

1. **Idempotency Test:**
* Klik "Bayar" -> Muncul QR A.
* Back ke Home.
* Klik "Bayar" lagi -> **Harus Muncul QR A (Sama)**, bukan QR B.


2. **Expiry Test:**
* Tunggu timer habis di UI.
* Coba scan QR A (yang lama) di simulator -> Harusnya Gagal/Expire.
* Klik "Generate Baru" di App -> Muncul QR B.


3. **Payment Sync Test:**
* Matikan koneksi internet laptop (Server Laravel) sebentar (Simulasi webhook gagal).
* Bayar di Simulator.
* Nyalakan internet laptop.
* Di HP, klik "Refresh Status" -> Status harus berubah jadi Lunas (karena fitur Active Inquiry).



---

Berikut adalah **Phasing Plan (Tahapan Pengerjaan)** yang disusun secara logis agar kamu tidak pusing. Kita mulai dari fondasi Backend, baru pindah ke Frontend, dan terakhir fitur canggihnya.

Estimasi waktu total: **4-5 Hari** (asumsi kerja santai tapi fokus).

---

### **Phase 1: Backend Foundation & API (Hari 1)**

*Fokus: Pastikan otak sistem (Laravel) sudah siap menerima perintah sebelum membuat tubuhnya (Flutter).*

**To-Do List:**

1. **Setup Project:**
* Install Laravel 11.
* Setup Database MySQL (`unipay_db`).
* `php artisan install:api` (Install Sanctum).


2. **Database Migration & Seeding:**
* Buat tabel: `users`, `bills`, `transactions` (sesuai PRD v2.0).
* **Penting:** Buat *Seeder* untuk data dummy mahasiswa dan tagihan. Jangan input manual di PHPMyAdmin biar tidak capek kalau reset DB.


3. **Midtrans Setup:**
* Daftar Midtrans Sandbox.
* Ambil Server Key & Client Key.
* Install library: `composer require midtrans/midtrans-php`.
* Buat `MidtransService` di Laravel untuk handle logic request QR.


4. **API Development (Part 1 - Basic):**
* `POST /login` (Return token).
* `GET /bills` (Return list tagihan).
* **Testing:** Wajib test pakai **Postman**. Pastikan login dapat token, dan bisa ambil data bills pakai token itu.



**🎯 Checkpoint Phase 1:** Kamu bisa login di Postman dan melihat JSON data tagihan mahasiswa.

---

### **Phase 2: Flutter Connectivity & UI Base (Hari 2)**

*Fokus: Memastikan HP bisa ngobrol sama Laptop dan menampilkan data dasar.*

**To-Do List:**

1. **Setup Flutter:**
* `flutter create unipay`.
* Install Packages: `dio`, `flutter_riverpod`, `flutter_secure_storage`, `intl`, `google_fonts`.
* **Config HTTP:** Setup `Dio` dengan Base URL IP Laptop (jangan localhost!).


2. **Auth Feature:**
* Bikin UI Login sederhana.
* Logic simpan Token ke `SecureStorage`.
* Auto-redirect ke Dashboard jika ada token.


3. **Dashboard & Bill List:**
* Bikin UI Card Mahasiswa (Nama/NIM).
* Fetch API `/bills` dan tampilkan di `ListView`.
* Format uang pakai `intl` (biar jadi Rp 5.000.000, bukan 5000000).



**🎯 Checkpoint Phase 2:** Aplikasi bisa dibuka di HP, login, dan muncul list tagihan sesuai database laptop.

---

### **Phase 3: The Payment Core (Hari 3 - Paling Krucial)**

*Fokus: Logic Generate QR Code dan mencegah double transaction.*

**To-Do List:**

1. **API Development (Part 2 - Transaction):**
* Implementasi `POST /api/pay`.
* **Logic Backend:** Cek `pending transaction` di DB -> Kalau ada return yang lama, kalau tidak ada hit Midtrans.
* Test di Postman: Harus keluar `qr_string` dan `order_id`.


2. **Flutter Payment UI:**
* Install package: `qr_flutter`.
* Bikin halaman `PaymentDetailScreen`.
* Integrasi tombol "Bayar Sekarang" ke API `/api/pay`.
* Render `qr_string` dari API menjadi gambar QR Code di layar HP.


3. **Screen Brightness:**
* Pasang logic: Saat masuk halaman QR -> Brightness 100%. Saat keluar -> Reset.



**🎯 Checkpoint Phase 3:** User klik bayar, muncul Loading, lalu muncul QR Code di layar HP. Jika di-back dan masuk lagi, QR Code-nya tetap sama (tidak berubah).

---

### **Phase 4: Real-time Status & Reliability (Hari 4)**

*Fokus: Memastikan aplikasi tahu kalau pembayaran sudah lunas tanpa perlu refresh manual.*

**To-Do List:**

1. **API Development (Part 3 - Sync):**
* Implementasi `GET /api/transactions/{id}/status`.
* **Logic Backend:** Cek status di DB. Jika masih pending, tembak API Midtrans (`Get Status`) untuk update DB, baru return ke Flutter.


2. **Flutter Polling Logic:**
* Buat `Timer.periodic` setiap 5 detik di halaman QR.
* Hit API status.
* Jika status = `settlement`, matikan timer, pindah ke halaman "Sukses".


3. **Fail-safe UI:**
* Tambahkan tombol manual "Saya Sudah Bayar" (jika polling macet).
* Tambahkan Countdown Timer (UI saja) berdasarkan `expiry_time`.
* Jika waktu habis, ubah tombol jadi "Generate Ulang".



**🎯 Checkpoint Phase 4:**
Buka Simulator Midtrans di laptop -> Scan QR di HP -> Bayar -> Layar HP otomatis berubah jadi "Lunas" dalam hitungan detik.

---

### **Phase 5: Polishing & Demo Prep (Hari 5)**

*Fokus: Mempercantik aplikasi agar dosen terkesan.*

**To-Do List:**

1. **Error Handling:**
* Apa yang terjadi jika internet mati? Pasang `try-catch` di Dio dan munculkan `SnackBar` merah "Periksa Koneksi Anda".


2. **UI Cleanup:**
* Rapikan Padding, Margin, dan Warna (sesuai tema kampus hijau).
* Pastikan keyboard turun (unfocus) setelah ketik NIM.


3. **Skenario Demo:**
* Latihan presentasi sesuai skenario di PRD (Create -> Scan -> Auto Update).
* Siapkan data dummy yang "bersih" (jangan pakai nama user "asdasd").



---

**Tips Penting:**
Jangan loncat ke Phase 3 sebelum Phase 1 & 2 selesai sempurna. Error di koneksi dasar akan membuat fitur QR mustahil dikerjakan. Selamat ngoding!

