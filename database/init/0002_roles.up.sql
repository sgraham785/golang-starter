-- \c canary_health;

-- CREATE NOLOGIN PARENT ROLES
CREATE ROLE eli_administrator_role WITH NOLOGIN NOINHERIT;
CREATE ROLE eli_read_write_role WITH NOLOGIN NOINHERIT;
CREATE ROLE eli_read_only_role WITH NOLOGIN NOINHERIT;

-- ACCESS DB
REVOKE CONNECT ON DATABASE canary_health FROM PUBLIC;
GRANT CONNECT ON DATABASE canary_health TO eli_administrator_role;
GRANT CONNECT ON DATABASE canary_health TO eli_read_write_role;
GRANT CONNECT ON DATABASE canary_health TO eli_read_only_role;

-- ACCESS SCHEMA
REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA reporter TO eli_administrator_role;
GRANT USAGE ON SCHEMA reporter TO eli_read_write_role;
GRANT USAGE ON SCHEMA reporter TO eli_read_only_role;

-- SET ROLE DEFAULT PRIVILEGES
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;
ALTER DEFAULT PRIVILEGES IN SCHEMA reporter GRANT ALL ON TABLES TO eli_administrator_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA reporter GRANT SELECT, INSERT, UPDATE ON TABLES TO eli_read_write_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA reporter GRANT SELECT ON TABLES TO eli_read_only_role;

-- SET SEARCH_PATH
ALTER ROLE postgres SET search_path TO reporter;
ALTER ROLE eli_administrator_role SET search_path TO reporter;
ALTER ROLE eli_read_write_role SET search_path TO reporter;
ALTER ROLE eli_read_only_role SET search_path TO reporter;
