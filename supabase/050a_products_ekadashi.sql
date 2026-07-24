-- Поле требуется триггерам автоматического расчёта из 108.
ALTER TABLE products ADD COLUMN IF NOT EXISTS ekadashi BOOLEAN DEFAULT false;
