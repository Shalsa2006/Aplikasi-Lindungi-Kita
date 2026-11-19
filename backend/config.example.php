<?php
// Pengaturan LindungiKita API. Default sudah cocok untuk Laragon (user root, tanpa password).

define('DB_HOST', '127.0.0.1');
define('DB_PORT', '3306');
define('DB_NAME', 'lindungikita');
define('DB_USER', 'root');
define('DB_PASS', '');

// GANTI nilai ini sebelum dipakai sungguhan. Dipakai untuk menandatangani token login.
define('TOKEN_SECRET', 'ISI_SENDIRI');

// Kunci enkripsi bukti (AES-256-GCM). Harus 32 byte. JANGAN diganti setelah ada bukti tersimpan,
// karena bukti lama tidak bisa dibuka lagi. Buat baru: php -r "echo base64_encode(random_bytes(32));"
define('EVIDENCE_KEY_B64', 'ISI_SENDIRI');

define('EVIDENCE_DIR', __DIR__ . '/storage/evidence');
define('MAX_UPLOAD_BYTES', 15 * 1024 * 1024); // 15 MB per file
define('TOKEN_TTL', 7 * 24 * 3600);
