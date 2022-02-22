#!/bin/sh
set -e

sed -i 's/root \/home\/USER/root \/var/g' /etc/nginx/http.d/grav.conf

sed -i "s/localhost/$SERVER_NAME/g" /etc/nginx/http.d/grav.conf

exec "$0"
