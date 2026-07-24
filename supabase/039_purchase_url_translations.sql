-- ============================================
-- ПЕРЕВОДЫ ДЛЯ ССЫЛКИ НА ПОКУПКУ
-- ============================================

INSERT INTO translations (key, ru, en, hi, page, context) VALUES
('purchase_url', 'Ссылка на покупку', 'Purchase Link', 'खरीद लिंक', 'products', 'Метка поля'),
('purchase_url_hint', 'Amazon, магазин и т.д.', 'Amazon, store, etc.', 'अमेज़न, दुकान, आदि', 'products', 'Подсказка')

ON CONFLICT (key) DO UPDATE SET
    ru = excluded.ru,
    en = excluded.en,
    hi = excluded.hi,
    page = excluded.page,
    context = excluded.context;
