-- CREATE LOGIN USERS
CREATE USER eli_app_administrator LOGIN INHERIT IN ROLE eli_administrator_role ENCRYPTED PASSWORD 'postgres';
CREATE USER eli_app_user LOGIN INHERIT IN ROLE eli_read_write_role ENCRYPTED PASSWORD 'postgres';
CREATE USER eli_read_only_user LOGIN INHERIT IN ROLE eli_read_only_role ENCRYPTED PASSWORD 'postgres';