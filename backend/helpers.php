<?php
require_once __DIR__ . '/config.php';

function db(): PDO {
    static $pdo = null;
    if ($pdo === null) {
        $dsn = sprintf('mysql:host=%s;port=%s;dbname=%s;charset=utf8mb4', DB_HOST, DB_PORT, DB_NAME);
        $pdo = new PDO($dsn, DB_USER, DB_PASS, [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        ]);
    }
    return $pdo;
}

function out($data = null, int $code = 200): void {
    http_response_code($code);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode(['ok' => $code < 400, 'data' => $data], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function fail(string $msg, int $code = 400): void {
    http_response_code($code);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode(['ok' => false, 'message' => $msg], JSON_UNESCAPED_UNICODE);
    exit;
}

function input(): array {
    static $in = null;
    if ($in !== null) return $in;
    $ct = $_SERVER['CONTENT_TYPE'] ?? '';
    if (stripos($ct, 'application/json') !== false) {
        $d = json_decode(file_get_contents('php://input'), true);
        $in = is_array($d) ? $d : [];
    } else {
        $in = $_POST;
    }
    return $in;
}

function str(array $a, string $k, int $max = 5000): string {
    $v = isset($a[$k]) ? trim((string)$a[$k]) : '';
    return mb_substr($v, 0, $max);
}

function client_ip(): string { return $_SERVER['REMOTE_ADDR'] ?? ''; }

function audit(?int $uid, string $aksi, string $detail = ''): void {
    $st = db()->prepare('INSERT INTO audit_logs (user_id,aksi,detail,ip) VALUES (?,?,?,?)');
    $st->execute([$uid, $aksi, mb_substr($detail, 0, 250), client_ip()]);
}

// ---------- Token (HS256 sederhana) ----------
function b64u(string $s): string { return rtrim(strtr(base64_encode($s), '+/', '-_'), '='); }
function b64u_dec(string $s): string { return base64_decode(strtr($s, '-_', '+/')); }

function make_token(array $user): string {
    $h = b64u(json_encode(['alg' => 'HS256', 'typ' => 'JWT']));
    $p = b64u(json_encode(['uid' => (int)$user['id'], 'role' => $user['role'], 'exp' => time() + TOKEN_TTL]));
    $s = b64u(hash_hmac('sha256', "$h.$p", TOKEN_SECRET, true));
    return "$h.$p.$s";
}

function bearer(): ?string {
    $h = $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '';
    if (!$h && function_exists('getallheaders')) {
        foreach (getallheaders() as $k => $v) if (strtolower($k) === 'authorization') $h = $v;
    }
    if (stripos($h, 'Bearer ') === 0) return trim(substr($h, 7));
    return $_GET['token'] ?? null; // untuk unduh bukti lewat URL
}

function current_user(): ?array {
    $t = bearer();
    if (!$t) return null;
    $parts = explode('.', $t);
    if (count($parts) !== 3) return null;
    [$h, $p, $s] = $parts;
    $calc = b64u(hash_hmac('sha256', "$h.$p", TOKEN_SECRET, true));
    if (!hash_equals($calc, $s)) return null;
    $pl = json_decode(b64u_dec($p), true);
    if (!$pl || ($pl['exp'] ?? 0) < time()) return null;
    $st = db()->prepare('SELECT id,nama,email,role,no_hp,instansi,wilayah,aktif FROM users WHERE id=?');
    $st->execute([$pl['uid']]);
    $u = $st->fetch();
    if (!$u || !$u['aktif']) return null;
    return $u;
}

function need_role(string ...$roles): array {
    $u = current_user();
    if (!$u) fail('Sesi berakhir, silakan masuk lagi.', 401);
    if (!in_array($u['role'], $roles, true)) fail('Anda tidak punya akses ke fitur ini.', 403);
    return $u;
}

// ---------- Enkripsi bukti AES-256-GCM ----------
function ev_key(): string { return base64_decode(EVIDENCE_KEY_B64); }

function encrypt_file(string $plain): array {
    $iv = random_bytes(12);
    $tag = '';
    $cipher = openssl_encrypt($plain, 'aes-256-gcm', ev_key(), OPENSSL_RAW_DATA, $iv, $tag);
    return [$cipher, bin2hex($iv), bin2hex($tag)];
}

function decrypt_file(string $cipher, string $ivHex, string $tagHex): ?string {
    $r = openssl_decrypt($cipher, 'aes-256-gcm', ev_key(), OPENSSL_RAW_DATA, hex2bin($ivHex), hex2bin($tagHex));
    return $r === false ? null : $r;
}

// ---------- Kasus ----------
function new_case_no(): string {
    return 'LK-' . date('ymd') . '-' . strtoupper(substr(bin2hex(random_bytes(3)), 0, 5));
}

function new_access_code(): string {
    $abc = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    $c = '';
    for ($i = 0; $i < 8; $i++) $c .= $abc[random_int(0, strlen($abc) - 1)];
    return substr($c, 0, 4) . '-' . substr($c, 4);
}

// Penilaian urgensi otomatis (awal) - petugas tetap bisa mengubahnya.
function assess_urgency(string $kategori, string $teks): string {
    $t = mb_strtolower($teks);
    $kritis = ['bunuh', 'senjata', 'pisau', 'ancam', 'hamil', 'berdarah', 'darah', 'bunuh diri', 'diperkosa', 'pemerkosaan', 'sekarang', 'disekap'];
    foreach ($kritis as $w) if (mb_strpos($t, $w) !== false) return 'kritis';
    if ($kategori === 'seksual') return 'tinggi';
    if ($kategori === 'kdrt') return 'tinggi';
    return 'sedang';
}

function load_report(int $id, bool $forStaff): ?array {
    $st = db()->prepare('SELECT r.*, u.nama AS pelapor_nama, p.nama AS petugas_nama
                         FROM reports r
                         LEFT JOIN users u ON u.id=r.user_id
                         LEFT JOIN users p ON p.id=r.petugas_id
                         WHERE r.id=?');
    $st->execute([$id]);
    $r = $st->fetch();
    if (!$r) return null;
    unset($r['access_hash']);
    // Identitas pelapor disembunyikan dari petugas bila anonim
    if (!$forStaff || $r['anonim']) { $r['pelapor_nama'] = null; }
    if ($forStaff) unset($r['user_id']);
    $ev = db()->prepare('SELECT id,nama_asli,mime,ukuran,sha256,uploaded_at FROM evidence WHERE report_id=? ORDER BY id');
    $ev->execute([$id]);
    $r['bukti'] = $ev->fetchAll();
    $ms = db()->prepare('SELECT id,sender,isi,created_at FROM messages WHERE report_id=? ORDER BY id');
    $ms->execute([$id]);
    $r['pesan'] = $ms->fetchAll();
    return $r;
}

function report_by_credentials(string $caseNo, string $code): ?array {
    $st = db()->prepare('SELECT id,access_hash FROM reports WHERE case_no=?');
    $st->execute([strtoupper(trim($caseNo))]);
    $r = $st->fetch();
    if (!$r) return null;
    if (!password_verify(strtoupper(trim($code)), $r['access_hash'])) return null;
    return $r;
}

function store_evidence(int $reportId): int {
    if (empty($_FILES['bukti'])) return 0;
    $f = $_FILES['bukti'];
    $names = is_array($f['name']) ? $f['name'] : [$f['name']];
    $tmps = is_array($f['tmp_name']) ? $f['tmp_name'] : [$f['tmp_name']];
    $errs = is_array($f['error']) ? $f['error'] : [$f['error']];
    $count = 0;
    if (!is_dir(EVIDENCE_DIR)) mkdir(EVIDENCE_DIR, 0775, true);
    foreach ($names as $i => $name) {
        if (($errs[$i] ?? 1) !== UPLOAD_ERR_OK) continue;
        $size = filesize($tmps[$i]);
        if ($size > MAX_UPLOAD_BYTES || $size === 0) continue;
        $plain = file_get_contents($tmps[$i]);
        $mime = (new finfo(FILEINFO_MIME_TYPE))->file($tmps[$i]) ?: 'application/octet-stream';
        $sha = hash('sha256', $plain);
        [$cipher, $iv, $tag] = encrypt_file($plain);
        $stored = bin2hex(random_bytes(16)) . '.enc';
        file_put_contents(EVIDENCE_DIR . '/' . $stored, $cipher);
        $st = db()->prepare('INSERT INTO evidence (report_id,nama_asli,stored_name,mime,ukuran,sha256,iv,tag) VALUES (?,?,?,?,?,?,?,?)');
        $st->execute([$reportId, mb_substr(basename($name), 0, 200), $stored, $mime, $size, $sha, $iv, $tag]);
        $count++;
    }
    return $count;
}
