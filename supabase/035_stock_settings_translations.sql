-- ============================================
-- ПЕРЕВОДЫ ДЛЯ НАСТРОЕК СКЛАДА
-- ============================================

INSERT INTO translations (key, ru, en, hi, page, context) VALUES
('stock_settings_title', 'Настройки склада', 'Stock Settings', 'स्टॉक सेटिंग्स', 'stock', 'Заголовок страницы'),
('buyers_tab', 'Закупщики', 'Buyers', 'खरीदार', 'stock', 'Таб'),
('min_stock_tab', 'Несгораемый остаток', 'Min Stock', 'न्यूनतम स्टॉक', 'stock', 'Таб'),
('buyers_list', 'Список закупщиков', 'Buyers List', 'खरीदारों की सूची', 'stock', 'Заголовок секции'),
('buyers_desc', 'Люди, которые могут закупать продукты', 'People who can purchase products', 'वे लोग जो उत्पाद खरीद सकते हैं', 'stock', 'Описание'),
('phone', 'Телефон', 'Phone', 'फ़ोन', 'common', 'Колонка таблицы'),
('name', 'Имя', 'Name', 'नाम', 'common', 'Колонка таблицы'),
('notes', 'Примечания', 'Notes', 'टिप्पणियाँ', 'common', 'Колонка таблицы'),
('min_stock_title', 'Несгораемый остаток', 'Minimum Stock', 'न्यूनतम स्टॉक', 'stock', 'Заголовок'),
('min_stock_desc', 'Минимальное количество, ниже которого остаток считается критичным', 'Minimum quantity below which stock is considered critical', 'न्यूनतम मात्रा जिसके नीचे स्टॉक महत्वपूर्ण माना जाता है', 'stock', 'Описание'),
('enter_buyer_name', 'Введите имя закупщика', 'Enter buyer name', 'खरीदार का नाम दर्ज करें', 'stock', 'Валидация'),
('delete_buyer_confirm', 'Удалить закупщика?', 'Delete buyer?', 'खरीदार को हटाएं?', 'stock', 'Подтверждение')

ON CONFLICT (key) DO UPDATE SET
    ru = excluded.ru,
    en = excluded.en,
    hi = excluded.hi,
    page = excluded.page,
    context = excluded.context;
