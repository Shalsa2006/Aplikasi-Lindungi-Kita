# LindungiKita

Aplikasi mobile (Flutter) untuk pelaporan kekerasan & perundungan yang aman dan anonim, dengan REST API PHP + MySQL (Laragon).

```
LindungiKita/
├── frontend/    Aplikasi Flutter (lib/, pubspec.yaml, setup_android.ps1)
├── backend/     REST API PHP + database.sql  -> disalin ke Laragon
└── README.md
```

## Akun bawaan (dari database.sql)
| Peran   | Email                    | Kata sandi    |
|---------|--------------------------|---------------|
| Admin   | admin@lindungikita.id    | Admin123!     |
| Petugas | petugas@lindungikita.id  | Petugas123!   |
| Pelapor | pelapor@lindungikita.id  | Pelapor123!   |

Pelapor bisa mendaftar sendiri lewat aplikasi. Akun petugas hanya dibuat oleh Admin (menu Petugas).

## Langkah 1 - Backend di Laragon
1. Jalankan Laragon, klik **Start All** (Apache + MySQL).
2. Salin (atau pindahkan) folder `backend` ke `C:\laragon\www\` lalu ganti namanya menjadi **`lindungikita_api`**
   (hasil akhir: `C:\laragon\www\lindungikita_api\index.php`).
3. Impor database: buka terminal Laragon, masuk ke folder tersebut, jalankan
   `mysql -u root < database.sql`
   (atau HeidiSQL -> File -> Run SQL file -> `database.sql`).
4. Tes di browser: `http://localhost/lindungikita_api/health`
   harus menampilkan `{"ok":true,"data":{"status":"ok",...}}`.
   Bila menampilkan 404, pakai `http://localhost/lindungikita_api/index.php/health` (mod_rewrite belum aktif).
5. Pengaturan DB ada di `backend/config.php` (default Laragon: user `root`, tanpa sandi).
   Ganti `TOKEN_SECRET` dan `EVIDENCE_KEY_B64` sebelum dipakai sungguhan.

## Langkah 2 - Aplikasi Flutter di VS Code
1. Pasang Flutter SDK + Android Studio (emulator) dan ekstensi VS Code **Flutter** & **Dart**.
2. Di VS Code: `File -> Open Folder...` -> pilih folder `frontend`.
3. Di terminal VS Code:
   ```
   cd frontend
   .\setup_android.ps1
   ```
   Skrip membuat folder android/ios, menjalankan `flutter pub get`, dan menambah izin internet,
   lokasi, serta HTTP lokal ke `AndroidManifest.xml`.
4. Jalankan emulator, lalu `flutter run` (atau F5 di VS Code).

### Alamat server di aplikasi
- **Emulator Android**: default `http://10.0.2.2/lindungikita_api` (sudah benar, tidak perlu diubah).
- **HP asli**: HP dan PC satu Wi-Fi. Cari IP PC (`ipconfig`, mis. 192.168.1.10), lalu di aplikasi tekan ikon
  gear di layar Login -> isi `http://192.168.1.10/lindungikita_api` -> **Tes koneksi** -> Simpan.
  Izinkan Apache di Windows Firewall bila tidak tersambung.

## Koneksi database di VS Code
Pasang ekstensi **SQLTools** + **SQLTools MySQL/MariaDB driver**, lalu tambah koneksi baru:
driver MySQL, server `127.0.0.1`, port `3306`, database `lindungikita`, username `root`, password kosong.
Connect, lalu lihat tabel `users`, `reports`, `evidence`, dst.
Impor database ulang kapan saja (di folder backend): `mysql -u root < database.sql`.

## Fitur
- Login/Register, 3 peran terpisah: **Pelapor**, **Petugas/Pendamping**, **Admin**, masing-masing punya beranda sendiri.
- Pelapor: lapor anonim tanpa akun (dapat nomor kasus + kode akses), lapor bernama, unggah bukti, lacak status,
  chat aman, tombol SOS (lokasi ke kontak tepercaya via WhatsApp/SMS), panduan hak korban, lembaga bantuan, statistik publik.
- Petugas: antrian kasus (urut urgensi), filter/cari, ubah status & urgensi, catatan, chat, lihat bukti, feed SOS.
  Identitas pelapor anonim tidak pernah dikirim ke petugas.
- Admin: dashboard statistik per status/jenis/urgensi/wilayah/hari, kelola akun petugas (tambah, nonaktifkan, reset sandi), audit log.
- Bukti: dienkripsi AES-256-GCM di server, disimpan dengan stempel waktu + hash SHA-256 yang diverifikasi setiap dibuka.

## Endpoint utama
`POST /auth/register`, `POST /auth/login`, `GET /me`, `POST /reports` (multipart), `POST /track`, `POST /track/message`,
`GET /my-reports`, `GET/POST/DELETE /contacts`, `POST /sos`, `GET /evidence/{id}`,
`GET/PATCH /staff/reports`, `POST /staff/reports/{id}/messages`, `GET /staff/sos`,
`GET /admin/stats`, `GET/POST /admin/staff`, `PATCH /admin/users/{id}`, `GET /admin/audit`, `GET /resources`, `GET /stats/public`.

## Catatan
- Kode ini belum dijalankan di perangkat nyata. Bila `flutter run` menampilkan error kompilasi, kirim teks errornya agar diperbaiki.
- Penilaian urgensi otomatis hanya berbasis kata kunci sederhana; petugas selalu bisa mengubahnya.
- Untuk produksi: wajib HTTPS, ganti kunci rahasia, batasi CORS, dan tambahkan pembatasan percobaan login.
