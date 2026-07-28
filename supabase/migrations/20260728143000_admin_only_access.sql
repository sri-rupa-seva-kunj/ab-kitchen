-- AB Kitchen — закрытое приложение с одним уровнем доступа.
-- Каждый активированный пользователь является администратором с полными правами.

UPDATE vaishnavas
   SET is_superuser = true,
       updated_at = NOW()
 WHERE user_id IS NOT NULL
   AND is_active = true
   AND approval_status = 'approved'
   AND is_deleted = false;

UPDATE user_roles SET is_active = false WHERE COALESCE(is_active, true);

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

GRANT EXECUTE ON FUNCTION public.abk_is_superuser(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.has_permission(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.link_auth_user_to_vaishnava() TO authenticated;
