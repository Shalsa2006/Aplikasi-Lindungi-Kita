<?php
/**
 * LindungiKita REST API - satu pintu (front controller).
 * Semua respons JSON: { ok: bool, data: ..., message: ... }
 */
require_once __DIR__ . '/helpers.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Authorization, Content-Type');
header('Access-Control-Allow-Methods: GET, POST, PATCH, DELETE, OPTIONS');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }

set_exception_handler(function (Throwable $e) {
    error_log($e->getMessage());
    fail('Terjadi kesalahan di server: ' . $e->getMessage(), 500);
});

const KATEGORI = ['seksual', 'kdrt', 'perundungan', 'lainnya'];
const STATUS = ['diterima', 'diverifikasi', 'ditangani', 'selesai'];
const URGENSI = ['rendah', 'sedang', 'tinggi', 'kritis'];

$method = $_SERVER['REQUEST_METHOD'];
$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$base = rtrim(str_replace('\\', '/', dirname($_SERVER['SCRIPT_NAME'])), '/');
if ($base !== '' && strpos($path, $base) === 0) $path = substr($path, strlen($base));
$path = '/' . trim(preg_replace('#^/index\.php#', '', $path), '/');

function route(string $m, string $pattern, callable $fn): void {
    global $method, $path;
    if ($method !== $m) return;
    if (preg_match('#^' . $pattern . '$#', $path, $mt)) {
        array_shift($mt);
        $fn(...$mt);
        exit;
    }
}

// ================= UMUM =================
route('GET', '/', fn() => out([
    'app' => 'LindungiKita API', 'versi' => '1.0',
    'publik' => ['GET /health', 'GET /resources', 'GET /stats/public', 'POST /auth/register', 'POST /auth/login', 'POST /reports', 'POST /track', 'POST /track/message'],
    'pelapor' => ['GET /me', 'GET /my-reports', 'GET /my-reports/{id}', 'POST /my-reports/{id}/messages', 'GET /contacts', 'POST /contacts', 'DELETE /contacts/{id}', 'POST /sos', 'GET /evidence/{id}'],
    'petugas' => ['GET /staff/reports', 'GET /staff/reports/{id}', 'PATCH /staff/reports/{id}', 'POST /staff/reports/{id}/messages', 'GET /staff/sos'],
    'admin' => ['GET /admin/stats', 'GET /admin/staff', 'POST /admin/staff', 'PATCH /admin/users/{id}', 'GET /admin/audit'],
]));

route('GET', '/health', function () {
    db()->query('SELECT 1');
    out(['status' => 'ok', 'waktu' => date('c')]);
});

route('GET', '/resources', function () {
    out(db()->query('SELECT id,nama,kategori,kontak,deskripsi FROM resources ORDER BY id')->fetchAll());
});

route('GET', '/stats/public', function () {
    $pdo = db();
    $total = (int)$pdo->query('SELECT COUNT(*) FROM reports')->fetchColumn();
    $selesai = (int)$pdo->query("SELECT COUNT(*) FROM reports WHERE status='selesai'")->fetchColumn();
    $kat = $pdo->query('SELECT kategori, COUNT(*) AS jumlah FROM reports GROUP BY kategori')->fetchAll();
    $wil = $pdo->query("SELECT COALESCE(NULLIF(wilayah,''),'Tidak disebut') AS wilayah, COUNT(*) AS jumlah
                        FROM reports GROUP BY 1 ORDER BY jumlah DESC LIMIT 10")->fetchAll();
    out(['total' => $total, 'selesai' => $selesai, 'per_kategori' => $kat, 'per_wilayah' => $wil]);
});

// ================= AUTH =================
route('POST', '/auth/register', function () {
    $in = input();
    $nama = str($in, 'nama', 100);
    $email = strtolower(str($in, 'email', 150));
    $pass = trim((string)($in['password'] ?? ''));
    $hp = str($in, 'no_hp', 25);
    if ($nama === '') fail('Nama wajib diisi.');
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) fail('Format email tidak valid.');
    if (strlen($pass) < 6) fail('Kata sandi minimal 6 karakter.');
    $c = db()->prepare('SELECT id FROM users WHERE email=?');
    $c->execute([$email]);
    if ($c->fetch()) fail('Email sudah terdaftar.', 409);
    $st = db()->prepare("INSERT INTO users (nama,email,password_hash,role,no_hp) VALUES (?,?,?, 'pelapor', ?)");
    $st->execute([$nama, $email, password_hash($pass, PASSWORD_BCRYPT), $hp ?: null]);
    $id = (int)db()->lastInsertId();
    audit($id, 'register', $email);
    $u = ['id' => $id, 'nama' => $nama, 'email' => $email, 'role' => 'pelapor', 'no_hp' => $hp, 'instansi' => null, 'wilayah' => null];
    out(['token' => make_token($u), 'user' => $u], 201);
});

route('POST', '/auth/login', function () {
    $in = input();
    $email = strtolower(str($in, 'email', 150));
    $pass = trim((string)($in['password'] ?? ''));
    $st = db()->prepare('SELECT * FROM users WHERE email=?');
    $st->execute([$email]);
    $u = $st->fetch();
    if (!$u || !password_verify($pass, $u['password_hash'])) {
        audit($u['id'] ?? null, 'login_gagal', $email);
        fail('Email atau kata sandi salah.', 401);
    }
    if (!$u['aktif']) fail('Akun dinonaktifkan. Hubungi admin.', 403);
    audit((int)$u['id'], 'login', $u['role']);
    unset($u['password_hash']);
    out(['token' => make_token($u), 'user' => $u]);
});

route('GET', '/me', function () {
    $u = need_role('pelapor', 'petugas', 'admin');
    out($u);
});

// ================= PELAPOR: BUAT LAPORAN =================
route('POST', '/reports', function () {
    $in = input();
    $user = current_user(); // opsional: boleh tanpa akun
    $kategori = str($in, 'kategori', 20);
    $judul = str($in, 'judul', 150);
    $desk = str($in, 'deskripsi', 8000);
    if (!in_array($kategori, KATEGORI, true)) fail('Kategori tidak valid.');
    if ($judul === '' || $desk === '') fail('Judul dan kronologi wajib diisi.');
    $anonim = !isset($in['anonim']) || in_array((string)$in['anonim'], ['1', 'true', 'on'], true) ? 1 : 0;
    if (!$anonim && !$user) fail('Laporan bernama membutuhkan akun. Masuk dulu atau pilih anonim.', 401);
    $tgl = str($in, 'tanggal_kejadian', 10);
    if ($tgl !== '' && !preg_match('/^\d{4}-\d{2}-\d{2}$/', $tgl)) $tgl = '';
    $code = new_access_code();
    $urg = assess_urgency($kategori, $judul . ' ' . $desk);

    $pdo = db();
    for ($try = 0; $try < 5; $try++) {
        $caseNo = new_case_no();
        try {
            $st = $pdo->prepare('INSERT INTO reports (case_no,access_hash,user_id,anonim,kategori,judul,deskripsi,lokasi,wilayah,tanggal_kejadian,urgensi)
                                 VALUES (?,?,?,?,?,?,?,?,?,?,?)');
            $st->execute([
                $caseNo, password_hash($code, PASSWORD_BCRYPT),
                ($user && !$anonim) ? $user['id'] : null, $anonim, $kategori, $judul, $desk,
                str($in, 'lokasi', 200) ?: null, str($in, 'wilayah', 80) ?: null, $tgl ?: null, $urg,
            ]);
            break;
        } catch (PDOException $e) {
            if ($try === 4) throw $e; // bentrok nomor kasus -> coba lagi
        }
    }
    $rid = (int)$pdo->lastInsertId();
    $n = store_evidence($rid);
    audit($anonim ? null : ($user['id'] ?? null), 'laporan_baru', $caseNo);
    out(['case_no' => $caseNo, 'access_code' => $code, 'urgensi' => $urg, 'bukti_tersimpan' => $n], 201);
});

// ================= PELAPOR: LACAK TANPA AKUN =================
route('POST', '/track', function () {
    $in = input();
    $r = report_by_credentials(str($in, 'case_no', 30), str($in, 'access_code', 20));
    if (!$r) fail('Nomor kasus atau kode akses salah.', 404);
    out(load_report((int)$r['id'], false));
});

route('POST', '/track/message', function () {
    $in = input();
    $r = report_by_credentials(str($in, 'case_no', 30), str($in, 'access_code', 20));
    if (!$r) fail('Nomor kasus atau kode akses salah.', 404);
    $isi = str($in, 'isi', 3000);
    if ($isi === '') fail('Pesan kosong.');
    $st = db()->prepare("INSERT INTO messages (report_id,sender,isi) VALUES (?, 'pelapor', ?)");
    $st->execute([$r['id'], $isi]);
    out(load_report((int)$r['id'], false), 201);
});

// ================= PELAPOR: AKUN =================
route('GET', '/my-reports', function () {
    $u = need_role('pelapor');
    $st = db()->prepare('SELECT id,case_no,kategori,judul,status,urgensi,created_at,updated_at FROM reports WHERE user_id=? ORDER BY id DESC');
    $st->execute([$u['id']]);
    out($st->fetchAll());
});

route('GET', '/my-reports/(\d+)', function ($id) {
    $u = need_role('pelapor');
    $c = db()->prepare('SELECT id FROM reports WHERE id=? AND user_id=?');
    $c->execute([$id, $u['id']]);
    if (!$c->fetch()) fail('Laporan tidak ditemukan.', 404);
    out(load_report((int)$id, false));
});

route('POST', '/my-reports/(\d+)/messages', function ($id) {
    $u = need_role('pelapor');
    $c = db()->prepare('SELECT id FROM reports WHERE id=? AND user_id=?');
    $c->execute([$id, $u['id']]);
    if (!$c->fetch()) fail('Laporan tidak ditemukan.', 404);
    $isi = str(input(), 'isi', 3000);
    if ($isi === '') fail('Pesan kosong.');
    db()->prepare("INSERT INTO messages (report_id,sender,sender_id,isi) VALUES (?, 'pelapor', ?, ?)")->execute([$id, $u['id'], $isi]);
    out(load_report((int)$id, false), 201);
});

route('GET', '/contacts', function () {
    $u = need_role('pelapor');
    $st = db()->prepare('SELECT id,nama,no_hp FROM trusted_contacts WHERE user_id=? ORDER BY id');
    $st->execute([$u['id']]);
    out($st->fetchAll());
});

route('POST', '/contacts', function () {
    $u = need_role('pelapor');
    $in = input();
    $nama = str($in, 'nama', 100);
    $hp = preg_replace('/[^0-9+]/', '', str($in, 'no_hp', 25));
    if ($nama === '' || strlen($hp) < 8) fail('Nama dan nomor HP yang valid wajib diisi.');
    $n = db()->prepare('SELECT COUNT(*) FROM trusted_contacts WHERE user_id=?');
    $n->execute([$u['id']]);
    if ($n->fetchColumn() >= 5) fail('Maksimal 5 kontak tepercaya.');
    db()->prepare('INSERT INTO trusted_contacts (user_id,nama,no_hp) VALUES (?,?,?)')->execute([$u['id'], $nama, $hp]);
    out(['id' => (int)db()->lastInsertId(), 'nama' => $nama, 'no_hp' => $hp], 201);
});

route('DELETE', '/contacts/(\d+)', function ($id) {
    $u = need_role('pelapor');
    db()->prepare('DELETE FROM trusted_contacts WHERE id=? AND user_id=?')->execute([$id, $u['id']]);
    out(['dihapus' => true]);
});

route('POST', '/sos', function () {
    $u = need_role('pelapor');
    $in = input();
    $lat = is_numeric($in['lat'] ?? null) ? (float)$in['lat'] : null;
    $lng = is_numeric($in['lng'] ?? null) ? (float)$in['lng'] : null;
    db()->prepare('INSERT INTO emergency_events (user_id,lat,lng) VALUES (?,?,?)')->execute([$u['id'], $lat, $lng]);
    audit((int)$u['id'], 'sos', $lat !== null ? "$lat,$lng" : 'tanpa lokasi');
    $st = db()->prepare('SELECT nama,no_hp FROM trusted_contacts WHERE user_id=?');
    $st->execute([$u['id']]);
    $maps = $lat !== null ? "https://maps.google.com/?q=$lat,$lng" : null;
    out(['kontak' => $st->fetchAll(), 'peta' => $maps], 201);
});

// ================= BUKTI (unduh terdekripsi) =================
route('GET', '/evidence/(\d+)', function ($id) {
    $st = db()->prepare('SELECT e.*, r.user_id, r.case_no, r.access_hash FROM evidence e JOIN reports r ON r.id=e.report_id WHERE e.id=?');
    $st->execute([$id]);
    $e = $st->fetch();
    if (!$e) fail('Bukti tidak ditemukan.', 404);
    $allowed = false;
    $u = current_user();
    if ($u && in_array($u['role'], ['petugas'], true)) $allowed = true;
    if ($u && $u['role'] === 'pelapor' && (int)$e['user_id'] === (int)$u['id']) $allowed = true;
    if (!$allowed && isset($_GET['case_no'], $_GET['code'])) {
        $allowed = strtoupper(trim($_GET['case_no'])) === $e['case_no']
            && password_verify(strtoupper(trim($_GET['code'])), $e['access_hash']);
    }
    if (!$allowed) fail('Tidak diizinkan.', 403);
    $cipher = @file_get_contents(EVIDENCE_DIR . '/' . $e['stored_name']);
    $plain = $cipher === false ? null : decrypt_file($cipher, $e['iv'], $e['tag']);
    if ($plain === null) fail('Berkas rusak atau kunci enkripsi berbeda.', 500);
    if (!hash_equals($e['sha256'], hash('sha256', $plain))) fail('Hash berkas tidak cocok: bukti mungkin telah diubah.', 500);
    audit($u['id'] ?? null, 'bukti_dibuka', 'evidence#' . $id);
    http_response_code(200);
    header('Content-Type: ' . $e['mime']);
    header('X-Evidence-SHA256: ' . $e['sha256']);
    header('Content-Disposition: inline; filename="' . rawurlencode($e['nama_asli']) . '"');
    echo $plain;
});

// ================= PETUGAS =================
route('GET', '/staff/reports', function () {
    need_role('petugas', 'admin');
    $where = [];
    $args = [];
    if (!empty($_GET['status']) && in_array($_GET['status'], STATUS, true)) { $where[] = 'status=?'; $args[] = $_GET['status']; }
    if (!empty($_GET['kategori']) && in_array($_GET['kategori'], KATEGORI, true)) { $where[] = 'kategori=?'; $args[] = $_GET['kategori']; }
    if (!empty($_GET['q'])) { $where[] = '(case_no LIKE ? OR judul LIKE ?)'; $args[] = '%' . $_GET['q'] . '%'; $args[] = '%' . $_GET['q'] . '%'; }
    $sql = 'SELECT id,case_no,kategori,judul,wilayah,urgensi,status,anonim,created_at,updated_at FROM reports'
        . ($where ? ' WHERE ' . implode(' AND ', $where) : '')
        . " ORDER BY (status='selesai'), FIELD(urgensi,'kritis','tinggi','sedang','rendah'), id DESC LIMIT 200";
    $st = db()->prepare($sql);
    $st->execute($args);
    out($st->fetchAll());
});

route('GET', '/staff/reports/(\d+)', function ($id) {
    need_role('petugas', 'admin');
    $r = load_report((int)$id, true);
    if (!$r) fail('Laporan tidak ditemukan.', 404);
    out($r);
});

route('PATCH', '/staff/reports/(\d+)', function ($id) {
    $u = need_role('petugas');
    $in = input();
    $r = db()->prepare('SELECT id,status FROM reports WHERE id=?');
    $r->execute([$id]);
    $cur = $r->fetch();
    if (!$cur) fail('Laporan tidak ditemukan.', 404);
    $sets = ['petugas_id=COALESCE(petugas_id, ?)'];
    $args = [$u['id']];
    if (isset($in['status'])) {
        if (!in_array($in['status'], STATUS, true)) fail('Status tidak valid.');
        $sets[] = 'status=?'; $args[] = $in['status'];
    }
    if (isset($in['urgensi'])) {
        if (!in_array($in['urgensi'], URGENSI, true)) fail('Urgensi tidak valid.');
        $sets[] = 'urgensi=?'; $args[] = $in['urgensi'];
    }
    if (isset($in['catatan_petugas'])) { $sets[] = 'catatan_petugas=?'; $args[] = str($in, 'catatan_petugas', 3000); }
    $args[] = $id;
    db()->prepare('UPDATE reports SET ' . implode(',', $sets) . ' WHERE id=?')->execute($args);
    audit((int)$u['id'], 'ubah_kasus', "#$id " . json_encode(array_intersect_key($in, array_flip(['status', 'urgensi']))));
    out(load_report((int)$id, true));
});

route('POST', '/staff/reports/(\d+)/messages', function ($id) {
    $u = need_role('petugas');
    $isi = str(input(), 'isi', 3000);
    if ($isi === '') fail('Pesan kosong.');
    $c = db()->prepare('SELECT id FROM reports WHERE id=?');
    $c->execute([$id]);
    if (!$c->fetch()) fail('Laporan tidak ditemukan.', 404);
    db()->prepare("INSERT INTO messages (report_id,sender,sender_id,isi) VALUES (?, 'petugas', ?, ?)")->execute([$id, $u['id'], $isi]);
    out(load_report((int)$id, true), 201);
});

route('GET', '/staff/sos', function () {
    need_role('petugas', 'admin');
    // SOS adalah permintaan bantuan darurat: nama + HP + lokasi dibutuhkan agar petugas bisa menghubungi.
    $rows = db()->query('SELECT e.id, e.lat, e.lng, e.created_at, u.nama, u.no_hp
                         FROM emergency_events e JOIN users u ON u.id = e.user_id
                         ORDER BY e.id DESC LIMIT 50')->fetchAll();
    out($rows);
});

// ================= ADMIN =================
route('GET', '/admin/stats', function () {
    need_role('admin');
    $pdo = db();
    $s = [];
    $s['total'] = (int)$pdo->query('SELECT COUNT(*) FROM reports')->fetchColumn();
    $s['per_status'] = $pdo->query('SELECT status, COUNT(*) AS jumlah FROM reports GROUP BY status')->fetchAll();
    $s['per_kategori'] = $pdo->query('SELECT kategori, COUNT(*) AS jumlah FROM reports GROUP BY kategori')->fetchAll();
    $s['per_urgensi'] = $pdo->query('SELECT urgensi, COUNT(*) AS jumlah FROM reports GROUP BY urgensi')->fetchAll();
    $s['per_wilayah'] = $pdo->query("SELECT COALESCE(NULLIF(wilayah,''),'Tidak disebut') AS wilayah, COUNT(*) AS jumlah
                                     FROM reports GROUP BY 1 ORDER BY jumlah DESC LIMIT 15")->fetchAll();
    $s['per_hari'] = $pdo->query('SELECT DATE(created_at) AS tanggal, COUNT(*) AS jumlah FROM reports
                                  WHERE created_at >= (CURDATE() - INTERVAL 6 DAY) GROUP BY 1 ORDER BY 1')->fetchAll();
    $s['jumlah_petugas'] = (int)$pdo->query("SELECT COUNT(*) FROM users WHERE role='petugas' AND aktif=1")->fetchColumn();
    $s['jumlah_pelapor'] = (int)$pdo->query("SELECT COUNT(*) FROM users WHERE role='pelapor'")->fetchColumn();
    $s['sos_total'] = (int)$pdo->query('SELECT COUNT(*) FROM emergency_events')->fetchColumn();
    out($s);
});

route('GET', '/admin/staff', function () {
    need_role('admin');
    out(db()->query("SELECT id,nama,email,role,no_hp,instansi,wilayah,aktif,created_at FROM users WHERE role IN ('petugas','admin') ORDER BY role, id")->fetchAll());
});

route('POST', '/admin/staff', function () {
    $a = need_role('admin');
    $in = input();
    $nama = str($in, 'nama', 100);
    $email = strtolower(str($in, 'email', 150));
    $pass = trim((string)($in['password'] ?? ''));
    if ($nama === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) fail('Nama dan email valid wajib diisi.');
    if (strlen($pass) < 6) fail('Kata sandi minimal 6 karakter.');
    $c = db()->prepare('SELECT id FROM users WHERE email=?');
    $c->execute([$email]);
    if ($c->fetch()) fail('Email sudah terdaftar.', 409);
    db()->prepare("INSERT INTO users (nama,email,password_hash,role,no_hp,instansi,wilayah) VALUES (?,?,?, 'petugas', ?,?,?)")
        ->execute([$nama, $email, password_hash($pass, PASSWORD_BCRYPT), str($in, 'no_hp', 25) ?: null, str($in, 'instansi', 150) ?: null, str($in, 'wilayah', 80) ?: null]);
    audit((int)$a['id'], 'tambah_petugas', $email);
    out(['id' => (int)db()->lastInsertId()], 201);
});

route('PATCH', '/admin/users/(\d+)', function ($id) {
    $a = need_role('admin');
    $in = input();
    if ((int)$id === (int)$a['id']) fail('Tidak bisa mengubah akun admin sendiri dari sini.');
    $t = db()->prepare("SELECT id,role FROM users WHERE id=? AND role='petugas'");
    $t->execute([$id]);
    if (!$t->fetch()) fail('Petugas tidak ditemukan.', 404);
    if (isset($in['aktif'])) {
        $v = in_array((string)$in['aktif'], ['1', 'true'], true) ? 1 : 0;
        db()->prepare('UPDATE users SET aktif=? WHERE id=?')->execute([$v, $id]);
        audit((int)$a['id'], $v ? 'aktifkan_petugas' : 'nonaktifkan_petugas', "#$id");
    }
    if (!empty($in['password'])) {
        if (strlen((string)$in['password']) < 6) fail('Kata sandi minimal 6 karakter.');
        db()->prepare('UPDATE users SET password_hash=? WHERE id=?')->execute([password_hash((string)$in['password'], PASSWORD_BCRYPT), $id]);
        audit((int)$a['id'], 'reset_sandi_petugas', "#$id");
    }
    out(['diubah' => true]);
});

route('GET', '/admin/audit', function () {
    need_role('admin');
    $rows = db()->query('SELECT a.id,a.aksi,a.detail,a.ip,a.created_at,u.nama AS pengguna,u.role
                         FROM audit_logs a LEFT JOIN users u ON u.id=a.user_id ORDER BY a.id DESC LIMIT 100')->fetchAll();
    out($rows);
});

fail('Endpoint tidak ditemukan: ' . $method . ' ' . $path, 404);