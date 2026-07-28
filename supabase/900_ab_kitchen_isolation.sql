-- AB Kitchen: изоляция актуального кухонного интерфейса от остальных модулей.
-- Выполняется после исходных кухонных миграций 001-050 и 108/152.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Команда кухни. Поля соответствуют обращениям существующего интерфейса.
CREATE TABLE IF NOT EXISTS departments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name_ru TEXT NOT NULL,
    name_en TEXT,
    name_hi TEXT,
    color TEXT DEFAULT '#6b7280',
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS vaishnavas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name TEXT,
    last_name TEXT,
    spiritual_name TEXT,
    phone TEXT,
    email TEXT,
    telegram TEXT,
    has_whatsapp BOOLEAN DEFAULT false,
    birth_date DATE,
    gender TEXT,
    country TEXT,
    city TEXT,
    photo_url TEXT,
    india_experience TEXT,
    is_team_member BOOLEAN DEFAULT true,
    department_id UUID REFERENCES departments(id) ON DELETE SET NULL,
    passport TEXT,
    notes TEXT,
    is_deleted BOOLEAN DEFAULT false,
    spiritual_teacher TEXT,
    service TEXT,
    senior_id UUID REFERENCES vaishnavas(id) ON DELETE SET NULL,
    visa_type TEXT,
    visa_expiry DATE,
    indian_phone TEXT,
    indian_phone_whatsapp BOOLEAN DEFAULT false,
    user_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE SET NULL,
    user_type TEXT NOT NULL DEFAULT 'staff',
    approval_status TEXT NOT NULL DEFAULT 'approved',
    is_superuser BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    approved_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    approved_at TIMESTAMPTZ,
    last_login_at TIMESTAMPTZ,
    telegram_username TEXT,
    no_spiritual_teacher BOOLEAN DEFAULT false,
    parent_id UUID REFERENCES vaishnavas(id) ON DELETE SET NULL,
    guru_name TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_vaishnavas_user_id ON vaishnavas(user_id);
CREATE INDEX IF NOT EXISTS idx_vaishnavas_team ON vaishnavas(is_team_member, is_deleted);
CREATE INDEX IF NOT EXISTS idx_vaishnavas_department ON vaishnavas(department_id);

-- Существующий menu_meals исторически ссылался на team_members.
DO $$
DECLARE
    constraint_name TEXT;
BEGIN
    SELECT tc.constraint_name
      INTO constraint_name
      FROM information_schema.table_constraints tc
      JOIN information_schema.key_column_usage kcu
        ON tc.constraint_name = kcu.constraint_name
       AND tc.table_schema = kcu.table_schema
     WHERE tc.table_schema = 'public'
       AND tc.table_name = 'menu_meals'
       AND tc.constraint_type = 'FOREIGN KEY'
       AND kcu.column_name = 'cook_id'
     LIMIT 1;

    IF constraint_name IS NOT NULL THEN
        EXECUTE format('ALTER TABLE menu_meals DROP CONSTRAINT %I', constraint_name);
    END IF;
END $$;

-- Тестовые повара из раннего seed относятся к удалённой модели team_members.
UPDATE menu_meals SET cook_id = NULL;

ALTER TABLE menu_meals
    ADD CONSTRAINT menu_meals_cook_id_fkey
    FOREIGN KEY (cook_id) REFERENCES vaishnavas(id) ON DELETE SET NULL;

-- Недостающие в ранней истории поля и таблицы, используемые текущими страницами.
ALTER TABLE locations ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE product_categories ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE product_categories ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE product_categories ADD COLUMN IF NOT EXISTS emoji TEXT;
ALTER TABLE recipe_categories ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE recipe_categories ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE products ADD COLUMN IF NOT EXISTS ekadashi BOOLEAN DEFAULT false;
ALTER TABLE buyers ALTER COLUMN name DROP NOT NULL;
ALTER TABLE stock ADD COLUMN IF NOT EXISTS placement TEXT;
ALTER TABLE stock_receipts ADD COLUMN IF NOT EXISTS deleted BOOLEAN DEFAULT false;
ALTER TABLE stock_issuances ADD COLUMN IF NOT EXISTS receiver_id UUID REFERENCES vaishnavas(id) ON DELETE SET NULL;
ALTER TABLE stock_issuances ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE user_roles ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

CREATE TABLE IF NOT EXISTS product_densities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL UNIQUE REFERENCES products(id) ON DELETE CASCADE,
    tsp_grams NUMERIC,
    tbsp_grams NUMERIC,
    cup_grams NUMERIC,
    liter_grams NUMERIC,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS superusers (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- В отдельном приложении оставляем только кухонные права и роли.
TRUNCATE TABLE user_permissions, user_roles, role_permissions, roles, permissions, modules CASCADE;

INSERT INTO modules (code, name_ru, name_en, name_hi, sort_order)
VALUES ('kitchen', 'Кухня', 'Kitchen', 'रसोई', 1);

WITH kitchen AS (SELECT id FROM modules WHERE code = 'kitchen')
INSERT INTO permissions (module_id, code, name_ru, name_en, category, sort_order)
SELECT kitchen.id, p.code, p.name_ru, p.name_en, p.category, p.sort_order
FROM kitchen
CROSS JOIN (VALUES
    ('view_menu', 'Просмотр меню', 'View menu', 'menu', 1),
    ('edit_menu', 'Редактирование меню', 'Edit menu', 'menu', 2),
    ('view_menu_templates', 'Просмотр шаблонов меню', 'View menu templates', 'menu', 3),
    ('edit_menu_templates', 'Редактирование шаблонов меню', 'Edit menu templates', 'menu', 4),
    ('view_recipes', 'Просмотр рецептур', 'View recipes', 'recipes', 10),
    ('create_recipe', 'Создание рецептур', 'Create recipes', 'recipes', 11),
    ('edit_recipe', 'Редактирование рецептур', 'Edit recipes', 'recipes', 12),
    ('delete_recipe', 'Удаление рецептур', 'Delete recipes', 'recipes', 13),
    ('view_products', 'Просмотр продуктов', 'View products', 'products', 20),
    ('edit_products', 'Редактирование продуктов', 'Edit products', 'products', 21),
    ('view_kitchen_dictionaries', 'Просмотр справочников кухни', 'View kitchen dictionaries', 'settings', 22),
    ('edit_kitchen_dictionaries', 'Редактирование справочников кухни', 'Edit kitchen dictionaries', 'settings', 23),
    ('view_stock', 'Просмотр остатков', 'View stock', 'stock', 30),
    ('view_stock_settings', 'Просмотр настроек склада', 'View stock settings', 'stock', 31),
    ('edit_stock_settings', 'Редактирование настроек склада', 'Edit stock settings', 'stock', 32),
    ('view_requests', 'Просмотр заявок', 'View requests', 'requests', 40),
    ('create_request', 'Создание заявок', 'Create requests', 'requests', 41),
    ('edit_request', 'Редактирование заявок', 'Edit requests', 'requests', 42),
    ('delete_request', 'Удаление заявок', 'Delete requests', 'requests', 43),
    ('receive_stock', 'Приёмка продуктов', 'Receive stock', 'stock', 50),
    ('issue_stock', 'Выдача продуктов', 'Issue stock', 'stock', 51),
    ('conduct_inventory', 'Проведение инвентаризации', 'Conduct inventory', 'stock', 52),
    ('view_team', 'Просмотр команды кухни', 'View kitchen team', 'team', 60),
    ('edit_vaishnava', 'Редактирование команды', 'Edit team', 'team', 61),
    ('edit_own_profile', 'Редактирование своего профиля', 'Edit own profile', 'team', 62),
    ('manage_users', 'Управление пользователями', 'Manage users', 'users', 70)
) AS p(code, name_ru, name_en, category, sort_order);

WITH kitchen AS (SELECT id FROM modules WHERE code = 'kitchen')
INSERT INTO roles (module_id, code, name_ru, name_en, description_ru, description_en, color, is_system, sort_order)
SELECT kitchen.id, r.code, r.name_ru, r.name_en, r.description_ru, r.description_en, r.color, true, r.sort_order
FROM kitchen
CROSS JOIN (VALUES
    ('admin', 'Администратор', 'Administrator', 'Полный доступ', 'Full access', '#ef4444', 1),
    ('head_cook', 'Старший повар', 'Head Cook', 'Меню, рецептуры и продукты', 'Menu, recipes and products', '#f97316', 2),
    ('cook', 'Повар', 'Cook', 'Работа с меню и рецептурами', 'Menu and recipes', '#eab308', 3),
    ('stock_manager', 'Завскладом', 'Stock Manager', 'Складской учёт', 'Stock management', '#22c55e', 4),
    ('buyer', 'Закупщик', 'Buyer', 'Закупки и приёмка', 'Purchasing and receiving', '#3b82f6', 5),
    ('observer', 'Наблюдатель', 'Observer', 'Только просмотр', 'Read only', '#6b7280', 6)
) AS r(code, name_ru, name_en, description_ru, description_en, color, sort_order);

-- Администратор получает все кухонные права.
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.module_id = r.module_id
WHERE r.code = 'admin';

-- Старший повар.
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r JOIN permissions p ON p.module_id = r.module_id
WHERE r.code = 'head_cook'
  AND p.code IN (
      'view_menu','edit_menu','view_menu_templates','edit_menu_templates',
      'view_recipes','create_recipe','edit_recipe','delete_recipe',
      'view_products','edit_products','view_kitchen_dictionaries',
      'view_stock','view_requests','create_request','edit_request','view_team'
  );

-- Повар.
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r JOIN permissions p ON p.module_id = r.module_id
WHERE r.code = 'cook'
  AND p.code IN ('view_menu','edit_menu','view_menu_templates','view_recipes','view_products','view_stock','view_team');

-- Завскладом.
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r JOIN permissions p ON p.module_id = r.module_id
WHERE r.code = 'stock_manager'
  AND p.code IN (
      'view_products','edit_products','view_stock','view_stock_settings','edit_stock_settings',
      'view_requests','create_request','edit_request','delete_request',
      'receive_stock','issue_stock','conduct_inventory','view_team'
  );

-- Закупщик.
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r JOIN permissions p ON p.module_id = r.module_id
WHERE r.code = 'buyer'
  AND p.code IN ('view_products','view_stock','view_requests','create_request','edit_request','receive_stock');

-- Наблюдатель.
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r JOIN permissions p ON p.module_id = r.module_id
WHERE r.code = 'observer'
  AND p.code IN (
      'view_menu','view_menu_templates','view_recipes','view_products',
      'view_kitchen_dictionaries','view_stock','view_stock_settings','view_requests','view_team'
  );

-- Проверка суперпользователя без рекурсии RLS.
CREATE OR REPLACE FUNCTION public.abk_is_superuser(p_user_id UUID DEFAULT auth.uid())
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM vaishnavas
        WHERE user_id = p_user_id
          AND is_superuser = true
          AND is_active = true
          AND approval_status = 'approved'
          AND is_deleted = false
    );
$$;

CREATE OR REPLACE FUNCTION public.has_permission(user_uuid UUID, perm_code TEXT)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
    SELECT public.abk_is_superuser(user_uuid);
$$;

CREATE OR REPLACE FUNCTION public.get_user_permissions(p_user_id UUID)
RETURNS TABLE(permission_code TEXT)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
BEGIN
    IF auth.uid() IS NULL OR auth.uid() <> p_user_id THEN
        RETURN;
    END IF;

    IF public.abk_is_superuser(p_user_id) THEN
        RETURN QUERY SELECT p.code::TEXT FROM permissions p ORDER BY p.code;
        RETURN;
    END IF;

    RETURN QUERY
    SELECT DISTINCT granted.code::TEXT
    FROM (
        SELECT p.code
        FROM user_roles ur
        JOIN role_permissions rp ON rp.role_id = ur.role_id
        JOIN permissions p ON p.id = rp.permission_id
        WHERE ur.user_id = p_user_id AND COALESCE(ur.is_active, true)
        UNION
        SELECT p.code
        FROM user_permissions up
        JOIN permissions p ON p.id = up.permission_id
        WHERE up.user_id = p_user_id AND up.is_granted = true
    ) granted
    WHERE NOT EXISTS (
        SELECT 1
        FROM user_permissions denied
        JOIN permissions p ON p.id = denied.permission_id
        WHERE denied.user_id = p_user_id
          AND denied.is_granted = false
          AND p.code = granted.code
    )
    ORDER BY granted.code;
END;
$$;

CREATE OR REPLACE FUNCTION public.link_auth_user_to_vaishnava()
RETURNS TABLE(success BOOLEAN, vaishnava_id UUID, error_code TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
DECLARE
    auth_id UUID := auth.uid();
    auth_email TEXT;
    person_id UUID;
    linked_user UUID;
BEGIN
    IF auth_id IS NULL THEN
        RETURN QUERY SELECT false, NULL::UUID, 'no_session'::TEXT;
        RETURN;
    END IF;

    SELECT email INTO auth_email FROM auth.users WHERE id = auth_id;
    SELECT id INTO person_id FROM vaishnavas WHERE user_id = auth_id LIMIT 1;

    IF person_id IS NULL THEN
        SELECT id, user_id
          INTO person_id, linked_user
          FROM vaishnavas
         WHERE LOWER(email) = LOWER(auth_email)
         ORDER BY id
         LIMIT 1
         FOR UPDATE;

        IF person_id IS NULL THEN
            RETURN QUERY SELECT false, NULL::UUID, 'not_found'::TEXT;
            RETURN;
        ELSIF linked_user IS NOT NULL AND linked_user <> auth_id THEN
            RETURN QUERY SELECT false, NULL::UUID, 'conflict'::TEXT;
            RETURN;
        END IF;

        UPDATE vaishnavas
           SET user_id = auth_id,
               is_superuser = true,
               updated_at = NOW()
         WHERE id = person_id;
    END IF;

    UPDATE vaishnavas
       SET is_superuser = true,
           updated_at = NOW()
     WHERE id = person_id;

    RETURN QUERY SELECT true, person_id, NULL::TEXT;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_user_permissions(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.link_auth_user_to_vaishnava() TO authenticated;
GRANT EXECUTE ON FUNCTION public.has_permission(UUID, TEXT) TO authenticated;

-- Транзакционная приёмка и корректировка остатков.
CREATE OR REPLACE FUNCTION public.save_stock_receipt(
    p_location_id UUID,
    p_date DATE,
    p_buyer_id UUID,
    p_notes TEXT,
    p_items JSONB
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    receipt_id UUID;
    item JSONB;
    qty NUMERIC;
    spent NUMERIC;
BEGIN
    IF NOT public.has_permission(auth.uid(), 'receive_stock') THEN
        RAISE EXCEPTION 'Insufficient permissions';
    END IF;

    INSERT INTO stock_receipts(location_id, receipt_date, buyer_id, notes)
    VALUES (p_location_id, p_date, p_buyer_id, NULLIF(p_notes, ''))
    RETURNING id INTO receipt_id;

    FOR item IN SELECT * FROM jsonb_array_elements(COALESCE(p_items, '[]'::JSONB))
    LOOP
        qty := COALESCE((item->>'quantity')::NUMERIC, 0);
        spent := COALESCE((item->>'spent')::NUMERIC, 0);

        INSERT INTO stock_receipt_items(receipt_id, product_id, quantity, price)
        VALUES (
            receipt_id,
            (item->>'product_id')::UUID,
            qty,
            CASE WHEN qty > 0 THEN spent / qty ELSE 0 END
        );

        INSERT INTO stock(location_id, product_id, current_quantity)
        VALUES (p_location_id, (item->>'product_id')::UUID, qty)
        ON CONFLICT (location_id, product_id)
        DO UPDATE SET current_quantity = stock.current_quantity + EXCLUDED.current_quantity,
                      updated_at = NOW();
    END LOOP;

    RETURN receipt_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_stock_receipt_items(
    p_receipt_id UUID,
    p_items JSONB
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    loc_id UUID;
    old_item RECORD;
    item JSONB;
    qty NUMERIC;
    spent NUMERIC;
BEGIN
    IF NOT public.has_permission(auth.uid(), 'receive_stock') THEN
        RAISE EXCEPTION 'Insufficient permissions';
    END IF;

    SELECT location_id INTO loc_id FROM stock_receipts WHERE id = p_receipt_id FOR UPDATE;

    FOR old_item IN SELECT product_id, quantity FROM stock_receipt_items WHERE receipt_id = p_receipt_id
    LOOP
        UPDATE stock
           SET current_quantity = current_quantity - old_item.quantity,
               updated_at = NOW()
         WHERE location_id = loc_id AND product_id = old_item.product_id;
    END LOOP;

    DELETE FROM stock_receipt_items WHERE receipt_id = p_receipt_id;

    FOR item IN SELECT * FROM jsonb_array_elements(COALESCE(p_items, '[]'::JSONB))
    LOOP
        qty := COALESCE((item->>'quantity')::NUMERIC, 0);
        spent := COALESCE((item->>'spent')::NUMERIC, 0);

        INSERT INTO stock_receipt_items(receipt_id, product_id, quantity, price)
        VALUES (
            p_receipt_id,
            (item->>'product_id')::UUID,
            qty,
            CASE WHEN qty > 0 THEN spent / qty ELSE 0 END
        );

        INSERT INTO stock(location_id, product_id, current_quantity)
        VALUES (loc_id, (item->>'product_id')::UUID, qty)
        ON CONFLICT (location_id, product_id)
        DO UPDATE SET current_quantity = stock.current_quantity + EXCLUDED.current_quantity,
                      updated_at = NOW();
    END LOOP;
END;
$$;

-- Транзакционная выдача.
CREATE OR REPLACE FUNCTION public.save_stock_issuance(
    p_location_id UUID,
    p_date DATE,
    p_receiver_id UUID,
    p_notes TEXT,
    p_items JSONB
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    issuance_id UUID;
    item JSONB;
    qty NUMERIC;
BEGIN
    IF NOT public.has_permission(auth.uid(), 'issue_stock') THEN
        RAISE EXCEPTION 'Insufficient permissions';
    END IF;

    INSERT INTO stock_issuances(location_id, issuance_date, receiver_id, notes)
    VALUES (p_location_id, p_date, p_receiver_id, NULLIF(p_notes, ''))
    RETURNING id INTO issuance_id;

    FOR item IN SELECT * FROM jsonb_array_elements(COALESCE(p_items, '[]'::JSONB))
    LOOP
        qty := COALESCE((item->>'quantity')::NUMERIC, 0);

        INSERT INTO stock_issuance_items(issuance_id, product_id, quantity)
        VALUES (issuance_id, (item->>'product_id')::UUID, qty);

        UPDATE stock
           SET current_quantity = current_quantity - qty,
               updated_at = NOW()
         WHERE location_id = p_location_id
           AND product_id = (item->>'product_id')::UUID
           AND current_quantity >= qty;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Insufficient stock';
        END IF;
    END LOOP;

    RETURN issuance_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_stock_issuance_items(
    p_issuance_id UUID,
    p_items JSONB
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    loc_id UUID;
    old_item RECORD;
    item JSONB;
    qty NUMERIC;
BEGIN
    IF NOT public.has_permission(auth.uid(), 'issue_stock') THEN
        RAISE EXCEPTION 'Insufficient permissions';
    END IF;

    SELECT location_id INTO loc_id FROM stock_issuances WHERE id = p_issuance_id FOR UPDATE;

    FOR old_item IN SELECT product_id, quantity FROM stock_issuance_items WHERE issuance_id = p_issuance_id
    LOOP
        INSERT INTO stock(location_id, product_id, current_quantity)
        VALUES (loc_id, old_item.product_id, old_item.quantity)
        ON CONFLICT (location_id, product_id)
        DO UPDATE SET current_quantity = stock.current_quantity + EXCLUDED.current_quantity,
                      updated_at = NOW();
    END LOOP;

    DELETE FROM stock_issuance_items WHERE issuance_id = p_issuance_id;

    FOR item IN SELECT * FROM jsonb_array_elements(COALESCE(p_items, '[]'::JSONB))
    LOOP
        qty := COALESCE((item->>'quantity')::NUMERIC, 0);

        INSERT INTO stock_issuance_items(issuance_id, product_id, quantity)
        VALUES (p_issuance_id, (item->>'product_id')::UUID, qty);

        UPDATE stock
           SET current_quantity = current_quantity - qty,
               updated_at = NOW()
         WHERE location_id = loc_id
           AND product_id = (item->>'product_id')::UUID
           AND current_quantity >= qty;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Insufficient stock';
        END IF;
    END LOOP;
END;
$$;

GRANT EXECUTE ON FUNCTION public.save_stock_receipt(UUID, DATE, UUID, TEXT, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_stock_receipt_items(UUID, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.save_stock_issuance(UUID, DATE, UUID, TEXT, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_stock_issuance_items(UUID, JSONB) TO authenticated;

-- Удаляем исторические открытые политики из переносимых таблиц.
DO $$
DECLARE
    policy_row RECORD;
    table_name TEXT;
    kitchen_tables TEXT[] := ARRAY[
        'locations','translations','product_categories','products','recipe_categories',
        'recipes','recipe_ingredients','units','product_densities','holidays','retreats',
        'menu_meals','menu_dishes','menu_templates','menu_template_meals','menu_template_dishes',
        'buyers','stock','purchase_requests','purchase_request_items',
        'stock_receipts','stock_receipt_items','stock_issuances','stock_issuance_items',
        'stock_inventories','stock_inventory_items','departments','vaishnavas',
        'modules','permissions','roles','role_permissions','user_roles','user_permissions',
        'user_locations','superusers'
    ];
BEGIN
    FOREACH table_name IN ARRAY kitchen_tables
    LOOP
        IF to_regclass('public.' || table_name) IS NOT NULL THEN
            EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', table_name);
            FOR policy_row IN
                SELECT policyname FROM pg_policies
                WHERE schemaname = 'public' AND tablename = table_name
            LOOP
                EXECUTE format('DROP POLICY %I ON %I', policy_row.policyname, table_name);
            END LOOP;
        END IF;
    END LOOP;
END $$;

-- Публично доступно только то, что нужно до авторизации.
CREATE POLICY translations_public_read ON translations FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY locations_authenticated_read ON locations FOR SELECT TO authenticated USING (true);

-- Справочники и рабочие данные читают только авторизованные пользователи приложения.
DO $$
DECLARE
    table_name TEXT;
    read_tables TEXT[] := ARRAY[
        'product_categories','products','recipe_categories','recipes','recipe_ingredients',
        'units','product_densities','holidays','retreats','menu_meals','menu_dishes',
        'menu_templates','menu_template_meals','menu_template_dishes','buyers','stock',
        'purchase_requests','purchase_request_items','stock_receipts','stock_receipt_items',
        'stock_issuances','stock_issuance_items','stock_inventories','stock_inventory_items',
        'departments','modules','permissions','roles','role_permissions'
    ];
BEGIN
    FOREACH table_name IN ARRAY read_tables
    LOOP
        EXECUTE format(
            'CREATE POLICY %I ON %I FOR SELECT TO authenticated USING (true)',
            table_name || '_authenticated_read',
            table_name
        );
    END LOOP;
END $$;

CREATE POLICY vaishnavas_authenticated_read ON vaishnavas
FOR SELECT TO authenticated
USING (
    user_id = auth.uid()
    OR public.abk_is_superuser(auth.uid())
    OR (is_team_member = true AND public.has_permission(auth.uid(), 'view_team'))
);

CREATE POLICY own_roles_read ON user_roles FOR SELECT TO authenticated
USING (user_id = auth.uid() OR public.abk_is_superuser(auth.uid()) OR public.has_permission(auth.uid(), 'manage_users'));
CREATE POLICY own_permissions_read ON user_permissions FOR SELECT TO authenticated
USING (user_id = auth.uid() OR public.abk_is_superuser(auth.uid()) OR public.has_permission(auth.uid(), 'manage_users'));
CREATE POLICY own_locations_read ON user_locations FOR SELECT TO authenticated
USING (user_id = auth.uid() OR public.abk_is_superuser(auth.uid()) OR public.has_permission(auth.uid(), 'manage_users'));
CREATE POLICY superusers_self_read ON superusers FOR SELECT TO authenticated
USING (user_id = auth.uid() OR public.abk_is_superuser(auth.uid()));

-- Изменения меню.
CREATE POLICY menu_meals_write ON menu_meals FOR ALL TO authenticated
USING (public.has_permission(auth.uid(), 'edit_menu'))
WITH CHECK (public.has_permission(auth.uid(), 'edit_menu'));
CREATE POLICY menu_dishes_write ON menu_dishes FOR ALL TO authenticated
USING (public.has_permission(auth.uid(), 'edit_menu'))
WITH CHECK (public.has_permission(auth.uid(), 'edit_menu'));
CREATE POLICY menu_templates_write ON menu_templates FOR ALL TO authenticated
USING (public.has_permission(auth.uid(), 'edit_menu_templates'))
WITH CHECK (public.has_permission(auth.uid(), 'edit_menu_templates'));
CREATE POLICY menu_template_meals_write ON menu_template_meals FOR ALL TO authenticated
USING (public.has_permission(auth.uid(), 'edit_menu_templates'))
WITH CHECK (public.has_permission(auth.uid(), 'edit_menu_templates'));
CREATE POLICY menu_template_dishes_write ON menu_template_dishes FOR ALL TO authenticated
USING (public.has_permission(auth.uid(), 'edit_menu_templates'))
WITH CHECK (public.has_permission(auth.uid(), 'edit_menu_templates'));

-- Рецептуры и продукты.
CREATE POLICY recipes_write ON recipes FOR ALL TO authenticated
USING (public.has_permission(auth.uid(), 'edit_recipe') OR public.has_permission(auth.uid(), 'delete_recipe'))
WITH CHECK (public.has_permission(auth.uid(), 'edit_recipe') OR public.has_permission(auth.uid(), 'create_recipe'));
CREATE POLICY recipe_ingredients_write ON recipe_ingredients FOR ALL TO authenticated
USING (public.has_permission(auth.uid(), 'edit_recipe') OR public.has_permission(auth.uid(), 'delete_recipe'))
WITH CHECK (public.has_permission(auth.uid(), 'edit_recipe') OR public.has_permission(auth.uid(), 'create_recipe'));
CREATE POLICY products_write ON products FOR ALL TO authenticated
USING (public.has_permission(auth.uid(), 'edit_products'))
WITH CHECK (public.has_permission(auth.uid(), 'edit_products'));
CREATE POLICY product_categories_write ON product_categories FOR ALL TO authenticated
USING (public.has_permission(auth.uid(), 'edit_kitchen_dictionaries'))
WITH CHECK (public.has_permission(auth.uid(), 'edit_kitchen_dictionaries'));
CREATE POLICY recipe_categories_write ON recipe_categories FOR ALL TO authenticated
USING (public.has_permission(auth.uid(), 'edit_kitchen_dictionaries'))
WITH CHECK (public.has_permission(auth.uid(), 'edit_kitchen_dictionaries'));
CREATE POLICY units_write ON units FOR ALL TO authenticated
USING (public.has_permission(auth.uid(), 'edit_kitchen_dictionaries'))
WITH CHECK (public.has_permission(auth.uid(), 'edit_kitchen_dictionaries'));
CREATE POLICY product_densities_write ON product_densities FOR ALL TO authenticated
USING (public.has_permission(auth.uid(), 'edit_kitchen_dictionaries'))
WITH CHECK (public.has_permission(auth.uid(), 'edit_kitchen_dictionaries'));

-- Склад.
CREATE POLICY stock_write ON stock FOR ALL TO authenticated
USING (
    public.has_permission(auth.uid(), 'edit_stock_settings')
    OR public.has_permission(auth.uid(), 'receive_stock')
    OR public.has_permission(auth.uid(), 'issue_stock')
    OR public.has_permission(auth.uid(), 'conduct_inventory')
)
WITH CHECK (
    public.has_permission(auth.uid(), 'edit_stock_settings')
    OR public.has_permission(auth.uid(), 'receive_stock')
    OR public.has_permission(auth.uid(), 'issue_stock')
    OR public.has_permission(auth.uid(), 'conduct_inventory')
);
CREATE POLICY buyers_write ON buyers FOR ALL TO authenticated
USING (public.has_permission(auth.uid(), 'edit_stock_settings'))
WITH CHECK (public.has_permission(auth.uid(), 'edit_stock_settings'));
CREATE POLICY requests_write ON purchase_requests FOR ALL TO authenticated
USING (public.has_permission(auth.uid(), 'edit_request') OR public.has_permission(auth.uid(), 'delete_request'))
WITH CHECK (public.has_permission(auth.uid(), 'create_request') OR public.has_permission(auth.uid(), 'edit_request'));
CREATE POLICY request_items_write ON purchase_request_items FOR ALL TO authenticated
USING (public.has_permission(auth.uid(), 'edit_request') OR public.has_permission(auth.uid(), 'delete_request'))
WITH CHECK (public.has_permission(auth.uid(), 'create_request') OR public.has_permission(auth.uid(), 'edit_request'));
CREATE POLICY receipts_write ON stock_receipts FOR ALL TO authenticated
USING (public.has_permission(auth.uid(), 'receive_stock'))
WITH CHECK (public.has_permission(auth.uid(), 'receive_stock'));
CREATE POLICY receipt_items_write ON stock_receipt_items FOR ALL TO authenticated
USING (public.has_permission(auth.uid(), 'receive_stock'))
WITH CHECK (public.has_permission(auth.uid(), 'receive_stock'));
CREATE POLICY issuances_write ON stock_issuances FOR ALL TO authenticated
USING (public.has_permission(auth.uid(), 'issue_stock'))
WITH CHECK (public.has_permission(auth.uid(), 'issue_stock'));
CREATE POLICY issuance_items_write ON stock_issuance_items FOR ALL TO authenticated
USING (public.has_permission(auth.uid(), 'issue_stock'))
WITH CHECK (public.has_permission(auth.uid(), 'issue_stock'));
CREATE POLICY inventories_write ON stock_inventories FOR ALL TO authenticated
USING (public.has_permission(auth.uid(), 'conduct_inventory'))
WITH CHECK (public.has_permission(auth.uid(), 'conduct_inventory'));
CREATE POLICY inventory_items_write ON stock_inventory_items FOR ALL TO authenticated
USING (public.has_permission(auth.uid(), 'conduct_inventory'))
WITH CHECK (public.has_permission(auth.uid(), 'conduct_inventory'));

-- Команда и управление доступом.
CREATE POLICY vaishnavas_write ON vaishnavas FOR ALL TO authenticated
USING (
    public.abk_is_superuser(auth.uid())
    OR public.has_permission(auth.uid(), 'edit_vaishnava')
    OR user_id = auth.uid()
)
WITH CHECK (
    public.abk_is_superuser(auth.uid())
    OR public.has_permission(auth.uid(), 'edit_vaishnava')
    OR user_id = auth.uid()
);
CREATE POLICY departments_write ON departments FOR ALL TO authenticated
USING (public.abk_is_superuser(auth.uid()) OR public.has_permission(auth.uid(), 'manage_users'))
WITH CHECK (public.abk_is_superuser(auth.uid()) OR public.has_permission(auth.uid(), 'manage_users'));
CREATE POLICY roles_manage ON user_roles FOR ALL TO authenticated
USING (public.abk_is_superuser(auth.uid()) OR public.has_permission(auth.uid(), 'manage_users'))
WITH CHECK (public.abk_is_superuser(auth.uid()) OR public.has_permission(auth.uid(), 'manage_users'));
CREATE POLICY permissions_manage ON user_permissions FOR ALL TO authenticated
USING (public.abk_is_superuser(auth.uid()) OR public.has_permission(auth.uid(), 'manage_users'))
WITH CHECK (public.abk_is_superuser(auth.uid()) OR public.has_permission(auth.uid(), 'manage_users'));

-- Storage для существующих загрузчиков фотографий рецептов.
INSERT INTO storage.buckets (id, name, public)
VALUES ('recipe-photos', 'recipe-photos', true)
ON CONFLICT (id) DO UPDATE SET public = true;

DROP POLICY IF EXISTS recipe_photos_public_read ON storage.objects;
DROP POLICY IF EXISTS recipe_photos_authenticated_insert ON storage.objects;
DROP POLICY IF EXISTS recipe_photos_authenticated_update ON storage.objects;
DROP POLICY IF EXISTS recipe_photos_authenticated_delete ON storage.objects;
CREATE POLICY recipe_photos_public_read ON storage.objects
FOR SELECT USING (bucket_id = 'recipe-photos');
CREATE POLICY recipe_photos_authenticated_insert ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'recipe-photos' AND public.has_permission(auth.uid(), 'edit_recipe'));
CREATE POLICY recipe_photos_authenticated_update ON storage.objects
FOR UPDATE TO authenticated
USING (bucket_id = 'recipe-photos' AND public.has_permission(auth.uid(), 'edit_recipe'))
WITH CHECK (bucket_id = 'recipe-photos' AND public.has_permission(auth.uid(), 'edit_recipe'));
CREATE POLICY recipe_photos_authenticated_delete ON storage.objects
FOR DELETE TO authenticated
USING (bucket_id = 'recipe-photos' AND public.has_permission(auth.uid(), 'edit_recipe'));

-- Название приложения всегда отделено от исходного back-office.
INSERT INTO translations (key, ru, en, hi, context, page)
VALUES
    ('app_name', 'AB Kitchen', 'AB Kitchen', 'AB Kitchen', 'Название приложения', 'layout'),
    ('app_name_short', 'AB Kitchen', 'AB Kitchen', 'AB Kitchen', 'Короткое название', 'layout'),
    ('nav_user_management', 'Пользователи', 'Users', 'उपयोगकर्ता', 'Навигация', 'layout')
ON CONFLICT (key) DO UPDATE SET
    ru = EXCLUDED.ru,
    en = EXCLUDED.en,
    hi = EXCLUDED.hi,
    context = EXCLUDED.context,
    page = EXCLUDED.page;
