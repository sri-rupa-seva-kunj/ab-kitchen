-- ============================================
-- 048: Заполнение прав для модуля Кухня
-- ============================================

-- Получаем ID модуля kitchen
DO $$
DECLARE
    kitchen_module_id UUID;

    -- Role IDs
    admin_role_id UUID;
    head_cook_role_id UUID;
    cook_role_id UUID;
    stock_manager_role_id UUID;
    buyer_role_id UUID;
    observer_role_id UUID;

    -- Permission IDs (will be populated)
    perm_id UUID;
BEGIN
    -- Получаем ID модуля kitchen
    SELECT id INTO kitchen_module_id FROM modules WHERE code = 'kitchen';

    IF kitchen_module_id IS NULL THEN
        RAISE EXCEPTION 'Module kitchen not found. Run 046_auth_system.sql first.';
    END IF;

    -- ============================================
    -- СОЗДАНИЕ ПРАВ (38 штук)
    -- ============================================

    -- Menu permissions
    INSERT INTO permissions (module_id, code, name_ru, name_en, category, sort_order) VALUES
        (kitchen_module_id, 'menu.view', 'Просмотр меню', 'View menu', 'menu', 1),
        (kitchen_module_id, 'menu.edit', 'Редактирование меню', 'Edit menu', 'menu', 2),
        (kitchen_module_id, 'menu.assign_cook', 'Назначение поваров', 'Assign cooks', 'menu', 3)
    ON CONFLICT (module_id, code) DO NOTHING;

    -- Templates permissions
    INSERT INTO permissions (module_id, code, name_ru, name_en, category, sort_order) VALUES
        (kitchen_module_id, 'templates.view', 'Просмотр шаблонов', 'View templates', 'templates', 10),
        (kitchen_module_id, 'templates.create', 'Создание шаблонов', 'Create templates', 'templates', 11),
        (kitchen_module_id, 'templates.edit', 'Редактирование шаблонов', 'Edit templates', 'templates', 12),
        (kitchen_module_id, 'templates.delete', 'Удаление шаблонов', 'Delete templates', 'templates', 13),
        (kitchen_module_id, 'templates.apply', 'Применение шаблонов', 'Apply templates', 'templates', 14)
    ON CONFLICT (module_id, code) DO NOTHING;

    -- Recipes permissions
    INSERT INTO permissions (module_id, code, name_ru, name_en, category, sort_order) VALUES
        (kitchen_module_id, 'recipes.view', 'Просмотр рецептов', 'View recipes', 'recipes', 20),
        (kitchen_module_id, 'recipes.create', 'Создание рецептов', 'Create recipes', 'recipes', 21),
        (kitchen_module_id, 'recipes.edit', 'Редактирование рецептов', 'Edit recipes', 'recipes', 22),
        (kitchen_module_id, 'recipes.delete', 'Удаление рецептов', 'Delete recipes', 'recipes', 23)
    ON CONFLICT (module_id, code) DO NOTHING;

    -- Products permissions
    INSERT INTO permissions (module_id, code, name_ru, name_en, category, sort_order) VALUES
        (kitchen_module_id, 'products.view', 'Просмотр продуктов', 'View products', 'products', 30),
        (kitchen_module_id, 'products.create', 'Создание продуктов', 'Create products', 'products', 31),
        (kitchen_module_id, 'products.edit', 'Редактирование продуктов', 'Edit products', 'products', 32),
        (kitchen_module_id, 'products.delete', 'Удаление продуктов', 'Delete products', 'products', 33)
    ON CONFLICT (module_id, code) DO NOTHING;

    -- Stock permissions
    INSERT INTO permissions (module_id, code, name_ru, name_en, category, sort_order) VALUES
        (kitchen_module_id, 'stock.view', 'Просмотр остатков', 'View stock', 'stock', 40),
        (kitchen_module_id, 'stock.edit', 'Редактирование остатков', 'Edit stock', 'stock', 41)
    ON CONFLICT (module_id, code) DO NOTHING;

    -- Requests permissions
    INSERT INTO permissions (module_id, code, name_ru, name_en, category, sort_order) VALUES
        (kitchen_module_id, 'requests.view', 'Просмотр заявок', 'View requests', 'requests', 50),
        (kitchen_module_id, 'requests.create', 'Создание заявок', 'Create requests', 'requests', 51),
        (kitchen_module_id, 'requests.approve', 'Одобрение заявок', 'Approve requests', 'requests', 52)
    ON CONFLICT (module_id, code) DO NOTHING;

    -- Receive permissions
    INSERT INTO permissions (module_id, code, name_ru, name_en, category, sort_order) VALUES
        (kitchen_module_id, 'receive.view', 'Просмотр приёмок', 'View receipts', 'receive', 60),
        (kitchen_module_id, 'receive.create', 'Создание приёмок', 'Create receipts', 'receive', 61)
    ON CONFLICT (module_id, code) DO NOTHING;

    -- Issue permissions
    INSERT INTO permissions (module_id, code, name_ru, name_en, category, sort_order) VALUES
        (kitchen_module_id, 'issue.view', 'Просмотр выдач', 'View issues', 'issue', 70),
        (kitchen_module_id, 'issue.create', 'Создание выдач', 'Create issues', 'issue', 71)
    ON CONFLICT (module_id, code) DO NOTHING;

    -- Inventory permissions
    INSERT INTO permissions (module_id, code, name_ru, name_en, category, sort_order) VALUES
        (kitchen_module_id, 'inventory.view', 'Просмотр инвентаризаций', 'View inventories', 'inventory', 80),
        (kitchen_module_id, 'inventory.create', 'Создание инвентаризаций', 'Create inventories', 'inventory', 81),
        (kitchen_module_id, 'inventory.complete', 'Завершение инвентаризаций', 'Complete inventories', 'inventory', 82)
    ON CONFLICT (module_id, code) DO NOTHING;

    -- Retreats permissions
    INSERT INTO permissions (module_id, code, name_ru, name_en, category, sort_order) VALUES
        (kitchen_module_id, 'retreats.view', 'Просмотр ретритов', 'View retreats', 'retreats', 90),
        (kitchen_module_id, 'retreats.edit', 'Редактирование ретритов', 'Edit retreats', 'retreats', 91)
    ON CONFLICT (module_id, code) DO NOTHING;

    -- Team permissions
    INSERT INTO permissions (module_id, code, name_ru, name_en, category, sort_order) VALUES
        (kitchen_module_id, 'team.view', 'Просмотр команды', 'View team', 'team', 100),
        (kitchen_module_id, 'team.edit', 'Редактирование команды', 'Edit team', 'team', 101)
    ON CONFLICT (module_id, code) DO NOTHING;

    -- Settings permissions
    INSERT INTO permissions (module_id, code, name_ru, name_en, category, sort_order) VALUES
        (kitchen_module_id, 'settings.dictionaries', 'Справочники', 'Dictionaries', 'settings', 110),
        (kitchen_module_id, 'settings.translations', 'Переводы', 'Translations', 'settings', 111),
        (kitchen_module_id, 'settings.festivals', 'Праздники', 'Festivals', 'settings', 112),
        (kitchen_module_id, 'settings.users', 'Пользователи', 'Users', 'settings', 113),
        (kitchen_module_id, 'settings.stock', 'Настройки склада', 'Stock settings', 'settings', 114)
    ON CONFLICT (module_id, code) DO NOTHING;

    -- ============================================
    -- СОЗДАНИЕ РОЛЕЙ
    -- ============================================

    -- Администратор
    INSERT INTO roles (module_id, code, name_ru, name_en, description_ru, description_en, color, is_system, sort_order)
    VALUES (kitchen_module_id, 'admin', 'Администратор', 'Administrator',
            'Полный доступ ко всем функциям', 'Full access to all features',
            '#ef4444', true, 1)
    ON CONFLICT (module_id, code) DO UPDATE SET
        name_ru = EXCLUDED.name_ru,
        name_en = EXCLUDED.name_en,
        description_ru = EXCLUDED.description_ru,
        description_en = EXCLUDED.description_en
    RETURNING id INTO admin_role_id;

    IF admin_role_id IS NULL THEN
        SELECT id INTO admin_role_id FROM roles WHERE module_id = kitchen_module_id AND code = 'admin';
    END IF;

    -- Старший повар
    INSERT INTO roles (module_id, code, name_ru, name_en, description_ru, description_en, color, is_system, sort_order)
    VALUES (kitchen_module_id, 'head_cook', 'Старший повар', 'Head Cook',
            'Управление меню, шаблонами и рецептами', 'Menu, templates and recipes management',
            '#f97316', true, 2)
    ON CONFLICT (module_id, code) DO UPDATE SET
        name_ru = EXCLUDED.name_ru,
        name_en = EXCLUDED.name_en,
        description_ru = EXCLUDED.description_ru,
        description_en = EXCLUDED.description_en
    RETURNING id INTO head_cook_role_id;

    IF head_cook_role_id IS NULL THEN
        SELECT id INTO head_cook_role_id FROM roles WHERE module_id = kitchen_module_id AND code = 'head_cook';
    END IF;

    -- Повар
    INSERT INTO roles (module_id, code, name_ru, name_en, description_ru, description_en, color, is_system, sort_order)
    VALUES (kitchen_module_id, 'cook', 'Повар', 'Cook',
            'Просмотр меню и рецептов', 'View menu and recipes',
            '#eab308', true, 3)
    ON CONFLICT (module_id, code) DO UPDATE SET
        name_ru = EXCLUDED.name_ru,
        name_en = EXCLUDED.name_en,
        description_ru = EXCLUDED.description_ru,
        description_en = EXCLUDED.description_en
    RETURNING id INTO cook_role_id;

    IF cook_role_id IS NULL THEN
        SELECT id INTO cook_role_id FROM roles WHERE module_id = kitchen_module_id AND code = 'cook';
    END IF;

    -- Завскладом
    INSERT INTO roles (module_id, code, name_ru, name_en, description_ru, description_en, color, is_system, sort_order)
    VALUES (kitchen_module_id, 'stock_manager', 'Завскладом', 'Stock Manager',
            'Управление складом, приёмки, выдачи, инвентаризации', 'Stock, receipts, issues, inventories',
            '#22c55e', true, 4)
    ON CONFLICT (module_id, code) DO UPDATE SET
        name_ru = EXCLUDED.name_ru,
        name_en = EXCLUDED.name_en,
        description_ru = EXCLUDED.description_ru,
        description_en = EXCLUDED.description_en
    RETURNING id INTO stock_manager_role_id;

    IF stock_manager_role_id IS NULL THEN
        SELECT id INTO stock_manager_role_id FROM roles WHERE module_id = kitchen_module_id AND code = 'stock_manager';
    END IF;

    -- Закупщик
    INSERT INTO roles (module_id, code, name_ru, name_en, description_ru, description_en, color, is_system, sort_order)
    VALUES (kitchen_module_id, 'buyer', 'Закупщик', 'Buyer',
            'Просмотр заявок и создание приёмок', 'View requests and create receipts',
            '#3b82f6', true, 5)
    ON CONFLICT (module_id, code) DO UPDATE SET
        name_ru = EXCLUDED.name_ru,
        name_en = EXCLUDED.name_en,
        description_ru = EXCLUDED.description_ru,
        description_en = EXCLUDED.description_en
    RETURNING id INTO buyer_role_id;

    IF buyer_role_id IS NULL THEN
        SELECT id INTO buyer_role_id FROM roles WHERE module_id = kitchen_module_id AND code = 'buyer';
    END IF;

    -- Наблюдатель
    INSERT INTO roles (module_id, code, name_ru, name_en, description_ru, description_en, color, is_system, sort_order)
    VALUES (kitchen_module_id, 'observer', 'Наблюдатель', 'Observer',
            'Только просмотр', 'View only',
            '#6b7280', true, 6)
    ON CONFLICT (module_id, code) DO UPDATE SET
        name_ru = EXCLUDED.name_ru,
        name_en = EXCLUDED.name_en,
        description_ru = EXCLUDED.description_ru,
        description_en = EXCLUDED.description_en
    RETURNING id INTO observer_role_id;

    IF observer_role_id IS NULL THEN
        SELECT id INTO observer_role_id FROM roles WHERE module_id = kitchen_module_id AND code = 'observer';
    END IF;

    -- ============================================
    -- НАЗНАЧЕНИЕ ПРАВ РОЛЯМ
    -- ============================================

    -- Очистка старых привязок
    DELETE FROM role_permissions WHERE role_id IN (
        admin_role_id, head_cook_role_id, cook_role_id,
        stock_manager_role_id, buyer_role_id, observer_role_id
    );

    -- ============================================
    -- АДМИНИСТРАТОР: все права
    -- ============================================
    INSERT INTO role_permissions (role_id, permission_id)
    SELECT admin_role_id, id FROM permissions WHERE module_id = kitchen_module_id;

    -- ============================================
    -- СТАРШИЙ ПОВАР
    -- ============================================
    -- menu.*, templates.*, recipes.*, products.view, stock.view, requests.view/create, retreats.view, team.view
    INSERT INTO role_permissions (role_id, permission_id)
    SELECT head_cook_role_id, id FROM permissions
    WHERE module_id = kitchen_module_id AND (
        category = 'menu' OR
        category = 'templates' OR
        category = 'recipes' OR
        code = 'products.view' OR
        code = 'stock.view' OR
        code IN ('requests.view', 'requests.create') OR
        code = 'retreats.view' OR
        code = 'team.view'
    );

    -- ============================================
    -- ПОВАР
    -- ============================================
    -- menu.view/edit, recipes.view, products.view, stock.view, retreats.view, team.view
    INSERT INTO role_permissions (role_id, permission_id)
    SELECT cook_role_id, id FROM permissions
    WHERE module_id = kitchen_module_id AND code IN (
        'menu.view', 'menu.edit',
        'recipes.view',
        'products.view',
        'stock.view',
        'retreats.view',
        'team.view'
    );

    -- ============================================
    -- ЗАВСКЛАДОМ
    -- ============================================
    -- products.*, stock.*, requests.*, receive.*, issue.*, inventory.*, settings.stock, team.view
    INSERT INTO role_permissions (role_id, permission_id)
    SELECT stock_manager_role_id, id FROM permissions
    WHERE module_id = kitchen_module_id AND (
        category = 'products' OR
        category = 'stock' OR
        category = 'requests' OR
        category = 'receive' OR
        category = 'issue' OR
        category = 'inventory' OR
        code = 'settings.stock' OR
        code = 'team.view'
    );

    -- ============================================
    -- ЗАКУПЩИК
    -- ============================================
    -- products.view, requests.view, receive.*
    INSERT INTO role_permissions (role_id, permission_id)
    SELECT buyer_role_id, id FROM permissions
    WHERE module_id = kitchen_module_id AND code IN (
        'products.view',
        'requests.view',
        'receive.view',
        'receive.create'
    );

    -- ============================================
    -- НАБЛЮДАТЕЛЬ
    -- ============================================
    -- *.view
    INSERT INTO role_permissions (role_id, permission_id)
    SELECT observer_role_id, id FROM permissions
    WHERE module_id = kitchen_module_id AND code LIKE '%.view';

END $$;

-- ============================================
-- ПЕРЕВОДЫ ДЛЯ КАТЕГОРИЙ ПРАВ
-- ============================================
INSERT INTO translations (key, ru, en, hi, page) VALUES
    ('perm_category_menu', 'Меню', 'Menu', 'मेनू', 'permissions'),
    ('perm_category_templates', 'Шаблоны', 'Templates', 'टेम्पलेट', 'permissions'),
    ('perm_category_recipes', 'Рецепты', 'Recipes', 'व्यंजन', 'permissions'),
    ('perm_category_products', 'Продукты', 'Products', 'उत्पाद', 'permissions'),
    ('perm_category_stock', 'Склад', 'Stock', 'स्टॉक', 'permissions'),
    ('perm_category_requests', 'Заявки', 'Requests', 'अनुरोध', 'permissions'),
    ('perm_category_receive', 'Приёмка', 'Receive', 'प्राप्ति', 'permissions'),
    ('perm_category_issue', 'Выдача', 'Issue', 'वितरण', 'permissions'),
    ('perm_category_inventory', 'Инвентаризация', 'Inventory', 'इन्वेंटरी', 'permissions'),
    ('perm_category_retreats', 'Ретриты', 'Retreats', 'रिट्रीट', 'permissions'),
    ('perm_category_team', 'Команда', 'Team', 'टीम', 'permissions'),
    ('perm_category_settings', 'Настройки', 'Settings', 'सेटिंग्स', 'permissions')
ON CONFLICT (key) DO UPDATE SET
    ru = EXCLUDED.ru,
    en = EXCLUDED.en,
    hi = EXCLUDED.hi,
    page = EXCLUDED.page;
