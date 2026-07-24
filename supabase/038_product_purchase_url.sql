-- ============================================
-- ССЫЛКА НА ПОКУПКУ ПРОДУКТА
-- ============================================

-- Добавляем поле purchase_url в products
ALTER TABLE products ADD COLUMN IF NOT EXISTS purchase_url TEXT DEFAULT NULL;

-- Комментарий
COMMENT ON COLUMN products.purchase_url IS 'Ссылка на покупку продукта (Amazon, магазин и т.д.)';
