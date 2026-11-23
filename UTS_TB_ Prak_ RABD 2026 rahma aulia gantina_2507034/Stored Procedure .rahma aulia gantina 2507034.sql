USE db_electromart;

DELIMITER $$

-- 1. SP_Tampil_Produk: Menampilkan seluruh data produk
CREATE PROCEDURE SP_Tampil_Produk()
BEGIN
    SELECT id_produk, nama_produk, kategori, harga, stok
    FROM produk
    ORDER BY id_produk ASC;
END$$

-- 2. SP_Tambah_Produk: Menambahkan produk baru menggunakan parameter
CREATE PROCEDURE SP_Tambah_Produk(
    IN p_id VARCHAR(10),
    IN p_nama VARCHAR(100),
    IN p_kategori VARCHAR(50),
    IN p_harga DECIMAL(12,2),
    IN p_stok INT
)
BEGIN
    INSERT INTO produk (id_produk, nama_produk, kategori, harga, stok)
    VALUES (p_id, p_nama, p_kategori, p_harga, p_stok);
END$$

-- 3. SP_Ubah_Harga: Mengubah harga produk berdasarkan ID produk dan harga baru
CREATE PROCEDURE SP_Ubah_Harga(
    IN p_id VARCHAR(10),
    IN p_harga_baru DECIMAL(12,2)
)
BEGIN
    UPDATE produk
    SET harga = p_harga_baru
    WHERE id_produk = p_id;
END$$

DELIMITER ;

-- =========================================================================
-- PENGUJIAN STORED PROCEDURE (Screenshot setiap hasil eksekusi!)
-- =========================================================================

-- Panggil SP_Tampil_Produk
CALL SP_Tampil_Produk();

-- Panggil SP_Tambah_Produk (Uji dengan 2 data berbeda)
CALL SP_Tambah_Produk('PRD011', 'SSD NVMe Samsung 1TB', 'Penyimpanan', 1450000.00, 15);
CALL SP_Tambah_Produk('PRD012', 'Router WiFi 6 TP-Link AX1800', 'Jaringan', 780000.00, 10);
CALL SP_Tampil_Produk();

-- Panggil SP_Ubah_Harga
CALL SP_Ubah_Harga('PRD011', 1390000.00);
CALL SP_Ubah_Harga('PRD002', 235000.00);
SELECT id_produk, nama_produk, harga FROM produk WHERE id_produk IN ('PRD011', 'PRD002');

-- Hapus salah satu procedure sebagai bukti penguasaan perintah pengelolaan
DROP PROCEDURE IF EXISTS SP_Ubah_Harga;
SHOW PROCEDURE STATUS WHERE Db = 'db_electromart';