#!/bin/sh
set -e
mkdir -p /run/mysqld /var/lib/mysql && chown -R mysql:mysql /run/mysqld /var/lib/mysql
[ -d /var/lib/mysql/mysql ] || mariadb-install-db --user=mysql --datadir=/var/lib/mysql >/dev/null

mysqld_safe --user=mysql >/dev/null 2>&1 &
for i in $(seq 1 60); do mariadb-admin --silent ping 2>/dev/null && break; sleep 1; done

mariadb -uroot <<'SQL'
CREATE DATABASE IF NOT EXISTS disn1imh_v13_ma CHARACTER SET utf8mb4;
CREATE USER IF NOT EXISTS 'root'@'127.0.0.1' IDENTIFIED BY 'root';
ALTER USER 'root'@'127.0.0.1' IDENTIFIED BY 'root';
GRANT ALL ON *.* TO 'root'@'127.0.0.1' WITH GRANT OPTION;
FLUSH PRIVILEGES;
SQL

# schéma, puis données d'exemple (--force : continue même si une ligne échoue)
for f in create_tables insert_null_personnel insert_patient insert_infirmier insert_examen insert_stock insert_prelevement insert_prelevement_examen; do
  [ -f "/opt/db/$f.sql" ] && mariadb -uroot --force disn1imh_v13_ma < "/opt/db/$f.sql" || true
done

exec apache2-foreground
