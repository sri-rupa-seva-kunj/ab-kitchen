-- AB Kitchen: приглашённый пользователь получает минимальную кухонную роль
-- после связывания Auth с профилем. Администратор затем может изменить роль.

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
    observer_role_id UUID;
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
               updated_at = NOW()
         WHERE id = person_id;
    END IF;

    IF NOT public.abk_is_superuser(auth_id)
       AND NOT EXISTS (
           SELECT 1
             FROM user_roles
            WHERE user_id = auth_id
              AND COALESCE(is_active, true)
       )
    THEN
        SELECT r.id
          INTO observer_role_id
          FROM roles r
          JOIN modules m ON m.id = r.module_id
         WHERE m.code = 'kitchen'
           AND r.code = 'observer'
         LIMIT 1;

        IF observer_role_id IS NOT NULL THEN
            INSERT INTO user_roles (user_id, role_id, is_active)
            VALUES (auth_id, observer_role_id, true)
            ON CONFLICT (user_id, role_id)
            DO UPDATE SET is_active = true, expires_at = NULL;
        END IF;
    END IF;

    RETURN QUERY SELECT true, person_id, NULL::TEXT;
END;
$$;

GRANT EXECUTE ON FUNCTION public.link_auth_user_to_vaishnava() TO authenticated;
