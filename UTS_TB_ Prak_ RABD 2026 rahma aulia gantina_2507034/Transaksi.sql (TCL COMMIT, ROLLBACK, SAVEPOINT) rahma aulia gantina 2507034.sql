USE db_electromart;

-- =========================================================================
-- SKENARIO A: Transaksi Penjualan Berhasil (1 Laptop PRD001 & 2 Mouse PRD002)
-- =========================================================================
START TRANSACTION;

INSERT INTO penjualan (id_penjualan, tanggal, id_pelanggan, id_pegawai, total_harga, diskon, total_bayar)
VALUES ('TRX005', NOW(), 'PLG005', 'PGW002', 15000000.00, 1500000.00, 13500000.00);

INSERT INTO detail_penjualan (id_penjualan, id_produk, jumlah, harga_satuan, subtotal) VALUES
('TRX005', 'PRD001', 1, 14500000.00, 14500000.00),
('TRX005', 'PRD002', 2, 250000.00, 500000.00);

UPDATE produk SET stok = stok - 1 WHERE id_produk = 'PRD001';
UPDATE produk SET stok = stok - 2 WHERE id_produk = 'PRD002';

INSERT INTO log_stok (id_produk, jumlah_perubahan, tipe_transaksi, keterangan) VALUES
('PRD001', -1, 'KELUAR', 'Pengurangan stok dari TRX005'),
('PRD002', -2, 'KELUAR', 'Pengurangan stok dari TRX005');

COMMIT;

-- Bukti Skenario A tersimpan permanen:
SELECT * FROM penjualan WHERE id_penjualan = 'TRX005';
SELECT id_produk, nama_produk, stok FROM produk WHERE id_produk IN ('PRD001', 'PRD002');

-- =========================================================================
-- SKENARIO B: Transaksi Gagal (Beli Smart TV PRD006 sebanyak 5 unit, padahal stok cuma 2)
-- =========================================================================
START TRANSACTION;

INSERT INTO penjualan (id_penjualan, tanggal, id_pelanggan, id_pegawai, total_harga, diskon, total_bayar)
VALUES ('TRX006', NOW(), 'PLG001', 'PGW002', 42500000.00, 4250000.00, 38250000.00);

INSERT INTO detail_penjualan (id_penjualan, id_produk, jumlah, harga_satuan, subtotal)
VALUES ('TRX006', 'PRD006', 5, 8500000.00, 42500000.00);

UPDATE produk SET stok = stok - 5 WHERE id_produk = 'PRD006';

-- Cek kondisi sementara: stok PRD006 menjadi -3 (tidak valid!)
SELECT id_produk, stok FROM produk WHERE id_produk = 'PRD006';

-- Batalkan seluruh transaksi TRX006
ROLLBACK;

-- Bukti Skenario B dibatalkan (TRX006 hilang, stok PRD006 kembali 2):
SELECT * FROM penjualan WHERE id_penjualan = 'TRX006';
SELECT id_produk, stok FROM produk WHERE id_produk = 'PRD006';

-- =========================================================================
-- SKENARIO C: Pembatalan Sebagian Transaksi (SAVEPOINT & RELEASE SAVEPOINT)
-- =========================================================================
START TRANSACTION;

-- Item 1: Beli 1 Webcam PRD010 (Rp 950.000) -> Valid
INSERT INTO penjualan (id_penjualan, tanggal, id_pelanggan, id_pegawai, total_harga, diskon, total_bayar)
VALUES ('TRX007', NOW(), 'PLG002', 'PGW002', 950000.00, 0.00, 950000.00);

INSERT INTO detail_penjualan (id_penjualan, id_produk, jumlah, harga_satuan, subtotal)
VALUES ('TRX007', 'PRD010', 1, 950000.00, 950000.00);

UPDATE produk SET stok = stok - 1 WHERE id_produk = 'PRD010';
INSERT INTO log_stok (id_produk, jumlah_perubahan, tipe_transaksi, keterangan)
VALUES ('PRD010', -1, 'KELUAR', 'Pengurangan stok dari TRX007');

-- Tandai titik aman setelah item pertama
SAVEPOINT sp_item_pertama;

-- Item 2: Pelanggan sempat ingin menambah 1 Keyboard PRD003 (Rp 1.200.000), lalu berubah pikiran
INSERT INTO detail_penjualan (id_penjualan, id_produk, jumlah, harga_satuan, subtotal)
VALUES ('TRX007', 'PRD003', 1, 1200000.00, 1200000.00);
UPDATE produk SET stok = stok - 1 WHERE id_produk = 'PRD003';

-- Batalkan hanya penambahan Item 2 kembali ke SAVEPOINT
ROLLBACK TO SAVEPOINT sp_item_pertama;

-- Hapus penanda savepoint karena sudah tidak dibutuhkan, lalu simpan permanen Item 1
RELEASE SAVEPOINT sp_item_pertama;
COMMIT;

-- Bukti akhir Skenario C (TRX007 hanya berisi PRD010, stok PRD003 tetap utuh 3):
SELECT * FROM detail_penjualan WHERE id_penjualan = 'TRX007';
SELECT id_produk, nama_produk, stok FROM produk WHERE id_produk IN ('PRD010', 'PRD003');