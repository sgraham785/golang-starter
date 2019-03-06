-- \c canary_health;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" SCHEMA reporter;
CREATE EXTENSION IF NOT EXISTS "citext" SCHEMA reporter;
CREATE EXTENSION IF NOT EXISTS "pgcrypto" SCHEMA reporter;