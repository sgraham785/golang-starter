-- \c canary_health;

CREATE TABLE schema_migrations (
  version bigint not null primary key, 
  dirty boolean not null
);