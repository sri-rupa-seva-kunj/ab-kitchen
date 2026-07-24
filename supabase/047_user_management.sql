-- ============================================
-- 047: Управление пользователями
-- ============================================

-- ============================================
-- 1. РАСШИРЕНИЕ TEAM_MEMBERS
-- ============================================
-- Связь с Supabase Auth
ALTER TABLE team_members ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;

-- Флаг суперпользователя (видит все локации)
ALTER TABLE team_members ADD COLUMN IF NOT EXISTS is_superuser BOOLEAN DEFAULT false;

-- Активность аккаунта
ALTER TABLE team_members ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

-- Индекс для быстрого поиска по user_id
CREATE INDEX IF NOT EXISTS idx_team_members_user_id ON team_members(user_id);

-- ============================================
-- 2. РОЛИ ПОЛЬЗОВАТЕЛЯ
-- ============================================
CREATE TABLE IF NOT EXISTS user_roles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    granted_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    granted_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, role_id)
);

CREATE INDEX IF NOT EXISTS idx_user_roles_user ON user_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_role ON user_roles(role_id);

-- ============================================
-- 3. ДОСТУПНЫЕ ЛОКАЦИИ ПОЛЬЗОВАТЕЛЯ
-- ============================================
CREATE TABLE IF NOT EXISTS user_locations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    location_id UUID NOT NULL REFERENCES locations(id) ON DELETE CASCADE,
    is_default BOOLEAN DEFAULT false,
    granted_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    granted_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, location_id)
);

CREATE INDEX IF NOT EXISTS idx_user_locations_user ON user_locations(user_id);
CREATE INDEX IF NOT EXISTS idx_user_locations_location ON user_locations(location_id);

-- ============================================
-- 4. ИСКЛЮЧЕНИЯ ПРАВ (+/-)
-- ============================================
CREATE TABLE IF NOT EXISTS user_permissions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    is_granted BOOLEAN NOT NULL, -- true = добавить право, false = отнять
    reason TEXT,
    granted_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, permission_id)
);

CREATE INDEX IF NOT EXISTS idx_user_permissions_user ON user_permissions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_permissions_permission ON user_permissions(permission_id);

-- ============================================
-- 5. ПРИГЛАШЕНИЯ ПОЛЬЗОВАТЕЛЕЙ
-- ============================================
CREATE TABLE IF NOT EXISTS user_invitations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    team_member_id UUID REFERENCES team_members(id) ON DELETE CASCADE,
    invited_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    token VARCHAR(255) UNIQUE NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    accepted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_user_invitations_email ON user_invitations(email);
CREATE INDEX IF NOT EXISTS idx_user_invitations_token ON user_invitations(token);

-- ============================================
-- RLS POLICIES
-- ============================================
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_invitations ENABLE ROW LEVEL SECURITY;

-- User roles: пользователь видит свои роли
DROP POLICY IF EXISTS "Users can read own roles" ON user_roles;
CREATE POLICY "Users can read own roles" ON user_roles
    FOR SELECT TO authenticated
    USING (user_id = auth.uid());

-- User locations: пользователь видит свои локации
DROP POLICY IF EXISTS "Users can read own locations" ON user_locations;
CREATE POLICY "Users can read own locations" ON user_locations
    FOR SELECT TO authenticated
    USING (user_id = auth.uid());

-- User permissions: пользователь видит свои исключения
DROP POLICY IF EXISTS "Users can read own permissions" ON user_permissions;
CREATE POLICY "Users can read own permissions" ON user_permissions
    FOR SELECT TO authenticated
    USING (user_id = auth.uid());

-- Invitations: только создатель и приглашённый
DROP POLICY IF EXISTS "Users can read invitations" ON user_invitations;
CREATE POLICY "Users can read invitations" ON user_invitations
    FOR SELECT TO authenticated
    USING (invited_by = auth.uid());

-- Временно: anon может читать (для разработки)
DROP POLICY IF EXISTS "Public read user_roles" ON user_roles;
CREATE POLICY "Public read user_roles" ON user_roles FOR SELECT TO anon USING (true);

DROP POLICY IF EXISTS "Public read user_locations" ON user_locations;
CREATE POLICY "Public read user_locations" ON user_locations FOR SELECT TO anon USING (true);

DROP POLICY IF EXISTS "Public read user_permissions" ON user_permissions;
CREATE POLICY "Public read user_permissions" ON user_permissions FOR SELECT TO anon USING (true);

-- ============================================
-- ПЕРЕВОДЫ
-- ============================================
INSERT INTO translations (key, ru, en, hi, page) VALUES
    ('nav_users', 'Пользователи', 'Users', 'उपयोगकर्ता', 'navigation'),
    ('logout', 'Выйти', 'Logout', 'लॉग आउट', 'auth'),
    ('settings_users', 'Пользователи', 'Users', 'उपयोगकर्ता', 'settings'),
    ('tab_roles', 'Роли', 'Roles', 'भूमिकाएँ', 'users'),
    ('tab_locations', 'Локации', 'Locations', 'स्थान', 'users'),
    ('tab_exceptions', 'Исключения', 'Exceptions', 'अपवाद', 'users'),
    ('no_exceptions', 'Нет исключений', 'No exceptions', 'कोई अपवाद नहीं', 'users'),
    ('add_exception', 'Добавить исключение', 'Add exception', 'अपवाद जोड़ें', 'users'),
    ('select_permission', 'Выберите право', 'Select permission', 'अनुमति चुनें', 'users'),
    ('select_team_member', 'Выберите сотрудника', 'Select team member', 'टीम सदस्य चुनें', 'users'),
    ('team_member', 'Сотрудник', 'Team member', 'टीम सदस्य', 'users'),
    ('invite_user_title', 'Пригласить пользователя', 'Invite user', 'उपयोगकर्ता आमंत्रित करें', 'users'),
    ('invite_hint', 'Выберите сотрудника и введите email для отправки приглашения', 'Select team member and enter email to send invitation', 'टीम सदस्य चुनें और आमंत्रण भेजने के लिए ईमेल दर्ज करें', 'users'),
    ('send_invite', 'Отправить приглашение', 'Send invitation', 'आमंत्रण भेजें', 'users'),
    ('filter_linked', 'Привязанные', 'Linked', 'लिंक किया गया', 'users'),
    ('filter_not_linked', 'Не привязанные', 'Not linked', 'लिंक नहीं किया गया', 'users'),
    ('users_count_suffix', 'пользователей', 'users', 'उपयोगकर्ता', 'users'),
    ('no_users', 'Нет пользователей', 'No users', 'कोई उपयोगकर्ता नहीं', 'users'),
    ('add_exception_title', 'Добавить исключение', 'Add exception', 'अपवाद जोड़ें', 'users'),
    ('exception_type', 'Тип', 'Type', 'प्रकार', 'users'),
    ('reason', 'Причина', 'Reason', 'कारण', 'users'),
    ('permission', 'Право', 'Permission', 'अनुमति', 'users')
ON CONFLICT (key) DO UPDATE SET
    ru = EXCLUDED.ru,
    en = EXCLUDED.en,
    hi = EXCLUDED.hi,
    page = EXCLUDED.page;

INSERT INTO translations (key, ru, en, hi, page) VALUES
    ('users_title', 'Пользователи', 'Users', 'उपयोगकर्ता', 'users'),
    ('add_user', 'Добавить пользователя', 'Add User', 'उपयोगकर्ता जोड़ें', 'users'),
    ('invite_user', 'Пригласить', 'Invite', 'आमंत्रित करें', 'users'),
    ('user_roles', 'Роли пользователя', 'User Roles', 'उपयोगकर्ता भूमिकाएँ', 'users'),
    ('user_locations', 'Доступные локации', 'Available Locations', 'उपलब्ध स्थान', 'users'),
    ('user_permissions', 'Исключения прав', 'Permission Exceptions', 'अनुमति अपवाद', 'users'),
    ('superuser', 'Суперпользователь', 'Superuser', 'सुपरयूज़र', 'users'),
    ('superuser_hint', 'Видит все локации', 'Can see all locations', 'सभी स्थान देख सकते हैं', 'users'),
    ('active', 'Активен', 'Active', 'सक्रिय', 'users'),
    ('inactive', 'Неактивен', 'Inactive', 'निष्क्रिय', 'users'),
    ('grant_permission', 'Добавить право', 'Grant Permission', 'अनुमति दें', 'users'),
    ('revoke_permission', 'Отнять право', 'Revoke Permission', 'अनुमति रद्द करें', 'users'),
    ('reset_password', 'Сбросить пароль', 'Reset Password', 'पासवर्ड रीसेट करें', 'users'),
    ('password_reset_sent', 'Ссылка для сброса отправлена', 'Reset link sent', 'रीसेट लिंक भेजा गया', 'users'),
    ('invitation_sent', 'Приглашение отправлено', 'Invitation sent', 'आमंत्रण भेजा गया', 'users'),
    ('no_roles', 'Нет ролей', 'No roles', 'कोई भूमिका नहीं', 'users'),
    ('all_locations', 'Все локации', 'All locations', 'सभी स्थान', 'users'),
    ('default_location', 'По умолчанию', 'Default', 'डिफ़ॉल्ट', 'users'),
    ('expires_at', 'Истекает', 'Expires', 'समाप्ति', 'users'),
    ('never', 'Бессрочно', 'Never', 'कभी नहीं', 'users'),
    ('not_linked', 'Не привязан', 'Not linked', 'लिंक नहीं है', 'users')
ON CONFLICT (key) DO UPDATE SET
    ru = EXCLUDED.ru,
    en = EXCLUDED.en,
    hi = EXCLUDED.hi,
    page = EXCLUDED.page;
