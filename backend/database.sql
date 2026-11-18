-- LindungiKita - skema database (MySQL / MariaDB di Laragon)
-- (Versi tanpa FOREIGN KEY agar impor tidak gagal di semua versi MySQL/MariaDB Laragon)
-- Cara pakai: buka HeidiSQL/phpMyAdmin Laragon, lalu Import file ini
-- atau jalankan:  mysql -u root < database.sql

CREATE DATABASE IF NOT EXISTS lindungikita CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE lindungikita;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS audit_logs, emergency_events, trusted_contacts, messages, evidence, reports, resources, users;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE users (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nama VARCHAR(100) NOT NULL,
  email VARCHAR(150) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('pelapor','petugas','admin') NOT NULL DEFAULT 'pelapor',
  no_hp VARCHAR(25) NULL,
  instansi VARCHAR(150) NULL,
  wilayah VARCHAR(80) NULL,
  aktif TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE reports (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  case_no VARCHAR(30) NOT NULL UNIQUE,
  access_hash VARCHAR(255) NOT NULL,           -- hash dari kode akses (kode asli hanya tampil sekali)
  user_id INT UNSIGNED NULL,                   -- NULL jika pelapor tanpa akun
  anonim TINYINT(1) NOT NULL DEFAULT 1,
  kategori ENUM('seksual','kdrt','perundungan','lainnya') NOT NULL,
  judul VARCHAR(150) NOT NULL,
  deskripsi TEXT NOT NULL,
  lokasi VARCHAR(200) NULL,
  wilayah VARCHAR(80) NULL,
  tanggal_kejadian DATE NULL,
  urgensi ENUM('rendah','sedang','tinggi','kritis') NOT NULL DEFAULT 'sedang',
  status ENUM('diterima','diverifikasi','ditangani','selesai') NOT NULL DEFAULT 'diterima',
  petugas_id INT UNSIGNED NULL,
  catatan_petugas TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX (status), INDEX (wilayah), INDEX (kategori)
) ENGINE=InnoDB;

CREATE TABLE evidence (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  report_id INT UNSIGNED NOT NULL,
  nama_asli VARCHAR(200) NOT NULL,
  stored_name VARCHAR(80) NOT NULL,            -- nama acak di disk (file terenkripsi AES-256-GCM)
  mime VARCHAR(100) NOT NULL,
  ukuran INT UNSIGNED NOT NULL,
  sha256 CHAR(64) NOT NULL,                    -- hash file asli untuk menjaga keaslian
  iv VARCHAR(40) NOT NULL,
  tag VARCHAR(40) NOT NULL,
  uploaded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP   -- stempel waktu
) ENGINE=InnoDB;

CREATE TABLE messages (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  report_id INT UNSIGNED NOT NULL,
  sender ENUM('pelapor','petugas') NOT NULL,
  sender_id INT UNSIGNED NULL,
  isi TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE trusted_contacts (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNSIGNED NOT NULL,
  nama VARCHAR(100) NOT NULL,
  no_hp VARCHAR(25) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE emergency_events (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNSIGNED NOT NULL,
  lat DECIMAL(10,7) NULL,
  lng DECIMAL(10,7) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE resources (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nama VARCHAR(150) NOT NULL,
  kategori VARCHAR(50) NOT NULL,
  kontak VARCHAR(100) NOT NULL,
  deskripsi VARCHAR(255) NULL
) ENGINE=InnoDB;

CREATE TABLE audit_logs (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNSIGNED NULL,
  aksi VARCHAR(60) NOT NULL,
  detail VARCHAR(255) NULL,
  ip VARCHAR(45) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX (aksi)
) ENGINE=InnoDB;

-- ============ DATA AWAL ============
-- Password:  admin = Admin123!   petugas = Petugas123!   pelapor = Pelapor123!
INSERT INTO users (nama,email,password_hash,role,no_hp,instansi,wilayah) VALUES
('Administrator','admin@lindungikita.id','$2y$10$cDBkVxt6yzwj9PcOAHD7J.hqUn5LvkgKCN47fd/b8LFXOwJkj5zgi','admin',NULL,'LindungiKita Pusat','DKI Jakarta'),
('Bu Ratna Pendamping','petugas@lindungikita.id','$2y$10$AML/gftltBLZ/k0tZ7yBo.VKrfD/TVBQ6rzBhrirKP0VuyMNiMhuy','petugas','081200000001','UPTD PPA Kota','DKI Jakarta'),
('Pelapor Contoh','pelapor@lindungikita.id','$2y$10$JgMdjRwYq2mKphayypIg2OETMrsdsuPNPM4Q37PEVzs.Lq5Gss5LO','pelapor','081200000002',NULL,NULL);

INSERT INTO resources (nama,kategori,kontak,deskripsi) VALUES
('SAPA 129 (KemenPPPA)','Layanan Nasional','129','Layanan pengaduan kekerasan perempuan dan anak, 24 jam.'),
('WhatsApp SAPA 129','Layanan Nasional','08111-129-129','Pengaduan lewat WhatsApp.'),
('Komnas Perempuan','Lembaga HAM','021-3903963','Pendampingan dan pengaduan kekerasan terhadap perempuan.'),
('LPSK','Perlindungan Saksi','148','Lembaga Perlindungan Saksi dan Korban.'),
('KPAI','Perlindungan Anak','021-31901446','Komisi Perlindungan Anak Indonesia.'),
('Polisi (darurat)','Darurat','110','Layanan darurat kepolisian.'),
('Ambulans / Medis','Darurat','119','Layanan darurat medis.');
