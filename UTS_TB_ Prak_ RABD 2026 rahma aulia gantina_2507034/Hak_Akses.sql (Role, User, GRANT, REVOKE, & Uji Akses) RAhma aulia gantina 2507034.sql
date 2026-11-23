-- 1. Membuat 4 Role Grup (Sesuai Tabel Role di Modul)
CREATE ROLE role_admin;
CREATE ROLE role_penjualan;
CREATE ROLE role_gudang;
CREATE ROLE role_manajer;

-- 2. Konfigurasi GRANT Hak Akses
-- role_admin: Mengelola seluruh objek dan data
GRANT ALL PRIVILEGES ON DATABASE db_electromart TO role_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO role_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO role_admin;

-- role_penjualan: Melihat produk & pelanggan, serta menginput transaksi
GRANT CONNECT ON DATABASE db_electromart TO role_penjualan;
GRANT SELECT ON produk, pelanggan, penjualan, detail_penjualan TO role_penjualan;
GRANT INSERT ON penjualan, detail_penjualan TO role_penjualan;
GRANT USAGE, SELECT ON SEQUENCE detail_penjualan_id_detail_seq TO role_penjualan;

-- role_gudang: Melihat produk dan memperbarui stok (+ log stok)
GRANT CONNECT ON DATABASE db_electromart TO role_gudang;
GRANT SELECT ON produk, log_stok TO role_gudang;
GRANT UPDATE (stok) ON produk TO role_gudang;
GRANT INSERT ON log_stok TO role_gudang;
GRANT USAGE, SELECT ON SEQUENCE log_stok_id_log_seq TO role_gudang;

-- role_manajer: Melihat informasi produk dan laporan penjualan (Read-Only)
GRANT CONNECT ON DATABASE db_electromart TO role_manajer;
GRANT SELECT ON produk, pelanggan, pegawai, penjualan, detail_penjualan, log_stok TO role_manajer;

-- 3. Contoh Implementasi REVOKE (Mencabut hak akses tertentu)
-- Misalnya sempat diberikan akses DELETE pada penjualan ke role_penjualan, lalu dicabut agar nota tidak bisa dihapus sembarangan
GRANT DELETE ON penjualan TO role_penjualan;
REVOKE DELETE ON penjualan FROM role_penjualan;

-- 4. Membuat Akun Pengguna (User) dan Menghubungkan ke Role
CREATE USER user_andi WITH PASSWORD 'Password123!';
CREATE USER user_maya WITH PASSWORD 'Password123!';
CREATE USER user_eko WITH PASSWORD 'Password123!';
CREATE USER user_hendra WITH PASSWORD 'Password123!';

GRANT role_admin TO user_andi;
GRANT role_penjualan TO user_maya;
GRANT role_gudang TO user_eko;
GRANT role_manajer TO user_hendra;

-- =========================================================================
-- 5. SKENARIO PENGUJIAN HAK AKSES (Screenshot hasil sukses & error!)
-- =========================================================================

-- Uji A: Simulasi sebagai Maya (role_penjualan)
SET ROLE user_maya;
SELECT * FROM produk; -- BERHASIL
ALTER TABLE produk ADD COLUMN berat INT; -- GAGAL (ERROR: must be owner of table produk)
SELECT * FROM log_stok; -- GAGAL (ERROR: permission denied for table log_stok)
RESET ROLE;

-- Uji B: Simulasi sebagai Eko (role_gudang)
SET ROLE user_eko;
SELECT id_produk, nama_produk, stok FROM produk; -- BERHASIL
UPDATE produk SET stok = 16 WHERE id_produk = 'PRD001'; -- BERHASIL
UPDATE produk SET harga = 1000 WHERE id_produk = 'PRD001'; -- GAGAL (ERROR: permission denied for table produk)
RESET ROLE;

-- Uji C: Simulasi sebagai Hendra (role_manajer)
SET ROLE user_hendra;
SELECT * FROM penjualan; -- BERHASIL
DELETE FROM penjualan WHERE id_penjualan = 'TRX001'; -- GAGAL (ERROR: permission denied for table penjualan)
RESET ROLE;