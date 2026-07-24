-- ============================================
-- ПЕРЕВОД ДЛЯ ПУНКТА МЕНЮ "ОСТАТКИ"
-- ============================================

INSERT INTO translations (key, ru, en, hi, page, context) VALUES
('nav_stock_balance', 'Остатки', 'Stock', 'स्टॉक', 'layout', 'Пункт меню'),
('nav_inventory', 'Инвентаризация', 'Inventory', 'इन्वेंटरी', 'layout', 'Пункт меню')

ON CONFLICT (key) DO UPDATE SET
    ru = excluded.ru,
    en = excluded.en,
    hi = excluded.hi,
    page = excluded.page,
    context = excluded.context;
