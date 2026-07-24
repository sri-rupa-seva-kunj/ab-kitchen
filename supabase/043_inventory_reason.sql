-- ============================================
-- ДОБАВЛЕНИЕ ПОЛЯ "ПРИЧИНА" ДЛЯ РЕВИЗИИ
-- ============================================

ALTER TABLE stock_inventory_items
ADD COLUMN IF NOT EXISTS reason TEXT;

-- Перевод
INSERT INTO translations (key, ru, en, hi, page, context) VALUES
('reason', 'Причина', 'Reason', 'कारण', 'inventory', 'Колонка')

ON CONFLICT (key) DO UPDATE SET
    ru = excluded.ru,
    en = excluded.en,
    hi = excluded.hi,
    page = excluded.page,
    context = excluded.context;
