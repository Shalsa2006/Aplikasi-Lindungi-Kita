# LindungiKita

Aplikasi mobile pelaporan kekerasan dan perundungan secara anonim. Pelapor bisa melapor tanpa akun, melampirkan bukti terenkripsi, dan memantau penanganan kasusnya.

Dibuat dengan **Flutter** (aplikasi), **REST API PHP** (backend), dan **MySQL** (database).

## Fitur

- **Lapor anonim**: tanpa akun, pelapor mendapat nomor kasus dan kode akses untuk melacak laporan.
- **Bukti terenkripsi**: foto atau berkas dienkripsi AES-256-GCM dan diberi cap waktu serta hash SHA-256.
- **Lacak status kasus**: diterima, diverifikasi, sedang diproses, selesai.
- **Chat aman** antara pelapor dan petugas pendamping.
- **Tombol SOS**: mengirim lokasi darurat ke petugas dan kontak tepercaya.
- **Panduan hak korban** dan daftar lembaga bantuan.
- **Statistik agregat** tanpa identitas.
- **Tiga peran**: Pelapor, Petugas (pendamping), dan Admin (statistik, kelola petugas, audit log).

## Bawaan (akun demo)

| Peran | Email | Kata sandi |
|---|---|---|
| Admin | admin@lindungikita.id | Admin123! |
| Petugas | petugas@lindungikita.id | Petugas123! |
| Pelapor | pelapor@lindungikita.id | Pelapor123! |

Data bawaan lain: tujuh lembaga bantuan (SAPA 129, Komnas Perempuan, LPSK, KPAI, Polisi 110, Ambulans 119).

## Struktur

```
backend/    REST API PHP dan skema database (database.sql)
frontend/   Aplikasi Flutter
docs/       Dokumentasi API dan koleksi Postman
```

## Menjalankan singkat

1. Nyalakan Laragon, taruh folder `backend` di `C:\laragon\www\lindungikita_api`, lalu impor `database.sql` ke MySQL.
2. Salin `config.example.php` menjadi `config.php`, lalu isi `TOKEN_SECRET` dan `EVIDENCE_KEY_B64`.
3. Di folder `frontend`, jalankan `flutter pub get` lalu `flutter run`.