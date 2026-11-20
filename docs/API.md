# Dokumentasi REST API LindungiKita

Base URL (lokal): `http://localhost/lindungikita_api`
Dari emulator Android: `http://10.0.2.2/lindungikita_api`

## Konvensi

- Format: JSON (`Content-Type: application/json`), kecuali upload bukti memakai `multipart/form-data`.
- Respons sukses: `{ "ok": true, "data": ... }`
- Respons gagal: `{ "ok": false, "message": "..." }` dengan kode HTTP sesuai.
- Autentikasi: header `Authorization: Bearer <token>`. Token (HS256, berisi `uid`, `role`, `exp`) diperoleh dari `/auth/login` atau `/auth/register`.
- Peran: `pelapor`, `petugas`, `admin`.
- Nilai enum:
  - `kategori`: `seksual`, `kdrt`, `perundungan`, `lainnya`
  - `status`: `diterima`, `diverifikasi`, `ditangani`, `selesai`
  - `urgensi`: `rendah`, `sedang`, `tinggi`, `kritis`

## Kode HTTP

| Kode | Arti |
|---|---|
| 200 / 201 | Berhasil / berhasil dibuat |
| 400 | Input tidak valid |
| 401 | Belum login atau login salah |
| 403 | Peran tidak diizinkan atau akun nonaktif |
| 404 | Data atau endpoint tidak ditemukan |
| 409 | Email sudah terdaftar |
| 500 | Kesalahan server |

## Ringkasan endpoint

| Metode | Endpoint | Akses | Fungsi |
|---|---|---|---|
| GET | `/` | Publik | Info API |
| GET | `/health` | Publik | Cek server dan database |
| GET | `/resources` | Publik | Daftar lembaga bantuan |
| GET | `/stats/public` | Publik | Statistik agregat anonim |
| POST | `/auth/register` | Publik | Daftar akun pelapor |
| POST | `/auth/login` | Publik | Masuk, mendapat token |
| GET | `/me` | Semua peran | Profil dari token |
| POST | `/reports` | Publik / pelapor | Kirim laporan (anonim atau bernama) + bukti |
| POST | `/track` | Publik | Lacak kasus dengan nomor kasus + kode akses |
| POST | `/track/message` | Publik | Kirim chat pada kasus (tanpa akun) |
| GET | `/my-reports` | Pelapor | Daftar laporan milik akun |
| GET | `/my-reports/{id}` | Pelapor | Detail laporan milik akun |
| POST | `/my-reports/{id}/messages` | Pelapor | Chat ke pendamping |
| GET | `/contacts` | Pelapor | Daftar kontak tepercaya |
| POST | `/contacts` | Pelapor | Tambah kontak (maks 5) |
| DELETE | `/contacts/{id}` | Pelapor | Hapus kontak |
| POST | `/sos` | Pelapor | Kirim SOS dengan lokasi |
| GET | `/evidence/{id}` | Petugas / pemilik / kode akses | Unduh bukti terdekripsi |
| GET | `/staff/reports` | Petugas, admin | Antrian kasus (filter) |
| GET | `/staff/reports/{id}` | Petugas, admin | Detail kasus |
| PATCH | `/staff/reports/{id}` | Petugas | Ubah status, urgensi, catatan |
| POST | `/staff/reports/{id}/messages` | Petugas | Balas chat pelapor |
| GET | `/staff/sos` | Petugas, admin | Daftar SOS masuk |
| GET | `/admin/stats` | Admin | Statistik lengkap dashboard |
| GET | `/admin/staff` | Admin | Daftar petugas dan admin |
| POST | `/admin/staff` | Admin | Tambah akun petugas |
| PATCH | `/admin/users/{id}` | Admin | Aktif/nonaktif atau reset sandi petugas |
| GET | `/admin/audit` | Admin | Audit log (100 terakhir) |

## Detail endpoint penting

### POST /auth/register
Body: `{ "nama": "Sari", "email": "sari@mail.com", "password": "rahasia1", "no_hp": "0812..." }`
Respons 201: `{ "token": "...", "user": { "id", "nama", "email", "role": "pelapor", ... } }`
Aturan: kata sandi minimal 6 karakter, email unik. Kata sandi disimpan sebagai hash bcrypt.

### POST /auth/login
Body: `{ "email": "admin@lindungikita.id", "password": "Admin123!" }`
Respons 200: `{ "token": "...", "user": { ... } }`
Gagal: 401 `Email atau kata sandi salah.`, 403 `Akun dinonaktifkan.`

### POST /reports
Body JSON atau `multipart/form-data` (bukti pada field `bukti[]`).

| Field | Wajib | Keterangan |
|---|---|---|
| kategori | Ya | enum kategori |
| judul | Ya | maks 150 karakter |
| deskripsi | Ya | kronologi, maks 8000 karakter |
| anonim | Tidak | default `1`. Jika `0` wajib login |
| lokasi, wilayah | Tidak | teks bebas |
| tanggal_kejadian | Tidak | `YYYY-MM-DD` |
| bukti[] | Tidak | berkas bukti, dienkripsi AES-256-GCM |

Respons 201: `{ "case_no": "LK-261117-4B6BB", "access_code": "XXXX-XXXX", "urgensi": "tinggi", "bukti_tersimpan": 2 }`
Kode akses hanya ditampilkan sekali; server hanya menyimpan hash-nya. Urgensi dinilai otomatis dari kategori dan kata kunci.

### POST /track
Body: `{ "case_no": "LK-261117-4B6BB", "access_code": "ABCD-1234" }`
Respons: detail kasus, linimasa status, bukti (nama, ukuran, SHA-256, waktu), dan pesan chat. Identitas pelapor tidak dikembalikan.

### GET /evidence/{id}
Server mendekripsi berkas, memverifikasi SHA-256, lalu mengirimnya dengan header `X-Evidence-SHA256`. Jika hash tidak cocok, server menolak dengan 500 (bukti mungkin diubah). Akses bagi petugas, pemilik akun, atau dengan `?case_no=...&code=...`. Setiap pembukaan dicatat di audit log.

### GET /staff/reports
Query opsional: `status`, `kategori`, `q` (nomor kasus atau judul). Urutan: kasus belum selesai dahulu, lalu urgensi kritis ke rendah. Maksimal 200 baris.

### PATCH /staff/reports/{id}
Body (semua opsional): `{ "status": "diverifikasi", "urgensi": "tinggi", "catatan_petugas": "..." }`
Petugas pertama yang mengubah kasus tercatat sebagai penanggung jawab. Perubahan masuk audit log.

### POST /sos
Body: `{ "lat": -7.2575, "lng": 112.7521 }`
Respons 201: `{ "kontak": [ { "nama", "no_hp" } ], "peta": "https://maps.google.com/?q=lat,lng" }`
Petugas melihat SOS lewat `/staff/sos` (nama, nomor HP, koordinat, waktu).

### POST /admin/staff
Body: `{ "nama", "email", "password", "no_hp", "instansi", "wilayah" }`. Membuat akun berperan `petugas`.

### PATCH /admin/users/{id}
Body: `{ "aktif": 0 }` dan/atau `{ "password": "baru123" }`. Hanya untuk akun petugas.

## Keamanan

- Kata sandi: bcrypt (`password_hash`).
- Token: HS256 dengan masa berlaku (`exp`); peran dicek di setiap endpoint (RBAC).
- Bukti: AES-256-GCM, kunci di `config.php`, IV dan tag per berkas, SHA-256 diverifikasi setiap dibaca.
- Anonimitas: laporan anonim tidak menyimpan `user_id`; kode akses disimpan sebagai hash.
- Query: seluruhnya memakai prepared statement PDO (anti SQL injection).
- Audit log: login, perubahan kasus, pembukaan bukti, SOS, dan aksi admin.
