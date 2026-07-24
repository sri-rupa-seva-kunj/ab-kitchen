-- 009 использует ON CONFLICT (name_en), поэтому ограничение должно существовать заранее.
ALTER TABLE products
    ADD CONSTRAINT products_name_en_unique UNIQUE (name_en);
