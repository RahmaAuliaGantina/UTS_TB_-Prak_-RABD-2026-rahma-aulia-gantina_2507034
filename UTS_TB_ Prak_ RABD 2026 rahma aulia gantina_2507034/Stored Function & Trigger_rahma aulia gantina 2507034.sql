USE db_electromart;

DELIMITER $$

-- =========================================================================
-- A. STORED FUNCTION
-- =========================================================================

-- 1. hitung_total(): Menghitung harga satuan dikalikan jumlah pembelian
CREATE FUNCTION hitung_total(p_harga DECIMAL(12,2), p_jumlah INT)
RETURNS DECIMAL(12,2)
DETERMINISTIC
BEGIN
    RETURN p_harga * p_jumlah;
END$$

-- 2. hitung_diskon(): Diskon 10% jika total transaksi >= Rp1.000.000, selain itu 0
CREATE FUNCTION hitung_diskon(p_total DECIMAL(12,2))
RETURNS DECIMAL(12,2)
DETERMINISTIC
BEGIN
    IF p_total >= 1000000.00 THEN
        RETURN p_total * 0.10;
    ELSE
        RETURN 0.00;
    END IF;
END$$

-- =========================================================================
-- B. TRIGGER
-- =========================================================================

-- 1. validasi_penjualan (BEFORE INSERT pada detail_penjualan)
-- Memvalidasi produk terdaftar, jumlah > 0, stok cukup, dan mengisi harga & subtotal otomatis
CREATE TRIGGER validasi_penjualan
BEFORE INSERT ON detail_penjualan
FOR EACH ROW
BEGIN
    DECLARE v_stok INT;
    DECLARE v_harga DECIMAL(12,2);

    -- Cek apakah produk ada di tabel produk
    SELECT stok, harga INTO v_stok, v_harga
    FROM produk
    WHERE id_produk = NEW.id_produk;

    IF v_stok IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Transaksi ditolak: Produk tidak terdaftar di sistem.';
    END IF;

    -- Validasi jumlah pembelian tidak boleh nol atau negatif
    IF NEW.jumlah <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Transaksi ditolak: Jumlah pembelian harus lebih dari 0.';
    END IF;

    -- Validasi ketersediaan stok
    IF NEW.jumlah > v_stok THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Transaksi ditolak: Stok produk tidak mencukupi.';
    END IF;

    -- Pastikan harga satuan mengikuti harga resmi master produk & hitung subtotal via Function
    SET NEW.harga_satuan = v_harga;
    SET NEW.subtotal = hitung_total(NEW.harga_satuan, NEW.jumlah);
END$$

-- 2. update_stok_penjualan (AFTER INSERT pada detail_penjualan)
-- Mengurangi stok, mencatat log_stok, dan menghitung total_harga, diskon, & total_bayar otomatis
CREATE TRIGGER update_stok_penjualan
AFTER INSERT ON detail_penjualan
FOR EACH ROW
BEGIN
    DECLARE v_total_transaksi DECIMAL(12,2);
    DECLARE v_diskon DECIMAL(12,2);

    -- 1. Kurangi stok pada tabel produk
    UPDATE produk
    SET stok = stok - NEW.jumlah
    WHERE id_produk = NEW.id_produk;

    -- 2. Catat mutasi keluar ke tabel log_stok
    INSERT INTO log_stok (id_produk, jumlah_perubahan, tipe_transaksi, keterangan, tanggal)
    VALUES (
        NEW.id_produk,
        -NEW.jumlah,
        'KELUAR',
        CONCAT('Pengurangan stok otomatis dari ', NEW.id_penjualan),
        NOW()
    );

    -- 3. Hitung ulang total belanja nota ini dan terapkan fungsi hitung_diskon()
    SELECT COALESCE(SUM(subtotal), 0) INTO v_total_transaksi
    FROM detail_penjualan
    WHERE id_penjualan = NEW.id_penjualan;

    SET v_diskon = hitung_diskon(v_total_transaksi);

    UPDATE penjualan
    SET total_harga = v_total_transaksi,
        diskon = v_diskon,
        total_bayar = v_total_transaksi - v_diskon
    WHERE id_penjualan = NEW.id_penjualan;
END$$

DELIMITER ;

-- =========================================================================
-- C. PENGUJIAN LENGKAP 6 SKENARIO MODUL (Screenshot setiap pengujian!)
-- =========================================================================

-- Skenario 35 & 39: Pembelian stok tersedia & Memenuhi syarat diskon (>= Rp 1.000.000)
-- Beli 2 unit Printer PRD009 (2 x 2.400.000 = 4.800.000 -> Diskon 10% = 480.000 -> Bayar = 4.320.000)
INSERT INTO penjualan (id_penjualan, id_pelanggan, id_pegawai) VALUES ('TRX008', 'PLG001', 'PGW002');
INSERT INTO detail_penjualan (id_penjualan, id_produk, jumlah) VALUES ('TRX008', 'PRD009', 2);

-- Cek hasil perhitungan otomatis, pengurangan stok PRD009 (dari 4 jadi 2), dan log_stok:
SELECT * FROM penjualan WHERE id_penjualan = 'TRX008';
SELECT id_produk, nama_produk, stok FROM produk WHERE id_produk = 'PRD009';
SELECT * FROM log_stok ORDER BY id_log DESC LIMIT 3;

-- Skenario 40: Transaksi yang TIDAK memenuhi syarat diskon (< Rp 1.000.000)
-- Beli 2 unit Flashdisk PRD008 (2 x 85.000 = 170.000 -> Diskon = 0 -> Bayar = 170.000)
INSERT INTO penjualan (id_penjualan, id_pelanggan, id_pegawai) VALUES ('TRX009', 'PLG003', 'PGW002');
INSERT INTO detail_penjualan (id_penjualan, id_produk, jumlah) VALUES ('TRX009', 'PRD008', 2);

SELECT * FROM penjualan WHERE id_penjualan = 'TRX009';

-- Skenario 36: Pembelian melebihi stok (HARUS ERROR / DITOLAK)
-- Stok PRD006 tinggal 2, coba beli 10
INSERT INTO penjualan (id_penjualan, id_pelanggan, id_pegawai) VALUES ('TRX010', 'PLG004', 'PGW002');
INSERT INTO detail_penjualan (id_penjualan, id_produk, jumlah) VALUES ('TRX010', 'PRD006', 10);

-- Skenario 37: Pembelian dengan jumlah nol atau negatif (HARUS ERROR / DITOLAK)
INSERT INTO detail_penjualan (id_penjualan, id_produk, jumlah) VALUES ('TRX010', 'PRD001', 0);
INSERT INTO detail_penjualan (id_penjualan, id_produk, jumlah) VALUES ('TRX010', 'PRD001', -3);

-- Skenario 38: Pembelian produk yang tidak terdaftar (HARUS ERROR / DITOLAK)
INSERT INTO detail_penjualan (id_penjualan, id_produk, jumlah) VALUES ('TRX010', 'PRD999', 1);