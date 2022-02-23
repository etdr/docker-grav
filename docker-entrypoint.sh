#!/bin/sh
set -e

sed -e 's/root \/home\/USER/root \/var/g' \
    -e "s/localhost/$SERVER_NAME/g" \
    -e 's/\/www\/html/\/www\/grav/g' \
    -e 's/\#listen 80/listen 10880/g' \
    -e 's/php\/php7.2-fpm.sock/php8-fpm.sock/g' \
    -i /etc/nginx/http.d/grav.conf

sed -e 's/127.0.0.1:9000/\/var\/run\/php8-fpm.sock/g' \
    -e 's/;listen.owner = nobody/listen.owner = www-data/g' \
    -e 's/;listen.group = nobody/listen.group = www-data/g' \
    -i /etc/php8/php-fpm.d/www.conf

exec "$@"
