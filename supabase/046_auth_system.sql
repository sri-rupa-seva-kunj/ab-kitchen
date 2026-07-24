-- ============================================
-- 046: Система авторизации - Модули и права
-- ============================================

-- ============================================
-- 1. МОДУЛИ СИСТЕМЫ
-- ============================================
CREATE TABLE IF NOT EXISTS modules (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name_ru VARCHAR(255) NOT NULL,
    name_en VARCHAR(255) NOT NULL,
    name_hi VARCHAR(255),
    is_active BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Начальные модули
INSERT INTO modules (code, name_ru, name_en, name_hi, sort_order) VALUES
    ('kitchen', 'Кухня', 'Kitchen', 'रसोई', 1),
    ('guesthouse', 'Гостевой дом', 'Guest House', 'अतिथि गृह', 2)
ON CONFLICT (code) DO NOTHING;

-- ============================================
-- 2. АТОМАРНЫЕ ПРАВА
-- ============================================
CREATE TABLE IF NOT EXISTS permissions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    module_id UUID NOT NULL REFERENCES modules(id) ON DELETE CASCADE,
    code VARCHAR(100) NOT NULL,
    name_ru VARCHAR(255) NOT NULL,
    name_en VARCHAR(255) NOT NULL,
    name_hi VARCHAR(255),
    category VARCHAR(50) NOT NULL,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(module_id, code)
);

CREATE INDEX IF NOT EXISTS idx_permissions_module ON permissions(module_id);
CREATE INDEX IF NOT EXISTS idx_permissions_code ON permissions(code);
CREATE INDEX IF NOT EXISTS idx_permissions_category ON permissions(category);

-- ============================================
-- 3. РОЛИ ВНУТРИ МОДУЛЯ
-- ============================================
CREATE TABLE IF NOT EXISTS roles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    module_id UUID NOT NULL REFERENCES modules(id) ON DELETE CASCADE,
    code VARCHAR(50) NOT NULL,
    name_ru VARCHAR(255) NOT NULL,
    name_en VARCHAR(255) NOT NULL,
    name_hi VARCHAR(255),
    description_ru TEXT,
    description_en TEXT,
    color VARCHAR(7) DEFAULT '#6366f1',
    is_system BOOLEAN DEFAULT false,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(module_id, code)
);

CREATE INDEX IF NOT EXISTS idx_roles_module ON roles(module_id);

-- ============================================
-- 4. ПРАВА РОЛИ (many-to-many)
-- ============================================
CREATE TABLE IF NOT EXISTS role_permissions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(role_id, permission_id)
);

CREATE INDEX IF NOT EXISTS idx_role_permissions_role ON role_permissions(role_id);
CREATE INDEX IF NOT EXISTS idx_role_permissions_permission ON role_permissions(permission_id);

-- ============================================
-- RLS POLICIES
-- ============================================
ALTER TABLE modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE role_permissions ENABLE ROW LEVEL SECURITY;

-- Modules: чтение для всех авторизованных
DROP POLICY IF EXISTS "Authenticated users can read modules" ON modules;
CREATE POLICY "Authenticated users can read modules" ON modules
    FOR SELECT TO authenticated USING (true);

-- Permissions: чтение для всех авторизованных
DROP POLICY IF EXISTS "Authenticated users can read permissions" ON permissions;
CREATE POLICY "Authenticated users can read permissions" ON permissions
    FOR SELECT TO authenticated USING (true);

-- Roles: чтение для всех авторизованных
DROP POLICY IF EXISTS "Authenticated users can read roles" ON roles;
CREATE POLICY "Authenticated users can read roles" ON roles
    FOR SELECT TO authenticated USING (true);

-- Role permissions: чтение для всех авторизованных
DROP POLICY IF EXISTS "Authenticated users can read role_permissions" ON role_permissions;
CREATE POLICY "Authenticated users can read role_permissions" ON role_permissions
    FOR SELECT TO authenticated USING (true);

-- Временно: anon может читать (для разработки)
DROP POLICY IF EXISTS "Public read modules" ON modules;
CREATE POLICY "Public read modules" ON modules FOR SELECT TO anon USING (true);

DROP POLICY IF EXISTS "Public read permissions" ON permissions;
CREATE POLICY "Public read permissions" ON permissions FOR SELECT TO anon USING (true);

DROP POLICY IF EXISTS "Public read roles" ON roles;
CREATE POLICY "Public read roles" ON roles FOR SELECT TO anon USING (true);

DROP POLICY IF EXISTS "Public read role_permissions" ON role_permissions;
CREATE POLICY "Public read role_permissions" ON role_permissions FOR SELECT TO anon USING (true);

-- ============================================
-- ПЕРЕВОДЫ
-- ============================================
INSERT INTO translations (key, ru, en, hi, page) VALUES
    ('modules', 'Модули', 'Modules', 'मॉड्यूल', 'auth'),
    ('permissions', 'Права', 'Permissions', 'अनुमतियाँ', 'auth'),
    ('roles', 'Роли', 'Roles', 'भूमिकाएँ', 'auth'),
    ('role_admin', 'Администратор', 'Administrator', 'व्यवस्थापक', 'auth'),
    ('role_head_cook', 'Старший повар', 'Head Cook', 'मुख्य रसोइया', 'auth'),
    ('role_cook', 'Повар', 'Cook', 'रसोइया', 'auth'),
    ('role_stock_manager', 'Завскладом', 'Stock Manager', 'स्टॉक प्रबंधक', 'auth'),
    ('role_buyer', 'Закупщик', 'Buyer', 'खरीदार', 'auth'),
    ('role_observer', 'Наблюдатель', 'Observer', 'पर्यवेक्षक', 'auth')
ON CONFLICT (key) DO UPDATE SET
    ru = EXCLUDED.ru,
    en = EXCLUDED.en,
    hi = EXCLUDED.hi,
    page = EXCLUDED.page;
