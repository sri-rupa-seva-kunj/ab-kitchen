-- ============================================
-- 050: API функции для клиента
-- ============================================

-- ============================================
-- 1. ПОЛУЧИТЬ ВСЕ ПРАВА ТЕКУЩЕГО ПОЛЬЗОВАТЕЛЯ
-- ============================================
CREATE OR REPLACE FUNCTION get_user_permissions()
RETURNS TABLE (
    permission_code TEXT,
    permission_name_ru TEXT,
    permission_name_en TEXT,
    module_code TEXT,
    category TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
DECLARE
    current_user_id UUID;
BEGIN
    current_user_id := auth.uid();

    IF current_user_id IS NULL THEN
        RETURN;
    END IF;

    -- Если суперпользователь - возвращаем все права
    IF is_superuser() THEN
        RETURN QUERY
        SELECT
            p.code::TEXT,
            p.name_ru::TEXT,
            p.name_en::TEXT,
            m.code::TEXT,
            p.category::TEXT
        FROM permissions p
        JOIN modules m ON m.id = p.module_id
        WHERE m.is_active = true
        ORDER BY m.sort_order, p.sort_order;
        RETURN;
    END IF;

    -- Собираем права из ролей (кроме отнятых через исключения)
    RETURN QUERY
    WITH role_perms AS (
        -- Права из ролей
        SELECT DISTINCT p.id AS permission_id
        FROM user_roles ur
        JOIN role_permissions rp ON rp.role_id = ur.role_id
        JOIN permissions p ON p.id = rp.permission_id
        WHERE ur.user_id = current_user_id
          AND (ur.expires_at IS NULL OR ur.expires_at > NOW())
    ),
    granted_perms AS (
        -- Явно добавленные права
        SELECT up.permission_id
        FROM user_permissions up
        WHERE up.user_id = current_user_id
          AND up.is_granted = true
          AND (up.expires_at IS NULL OR up.expires_at > NOW())
    ),
    revoked_perms AS (
        -- Явно отнятые права
        SELECT up.permission_id
        FROM user_permissions up
        WHERE up.user_id = current_user_id
          AND up.is_granted = false
          AND (up.expires_at IS NULL OR up.expires_at > NOW())
    ),
    final_perms AS (
        SELECT permission_id FROM role_perms
        UNION
        SELECT permission_id FROM granted_perms
        EXCEPT
        SELECT permission_id FROM revoked_perms
    )
    SELECT
        p.code::TEXT,
        p.name_ru::TEXT,
        p.name_en::TEXT,
        m.code::TEXT,
        p.category::TEXT
    FROM final_perms fp
    JOIN permissions p ON p.id = fp.permission_id
    JOIN modules m ON m.id = p.module_id
    WHERE m.is_active = true
    ORDER BY m.sort_order, p.sort_order;
END;
$$;

-- ============================================
-- 2. ПОЛУЧИТЬ ДОСТУПНЫЕ ЛОКАЦИИ ПОЛЬЗОВАТЕЛЯ
-- ============================================
CREATE OR REPLACE FUNCTION get_user_locations()
RETURNS TABLE (
    location_id UUID,
    slug TEXT,
    name_ru TEXT,
    name_en TEXT,
    name_hi TEXT,
    color TEXT,
    is_default BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
DECLARE
    current_user_id UUID;
BEGIN
    current_user_id := auth.uid();

    IF current_user_id IS NULL THEN
        RETURN;
    END IF;

    -- Если суперпользователь - возвращаем все локации
    IF is_superuser() THEN
        RETURN QUERY
        SELECT
            l.id,
            l.slug::TEXT,
            l.name_ru::TEXT,
            l.name_en::TEXT,
            l.name_hi::TEXT,
            l.color::TEXT,
            false AS is_default
        FROM locations l
        ORDER BY l.slug;
        RETURN;
    END IF;

    -- Возвращаем только доступные локации
    RETURN QUERY
    SELECT
        l.id,
        l.slug::TEXT,
        l.name_ru::TEXT,
        l.name_en::TEXT,
        l.name_hi::TEXT,
        l.color::TEXT,
        COALESCE(ul.is_default, false)
    FROM user_locations ul
    JOIN locations l ON l.id = ul.location_id
    WHERE ul.user_id = current_user_id
    ORDER BY ul.is_default DESC, l.slug;
END;
$$;

-- ============================================
-- 3. ИНФОРМАЦИЯ О ТЕКУЩЕМ ПОЛЬЗОВАТЕЛЕ
-- ============================================
CREATE OR REPLACE FUNCTION get_current_user_info()
RETURNS TABLE (
    user_id UUID,
    team_member_id UUID,
    first_name TEXT,
    spiritual_name TEXT,
    email TEXT,
    is_superuser BOOLEAN,
    is_active BOOLEAN,
    roles JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
DECLARE
    current_user_id UUID;
BEGIN
    current_user_id := auth.uid();

    IF current_user_id IS NULL THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT
        current_user_id,
        tm.id,
        tm.first_name::TEXT,
        tm.spiritual_name::TEXT,
        (SELECT au.email FROM auth.users au WHERE au.id = current_user_id)::TEXT,
        COALESCE(tm.is_superuser, false),
        COALESCE(tm.is_active, true),
        COALESCE(
            (
                SELECT jsonb_agg(
                    jsonb_build_object(
                        'id', r.id,
                        'code', r.code,
                        'name_ru', r.name_ru,
                        'name_en', r.name_en,
                        'color', r.color,
                        'module_code', m.code
                    )
                )
                FROM user_roles ur
                JOIN roles r ON r.id = ur.role_id
                JOIN modules m ON m.id = r.module_id
                WHERE ur.user_id = current_user_id
                  AND (ur.expires_at IS NULL OR ur.expires_at > NOW())
            ),
            '[]'::jsonb
        )
    FROM team_members tm
    WHERE tm.user_id = current_user_id;
END;
$$;

-- ============================================
-- 4. ПРОВЕРИТЬ КОНКРЕТНОЕ ПРАВО (для клиента)
-- ============================================
-- Функция user_has_permission уже создана в 049

-- ============================================
-- 5. ПОЛУЧИТЬ ВСЕ РОЛИ МОДУЛЯ (для UI)
-- ============================================
CREATE OR REPLACE FUNCTION get_module_roles(module_code_param TEXT)
RETURNS TABLE (
    role_id UUID,
    code TEXT,
    name_ru TEXT,
    name_en TEXT,
    name_hi TEXT,
    description_ru TEXT,
    description_en TEXT,
    color TEXT,
    is_system BOOLEAN,
    permissions JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
BEGIN
    RETURN QUERY
    SELECT
        r.id,
        r.code::TEXT,
        r.name_ru::TEXT,
        r.name_en::TEXT,
        r.name_hi::TEXT,
        r.description_ru::TEXT,
        r.description_en::TEXT,
        r.color::TEXT,
        r.is_system,
        COALESCE(
            (
                SELECT jsonb_agg(
                    jsonb_build_object(
                        'id', p.id,
                        'code', p.code,
                        'name_ru', p.name_ru,
                        'name_en', p.name_en,
                        'category', p.category
                    )
                    ORDER BY p.sort_order
                )
                FROM role_permissions rp
                JOIN permissions p ON p.id = rp.permission_id
                WHERE rp.role_id = r.id
            ),
            '[]'::jsonb
        )
    FROM roles r
    JOIN modules m ON m.id = r.module_id
    WHERE m.code = module_code_param
    ORDER BY r.sort_order;
END;
$$;

-- ============================================
-- 6. ПОЛУЧИТЬ ВСЕ ПРАВА МОДУЛЯ (для UI)
-- ============================================
CREATE OR REPLACE FUNCTION get_module_permissions(module_code_param TEXT)
RETURNS TABLE (
    permission_id UUID,
    code TEXT,
    name_ru TEXT,
    name_en TEXT,
    name_hi TEXT,
    category TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id,
        p.code::TEXT,
        p.name_ru::TEXT,
        p.name_en::TEXT,
        p.name_hi::TEXT,
        p.category::TEXT
    FROM permissions p
    JOIN modules m ON m.id = p.module_id
    WHERE m.code = module_code_param
    ORDER BY p.sort_order;
END;
$$;

-- ============================================
-- 7. УПРАВЛЕНИЕ РОЛЯМИ ПОЛЬЗОВАТЕЛЯ (для админов)
-- ============================================
CREATE OR REPLACE FUNCTION assign_user_role(
    target_user_id UUID,
    target_role_id UUID,
    expires TIMESTAMPTZ DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Проверяем право на управление пользователями
    IF NOT user_has_permission('settings.users') THEN
        RAISE EXCEPTION 'Permission denied';
    END IF;

    INSERT INTO user_roles (user_id, role_id, granted_by, expires_at)
    VALUES (target_user_id, target_role_id, auth.uid(), expires)
    ON CONFLICT (user_id, role_id)
    DO UPDATE SET
        expires_at = expires,
        granted_by = auth.uid(),
        granted_at = NOW();

    RETURN true;
END;
$$;

CREATE OR REPLACE FUNCTION revoke_user_role(
    target_user_id UUID,
    target_role_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Проверяем право на управление пользователями
    IF NOT user_has_permission('settings.users') THEN
        RAISE EXCEPTION 'Permission denied';
    END IF;

    DELETE FROM user_roles
    WHERE user_id = target_user_id AND role_id = target_role_id;

    RETURN true;
END;
$$;

-- ============================================
-- 8. УПРАВЛЕНИЕ ЛОКАЦИЯМИ ПОЛЬЗОВАТЕЛЯ
-- ============================================
CREATE OR REPLACE FUNCTION assign_user_location(
    target_user_id UUID,
    target_location_id UUID,
    set_default BOOLEAN DEFAULT false
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Проверяем право на управление пользователями
    IF NOT user_has_permission('settings.users') THEN
        RAISE EXCEPTION 'Permission denied';
    END IF;

    -- Если это default локация, сбрасываем предыдущий default
    IF set_default THEN
        UPDATE user_locations
        SET is_default = false
        WHERE user_id = target_user_id AND is_default = true;
    END IF;

    INSERT INTO user_locations (user_id, location_id, is_default, granted_by)
    VALUES (target_user_id, target_location_id, set_default, auth.uid())
    ON CONFLICT (user_id, location_id)
    DO UPDATE SET
        is_default = set_default,
        granted_by = auth.uid(),
        granted_at = NOW();

    RETURN true;
END;
$$;

CREATE OR REPLACE FUNCTION revoke_user_location(
    target_user_id UUID,
    target_location_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Проверяем право на управление пользователями
    IF NOT user_has_permission('settings.users') THEN
        RAISE EXCEPTION 'Permission denied';
    END IF;

    DELETE FROM user_locations
    WHERE user_id = target_user_id AND location_id = target_location_id;

    RETURN true;
END;
$$;

-- ============================================
-- 9. УПРАВЛЕНИЕ ИСКЛЮЧЕНИЯМИ ПРАВ
-- ============================================
CREATE OR REPLACE FUNCTION set_user_permission_exception(
    target_user_id UUID,
    target_permission_id UUID,
    is_grant BOOLEAN,
    reason_text TEXT DEFAULT NULL,
    expires TIMESTAMPTZ DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Проверяем право на управление пользователями
    IF NOT user_has_permission('settings.users') THEN
        RAISE EXCEPTION 'Permission denied';
    END IF;

    INSERT INTO user_permissions (user_id, permission_id, is_granted, reason, granted_by, expires_at)
    VALUES (target_user_id, target_permission_id, is_grant, reason_text, auth.uid(), expires)
    ON CONFLICT (user_id, permission_id)
    DO UPDATE SET
        is_granted = is_grant,
        reason = reason_text,
        granted_by = auth.uid(),
        expires_at = expires;

    RETURN true;
END;
$$;

CREATE OR REPLACE FUNCTION remove_user_permission_exception(
    target_user_id UUID,
    target_permission_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Проверяем право на управление пользователями
    IF NOT user_has_permission('settings.users') THEN
        RAISE EXCEPTION 'Permission denied';
    END IF;

    DELETE FROM user_permissions
    WHERE user_id = target_user_id AND permission_id = target_permission_id;

    RETURN true;
END;
$$;

-- ============================================
-- 10. ПОЛУЧИТЬ ВСЕХ ПОЛЬЗОВАТЕЛЕЙ (для админов)
-- ============================================
CREATE OR REPLACE FUNCTION get_all_users()
RETURNS TABLE (
    team_member_id UUID,
    user_id UUID,
    first_name TEXT,
    last_name TEXT,
    spiritual_name TEXT,
    email TEXT,
    department_name_ru TEXT,
    department_name_en TEXT,
    department_color TEXT,
    is_superuser BOOLEAN,
    is_active BOOLEAN,
    roles JSONB,
    locations JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
BEGIN
    -- Проверяем право на управление пользователями
    IF NOT user_has_permission('settings.users') THEN
        RAISE EXCEPTION 'Permission denied';
    END IF;

    RETURN QUERY
    SELECT
        tm.id,
        tm.user_id,
        tm.first_name::TEXT,
        tm.last_name::TEXT,
        tm.spiritual_name::TEXT,
        (SELECT au.email FROM auth.users au WHERE au.id = tm.user_id)::TEXT,
        d.name_ru::TEXT,
        d.name_en::TEXT,
        d.color::TEXT,
        COALESCE(tm.is_superuser, false),
        COALESCE(tm.is_active, true),
        COALESCE(
            (
                SELECT jsonb_agg(
                    jsonb_build_object(
                        'id', r.id,
                        'code', r.code,
                        'name_ru', r.name_ru,
                        'name_en', r.name_en,
                        'color', r.color,
                        'module_code', m.code
                    )
                )
                FROM user_roles ur
                JOIN roles r ON r.id = ur.role_id
                JOIN modules m ON m.id = r.module_id
                WHERE ur.user_id = tm.user_id
                  AND (ur.expires_at IS NULL OR ur.expires_at > NOW())
            ),
            '[]'::jsonb
        ),
        COALESCE(
            (
                SELECT jsonb_agg(
                    jsonb_build_object(
                        'id', l.id,
                        'slug', l.slug,
                        'name_ru', l.name_ru,
                        'name_en', l.name_en,
                        'color', l.color,
                        'is_default', ul.is_default
                    )
                )
                FROM user_locations ul
                JOIN locations l ON l.id = ul.location_id
                WHERE ul.user_id = tm.user_id
            ),
            '[]'::jsonb
        )
    FROM team_members tm
    LEFT JOIN departments d ON d.id = tm.department_id
    ORDER BY tm.spiritual_name, tm.first_name;
END;
$$;

-- ============================================
-- 11. УСТАНОВИТЬ СУПЕРПОЛЬЗОВАТЕЛЯ
-- ============================================
CREATE OR REPLACE FUNCTION set_superuser(
    target_team_member_id UUID,
    is_super BOOLEAN
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Только суперпользователь может назначать других суперпользователей
    IF NOT is_superuser() THEN
        RAISE EXCEPTION 'Only superusers can modify superuser status';
    END IF;

    UPDATE team_members
    SET is_superuser = is_super
    WHERE id = target_team_member_id;

    RETURN true;
END;
$$;

-- ============================================
-- 12. СВЯЗАТЬ TEAM_MEMBER С AUTH USER
-- ============================================
CREATE OR REPLACE FUNCTION link_team_member_to_user(
    target_team_member_id UUID,
    target_auth_user_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Проверяем право на управление пользователями
    IF NOT user_has_permission('settings.users') THEN
        RAISE EXCEPTION 'Permission denied';
    END IF;

    UPDATE team_members
    SET user_id = target_auth_user_id
    WHERE id = target_team_member_id;

    RETURN true;
END;
$$;
