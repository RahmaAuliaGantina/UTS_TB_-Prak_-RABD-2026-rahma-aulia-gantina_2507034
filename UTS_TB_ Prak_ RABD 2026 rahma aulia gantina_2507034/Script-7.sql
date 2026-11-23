USE db_electromart;

-- 1. View_Produk: Mengambil dari 1 tabel tanpa atribut internal (misalnya menyembunyikan jumlah stok gudang untuk katalog kasir/pelanggan)
CREATE VIEW View_Produk AS
SELECT id_produk, nama_produk, kategori, harga
FROM produk;

-- 2. View_Transaksi: Menggabungkan beberapa tabel dengan JOIN (penjualan + pelanggan + pegawai)
CREATE VIEW View_Transaksi AS
SELECT 
    pj.id_penjualan,
    pj.tanggal,
    pl.nama_pelanggan,
    pg.nama_pegawai AS kasir,
    pj.total_harga,
    pj.diskon,
    pj.total_bayar
FROM penjualan pj
JOIN pelanggan pl ON pj.id_pelanggan = pl.id_pelanggan
JOIN pegawai pg ON pj.id_pegawai = pg.id_pegawai;

-- 3. View_Laporan_Penjualan: Agregasi COUNT(), SUM(), dan GROUP BY per kategori produk
CREATE VIEW View_Laporan_Penjualan AS
SELECT 
    pr.kategori,
    COUNT(DISTINCT dp.id_penjualan) AS jumlah_transaksi,
    SUM(dp.jumlah) AS total_unit_terjual,
    SUM(dp.subtotal) AS total_omzet
FROM detail_penjualan dp
JOIN produk pr ON dp.id_produk = pr.id_produk
GROUP BY pr.kategori;

-- 4. View_Stok_Rendah: Produk dengan stok <= 5 disertai WITH CHECK OPTION
CREATE VIEW View_Stok_Rendah AS
SELECT id_produk, nama_produk, kategori, harga, stok
FROM produk
WHERE stok <= 5
WITH CHECK OPTION;

-- =========================================================================
-- PENGUJIAN VIEW & WITH CHECK OPTION (Screenshot semua hasil!)
-- =========================================================================
SELECT * FROM View_Produk;
SELECT * FROM View_Transaksi;
SELECT * FROM View_Laporan_Penjualan;
SELECT * FROM View_Stok_Rendah;

-- Uji WITH CHECK OPTION pada View_Stok_Rendah:
-- A. Update stok PRD003 dari 3 menjadi 4 (Masih <= 5 -> BERHASIL)
UPDATE View_Stok_Rendah SET stok = 4 WHERE id_produk = 'PRD003';

-- B. Update stok PRD003 menjadi 20 (Melanggar kondisi WHERE stok <= 5 -> GAGAL: CHECK OPTION failed!)
UPDATE View_Stok_Rendah SET stok = 20 WHERE id_produk = 'PRD003';

-- Hapus salah satu View menggunakan DROP VIEW sesuai instruksi nomor 47
DROP VIEW IF EXISTS View_Produk;