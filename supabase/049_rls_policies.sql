-- ============================================
-- 049: RLS политики безопасности
-- ============================================

-- ============================================
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
-- ============================================

-- Получить team_member_id текущего пользователя
CREATE OR REPLACE FUNCTION get_current_team_member_id()
RETURNS UUID
LANGUAGE SQL
SECURITY DEFINER
STABLE
AS $$
    SELECT id FROM team_members WHERE user_id = auth.uid() LIMIT 1;
$$;

-- Проверить, является ли пользователь суперпользователем
CREATE OR REPLACE FUNCTION is_superuser()
RETURNS BOOLEAN
LANGUAGE SQL
SECURITY DEFINER
STABLE
AS $$
    SELECT COALESCE(
        (SELECT is_superuser FROM team_members WHERE user_id = auth.uid() LIMIT 1),
        false
    );
$$;

-- ============================================
-- ОСНОВНАЯ ФУНКЦИЯ ПРОВЕРКИ ПРАВ
-- ============================================
CREATE OR REPLACE FUNCTION user_has_permission(permission_code TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
DECLARE
    current_user_id UUID;
    has_permission BOOLEAN := false;
    user_exception BOOLEAN;
BEGIN
    current_user_id := auth.uid();

    -- Анонимные пользователи не имеют прав
    IF current_user_id IS NULL THEN
        RETURN false;
    END IF;

    -- Суперпользователи имеют все права
    IF is_superuser() THEN
        RETURN true;
    END IF;

    -- Проверяем исключения пользователя (приоритет над ролями)
    SELECT is_granted INTO user_exception
    FROM user_permissions up
    JOIN permissions p ON p.id = up.permission_id
    WHERE up.user_id = current_user_id
      AND p.code = permission_code
      AND (up.expires_at IS NULL OR up.expires_at > NOW());

    -- Если есть исключение, возвращаем его значение
    IF user_exception IS NOT NULL THEN
        RETURN user_exception;
    END IF;

    -- Проверяем права через роли
    SELECT EXISTS (
        SELECT 1
        FROM user_roles ur
        JOIN role_permissions rp ON rp.role_id = ur.role_id
        JOIN permissions p ON p.id = rp.permission_id
        WHERE ur.user_id = current_user_id
          AND p.code = permission_code
          AND (ur.expires_at IS NULL OR ur.expires_at > NOW())
    ) INTO has_permission;

    RETURN has_permission;
END;
$$;

-- ============================================
-- ФУНКЦИЯ ПРОВЕРКИ ДОСТУПА К ЛОКАЦИИ
-- ============================================
CREATE OR REPLACE FUNCTION user_has_location_access(loc_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
DECLARE
    current_user_id UUID;
BEGIN
    current_user_id := auth.uid();

    -- Анонимные пользователи не имеют доступа
    IF current_user_id IS NULL THEN
        RETURN false;
    END IF;

    -- Суперпользователи имеют доступ ко всем локациям
    IF is_superuser() THEN
        RETURN true;
    END IF;

    -- Проверяем явный доступ к локации
    RETURN EXISTS (
        SELECT 1
        FROM user_locations
        WHERE user_id = current_user_id
          AND location_id = loc_id
    );
END;
$$;

-- ============================================
-- RLS ПОЛИТИКИ ДЛЯ ОСНОВНЫХ ТАБЛИЦ
-- ============================================

-- ============================================
-- RECIPES
-- ============================================
DROP POLICY IF EXISTS "Auth users read recipes with permission" ON recipes;
CREATE POLICY "Auth users read recipes with permission" ON recipes
    FOR SELECT TO authenticated
    USING (user_has_permission('recipes.view'));

DROP POLICY IF EXISTS "Auth users create recipes with permission" ON recipes;
CREATE POLICY "Auth users create recipes with permission" ON recipes
    FOR INSERT TO authenticated
    WITH CHECK (user_has_permission('recipes.create'));

DROP POLICY IF EXISTS "Auth users update recipes with permission" ON recipes;
CREATE POLICY "Auth users update recipes with permission" ON recipes
    FOR UPDATE TO authenticated
    USING (user_has_permission('recipes.edit'))
    WITH CHECK (user_has_permission('recipes.edit'));

DROP POLICY IF EXISTS "Auth users delete recipes with permission" ON recipes;
CREATE POLICY "Auth users delete recipes with permission" ON recipes
    FOR DELETE TO authenticated
    USING (user_has_permission('recipes.delete'));

-- ============================================
-- PRODUCTS
-- ============================================
DROP POLICY IF EXISTS "Auth users read products with permission" ON products;
CREATE POLICY "Auth users read products with permission" ON products
    FOR SELECT TO authenticated
    USING (user_has_permission('products.view'));

DROP POLICY IF EXISTS "Auth users create products with permission" ON products;
CREATE POLICY "Auth users create products with permission" ON products
    FOR INSERT TO authenticated
    WITH CHECK (user_has_permission('products.create'));

DROP POLICY IF EXISTS "Auth users update products with permission" ON products;
CREATE POLICY "Auth users update products with permission" ON products
    FOR UPDATE TO authenticated
    USING (user_has_permission('products.edit'))
    WITH CHECK (user_has_permission('products.edit'));

DROP POLICY IF EXISTS "Auth users delete products with permission" ON products;
CREATE POLICY "Auth users delete products with permission" ON products
    FOR DELETE TO authenticated
    USING (user_has_permission('products.delete'));

-- ============================================
-- RECIPE_CATEGORIES
-- ============================================
DROP POLICY IF EXISTS "Auth users read recipe_categories with permission" ON recipe_categories;
CREATE POLICY "Auth users read recipe_categories with permission" ON recipe_categories
    FOR SELECT TO authenticated
    USING (user_has_permission('recipes.view'));

-- ============================================
-- PRODUCT_CATEGORIES
-- ============================================
DROP POLICY IF EXISTS "Auth users read product_categories with permission" ON product_categories;
CREATE POLICY "Auth users read product_categories with permission" ON product_categories
    FOR SELECT TO authenticated
    USING (user_has_permission('products.view'));

-- ============================================
-- STOCK (с проверкой локации)
-- ============================================
DROP POLICY IF EXISTS "Auth users read stock with permission and location" ON stock;
CREATE POLICY "Auth users read stock with permission and location" ON stock
    FOR SELECT TO authenticated
    USING (
        user_has_permission('stock.view')
        AND user_has_location_access(location_id)
    );

DROP POLICY IF EXISTS "Auth users update stock with permission and location" ON stock;
CREATE POLICY "Auth users update stock with permission and location" ON stock
    FOR UPDATE TO authenticated
    USING (
        user_has_permission('stock.edit')
        AND user_has_location_access(location_id)
    )
    WITH CHECK (
        user_has_permission('stock.edit')
        AND user_has_location_access(location_id)
    );

-- ============================================
-- MENU_DAYS (с проверкой локации)
-- ============================================
DROP POLICY IF EXISTS "Auth users read menu_days with permission and location" ON menu_days;
CREATE POLICY "Auth users read menu_days with permission and location" ON menu_days
    FOR SELECT TO authenticated
    USING (
        user_has_permission('menu.view')
        AND user_has_location_access(location_id)
    );

DROP POLICY IF EXISTS "Auth users modify menu_days with permission and location" ON menu_days;
CREATE POLICY "Auth users modify menu_days with permission and location" ON menu_days
    FOR ALL TO authenticated
    USING (
        user_has_permission('menu.edit')
        AND user_has_location_access(location_id)
    )
    WITH CHECK (
        user_has_permission('menu.edit')
        AND user_has_location_access(location_id)
    );

-- ============================================
-- MENU_ITEMS
-- ============================================
DROP POLICY IF EXISTS "Auth users read menu_items with permission" ON menu_items;
CREATE POLICY "Auth users read menu_items with permission" ON menu_items
    FOR SELECT TO authenticated
    USING (
        user_has_permission('menu.view')
        AND EXISTS (
            SELECT 1 FROM menu_days md
            WHERE md.id = menu_items.menu_day_id
            AND user_has_location_access(md.location_id)
        )
    );

DROP POLICY IF EXISTS "Auth users modify menu_items with permission" ON menu_items;
CREATE POLICY "Auth users modify menu_items with permission" ON menu_items
    FOR ALL TO authenticated
    USING (
        user_has_permission('menu.edit')
        AND EXISTS (
            SELECT 1 FROM menu_days md
            WHERE md.id = menu_items.menu_day_id
            AND user_has_location_access(md.location_id)
        )
    )
    WITH CHECK (
        user_has_permission('menu.edit')
        AND EXISTS (
            SELECT 1 FROM menu_days md
            WHERE md.id = menu_items.menu_day_id
            AND user_has_location_access(md.location_id)
        )
    );

-- ============================================
-- TEAM_MEMBERS
-- ============================================
DROP POLICY IF EXISTS "Auth users read team_members with permission" ON team_members;
CREATE POLICY "Auth users read team_members with permission" ON team_members
    FOR SELECT TO authenticated
    USING (user_has_permission('team.view'));

DROP POLICY IF EXISTS "Auth users modify team_members with permission" ON team_members;
CREATE POLICY "Auth users modify team_members with permission" ON team_members
    FOR ALL TO authenticated
    USING (user_has_permission('team.edit'))
    WITH CHECK (user_has_permission('team.edit'));

-- ============================================
-- RETREATS (с проверкой локации)
-- ============================================
DROP POLICY IF EXISTS "Auth users read retreats with permission" ON retreats;
CREATE POLICY "Auth users read retreats with permission" ON retreats
    FOR SELECT TO authenticated
    USING (
        user_has_permission('retreats.view')
        AND (location_id IS NULL OR user_has_location_access(location_id))
    );

DROP POLICY IF EXISTS "Auth users modify retreats with permission" ON retreats;
CREATE POLICY "Auth users modify retreats with permission" ON retreats
    FOR ALL TO authenticated
    USING (
        user_has_permission('retreats.edit')
        AND (location_id IS NULL OR user_has_location_access(location_id))
    )
    WITH CHECK (
        user_has_permission('retreats.edit')
        AND (location_id IS NULL OR user_has_location_access(location_id))
    );

-- ============================================
-- LOCATIONS (только доступные пользователю)
-- ============================================
DROP POLICY IF EXISTS "Auth users read accessible locations" ON locations;
CREATE POLICY "Auth users read accessible locations" ON locations
    FOR SELECT TO authenticated
    USING (
        is_superuser()
        OR EXISTS (
            SELECT 1 FROM user_locations
            WHERE user_id = auth.uid()
            AND location_id = locations.id
        )
    );

-- ============================================
-- TRANSLATIONS, UNITS - открыты для чтения
-- ============================================
-- Политики уже есть в предыдущих миграциях

-- ============================================
-- RECIPE_INGREDIENTS
-- ============================================
DROP POLICY IF EXISTS "Auth users read recipe_ingredients with permission" ON recipe_ingredients;
CREATE POLICY "Auth users read recipe_ingredients with permission" ON recipe_ingredients
    FOR SELECT TO authenticated
    USING (user_has_permission('recipes.view'));

DROP POLICY IF EXISTS "Auth users modify recipe_ingredients with permission" ON recipe_ingredients;
CREATE POLICY "Auth users modify recipe_ingredients with permission" ON recipe_ingredients
    FOR ALL TO authenticated
    USING (user_has_permission('recipes.edit'))
    WITH CHECK (user_has_permission('recipes.edit'));

-- ============================================
-- HOLIDAYS
-- ============================================
DROP POLICY IF EXISTS "Auth users read holidays" ON holidays;
CREATE POLICY "Auth users read holidays" ON holidays
    FOR SELECT TO authenticated
    USING (true);

DROP POLICY IF EXISTS "Auth users modify holidays with permission" ON holidays;
CREATE POLICY "Auth users modify holidays with permission" ON holidays
    FOR ALL TO authenticated
    USING (user_has_permission('settings.festivals'))
    WITH CHECK (user_has_permission('settings.festivals'));

-- ============================================
-- ПРИМЕЧАНИЕ: Временно оставляем anon политики
-- для разработки. Удалить после внедрения auth!
-- ============================================
