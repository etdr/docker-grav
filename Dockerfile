FROM php:alpine
LABEL maintainer="Andy Miller <rhuk@getgrav.org> (@rhukster)"
LABEL modifier="Eli T. Drumm <eli@eli.td>"

# Enable Apache Rewrite + Expires Module
# RUN a2enmod rewrite expires && \
# sed -i 's/ServerTokens OS/ServerTokens ProductOnly/g' \
# /etc/apache2/conf-available/security.conf

# Install dependencies
RUN apk update && apk add \
    nginx \
    php8-fpm \
    unzip \
    #libfreetype6-dev \
    freetype-dev \
    #libjpeg62-turbo-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    #libyaml-dev \
    yaml-dev php8-pecl-yaml \
    php8-pecl-apcu \
    #libzip4 \
    libzip-dev \
    #zlib1g-dev \
    zlib-dev \
    #libicu-dev \
    icu-dev \
    g++ \
    git \
    #cron \
    cronie \
    micro \
    autoconf make \
    && docker-php-ext-install opcache \
    #php8-opcache \
    && docker-php-ext-configure intl \
    #php8-intl \
    && docker-php-ext-install intl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    #php8-gd \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install zip \
    #php8-zip \
    && rm -rf /var/lib/apt/lists/*

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=2'; \
    echo 'opcache.fast_shutdown=1'; \
    echo 'opcache.enable_cli=1'; \
    echo 'upload_max_filesize=128M'; \
    echo 'post_max_size=128M'; \
    echo 'expose_php=off'; \
    } > /usr/local/etc/php/conf.d/php-recommended.ini

RUN pecl install apcu \
    && pecl install yaml \
    && docker-php-ext-enable apcu yaml




# Set user to www-data
RUN chown -R www-data:www-data /var/www
#RUN chown -R www-data:www-data /var/www/html
USER www-data

# Define Grav specific version of Grav or use latest stable
ARG GRAV_VERSION=latest

# Install grav
WORKDIR /var/www
RUN curl -o grav-admin.zip -SL https://getgrav.org/download/core/grav-admin/${GRAV_VERSION} && \
    unzip grav-admin.zip && \
    mkdir grav && \
    mv /var/www/grav-admin/* /var/www/grav && \
    rm grav-admin.zip

# Create cron job for Grav maintenance scripts
RUN (crontab -l; echo "* * * * * cd /var/www/html;/usr/local/bin/php bin/grav scheduler 1>> /dev/null 2>&1") | crontab -

# Return to root user
USER root

RUN rm /etc/nginx/http.d/default.conf
RUN cp /var/www/grav/webserver-configs/nginx.conf /etc/nginx/http.d/grav.conf


RUN sed -e 's/\;extension=mbstring/extension=mbstring/g' \
        -i /etc/php8/php.ini


# Copy init scripts
COPY docker-entrypoint.sh /entrypoint.sh

# provide container inside image for data persistence
VOLUME ["/var/www/grav"]

ENTRYPOINT ["/entrypoint.sh"]
# CMD ["apache2-foreground"]
CMD ["sh", "-c", "crond && php-fpm8 && nginx -g 'daemon off;'"]
