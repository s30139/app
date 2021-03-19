#!/bin/bash
# psql "sslmode=require" -h 127.0.0.1 -p 5441 -Umojo -d users
set -e
sqluser="mojo"
sqlpassword="mojo"
dbname="users"
user_mail="mojo@s30139.ru"
#
PGPASSWORD="$POSTGRES_PASSWORD" psql -v ON_ERROR_STOP=1 --username "$POSTGRESQL_USERNAME" --dbname "postgres" <<-EOSQL
    CREATE USER docker;
    CREATE DATABASE docker;
    GRANT ALL PRIVILEGES ON DATABASE docker TO docker;
    CREATE DATABASE ${dbname};
    CREATE USER ${sqluser} WITH PASSWORD '${sqlpassword}' SUPERUSER;
    GRANT ALL PRIVILEGES ON DATABASE "${dbname}" to ${sqluser};
EOSQL
PGPASSWORD="${sqlpassword}" psql -v ON_ERROR_STOP=1 --username "${sqluser}" --dbname "${dbname}" <<-EOSQL
    CREATE EXTENSION pgcrypto;
    CREATE TABLE users (
        id        BIGSERIAL               PRIMARY KEY,
        mail      character varying(250)  NOT NULL,
        password  character varying(250)  NOT NULL,
        balans    numeric(19,2)           DEFAULT 0
    );
    INSERT INTO users (             mail,   balans, password )
    VALUES            (   '${user_mail}',     1000,      'a' );
    UPDATE users SET password = crypt( '123' , gen_salt('md5') )  WHERE mail = '${user_mail}';

    CREATE TABLE goods (
        id          BIGSERIAL                    PRIMARY KEY,
        name        character varying(1024)      NOT NULL,
        price       numeric(19,2)                CONSTRAINT positive_price CHECK (price > 0),
        desc1       character varying(1024)      DEFAULT ''
    );
    INSERT INTO goods (       name,     price,           desc1  )
    VALUES            (     'cars',     '100',     'cars desc'  ),
                      (   'fruits',  '500.00',   'fruits desc'  ),
                      ( 'clothing',  '900.01',   'fruits desc'  )
    ;
    CREATE TABLE orders (
        id          BIGSERIAL                   ,
        user_id     BIGSERIAL                   ,
        goods_id    BIGSERIAL                   ,
        count       INTEGER                     CHECK (count > 0),
        visible     INT                         DEFAULT 1        ,
        FOREIGN KEY (user_id)  REFERENCES users (id),
        FOREIGN KEY (goods_id) REFERENCES goods (id)
    );

    CREATE TABLE sessions (
        id         character(32)           not null,
        mail       character varying(250),
        userid     character varying(250),
        data       jsonb,
        expire     bigint
    );
EOSQL

#cat /var/lib/postgresql/data/postgresql.conf

