-- ============================================
-- RLS ПОЛИТИКИ ДЛЯ СПРАВОЧНИКОВ
-- ============================================

-- Категории продуктов
ALTER TABLE product_categories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read product_categories" ON product_categories;
DROP POLICY IF EXISTS "Public insert product_categories" ON product_categories;
DROP POLICY IF EXISTS "Public update product_categories" ON product_categories;
DROP POLICY IF EXISTS "Public delete product_categories" ON product_categories;

CREATE POLICY "Public read product_categories" ON product_categories FOR SELECT TO anon USING (true);
CREATE POLICY "Public insert product_categories" ON product_categories FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "Public update product_categories" ON product_categories FOR UPDATE TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Public delete product_categories" ON product_categories FOR DELETE TO anon USING (true);

-- Категории блюд
ALTER TABLE recipe_categories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read recipe_categories" ON recipe_categories;
DROP POLICY IF EXISTS "Public insert recipe_categories" ON recipe_categories;
DROP POLICY IF EXISTS "Public update recipe_categories" ON recipe_categories;
DROP POLICY IF EXISTS "Public delete recipe_categories" ON recipe_categories;

CREATE POLICY "Public read recipe_categories" ON recipe_categories FOR SELECT TO anon USING (true);
CREATE POLICY "Public insert recipe_categories" ON recipe_categories FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "Public update recipe_categories" ON recipe_categories FOR UPDATE TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Public delete recipe_categories" ON recipe_categories FOR DELETE TO anon USING (true);
