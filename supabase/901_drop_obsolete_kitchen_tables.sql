-- Удаляем старые версии таблиц, которые больше не используются текущим интерфейсом.
DROP TABLE IF EXISTS user_invitations CASCADE;
DROP TABLE IF EXISTS team_member_stays CASCADE;
DROP TABLE IF EXISTS team_presence CASCADE;
DROP TABLE IF EXISTS team_members CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;
DROP TABLE IF EXISTS menu_items CASCADE;
DROP TABLE IF EXISTS menu_days CASCADE;
DROP TABLE IF EXISTS stock_request_items CASCADE;
DROP TABLE IF EXISTS stock_requests CASCADE;
DROP TABLE IF EXISTS stock_transactions CASCADE;
DROP TABLE IF EXISTS stock_issue_items CASCADE;
DROP TABLE IF EXISTS stock_issues CASCADE;
DROP TABLE IF EXISTS price_history CASCADE;
