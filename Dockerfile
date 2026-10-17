FROM php:8.2-apache

RUN apt-get update && apt-get install -y --no-install-recommends mariadb-server \
 && docker-php-ext-install pdo_mysql \
 && rm -rf /var/lib/apt/lists/*

# MariaDB sous Linux est sensible à la casse ; le code mélange DISN1IMH_V13_x et disn1imh_v13_x
RUN printf '[mysqld]\nlower_case_table_names=1\nbind-address=127.0.0.1\nskip-name-resolve\ninnodb_buffer_pool_size=32M\nperformance_schema=OFF\nmax_connections=30\n' > /etc/mysql/mariadb.conf.d/99-labanal.cnf

COPY www /var/www/www
COPY database /opt/db

# Une seule base et une seule connexion (127.0.0.1, root/root) pour tout le code, sans toucher au dépôt
RUN find /var/www/www -name '*.php' -exec sed -i -E \
      -e 's/host=localhost:3306/host=127.0.0.1;port=3306/g' \
      -e 's/host=localhost;/host=127.0.0.1;/g' \
      -e 's/dbname=DISN1IMH_V1"/dbname=disn1imh_v13_ma"/g' \
      -e 's/"root", *""/"root","root"/g' {} + \
 && chown -R www-data:www-data /var/www/www

ENV PORT=10000
RUN printf 'Listen ${PORT}\n' > /etc/apache2/ports.conf \
 && printf '<VirtualHost *:${PORT}>\n  DocumentRoot /var/www/www/external\n  Alias /internal /var/www/www/internal\n  Alias /assets /var/www/www/assets\n  <Directory /var/www/www>\n    AllowOverride None\n    Require all granted\n  </Directory>\n</VirtualHost>\n' > /etc/apache2/sites-available/000-default.conf

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
CMD ["docker-entrypoint.sh"]
