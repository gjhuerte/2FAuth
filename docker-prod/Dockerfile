# 2FAuth — production image
#
# Same layout as the nyxbin docker-prod setup (Ubuntu + nginx + PHP-FPM run
# by supervisord in one container), hardened for production:
#
#   - Ubuntu 26.04 LTS with PHP 8.5 from Ubuntu's own signed repositories
#     (no third-party PPA, no Composer binary in the repo)
#   - Application code, Composer vendor and built assets are baked into the
#     image (immutable deploys); nothing is bind-mounted from the host
#   - Front-end assets are built with Vite in a throwaway Node stage
#     (the @2fauth/* components are vendored in resources/js/packages)
#   - Build tools (Node, Composer, git) exist only in the build stages
#   - Every process runs as www-data; nginx listens on 8080; code is
#     root-owned and read-only to PHP
#
# Build from the repository root:
#   docker compose -f docker-prod/docker-compose.yml build

ARG UBUNTU_VERSION=26.04
ARG PHP_VERSION=8.5
ARG NODE_VERSION=22

# ---------------------------------------------------------------------------
# base: runtime packages shared by the build and final stages
# ---------------------------------------------------------------------------
FROM ubuntu:${UBUNTU_VERSION} AS base

ARG PHP_VERSION
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    PHP_VERSION=${PHP_VERSION}

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        tzdata \
        tini \
        nginx \
        supervisor \
        php${PHP_VERSION}-fpm \
        php${PHP_VERSION}-cli \
        php${PHP_VERSION}-bcmath \
        php${PHP_VERSION}-curl \
        php${PHP_VERSION}-gd \
        php${PHP_VERSION}-intl \
        php${PHP_VERSION}-mbstring \
        php${PHP_VERSION}-mysql \
        php${PHP_VERSION}-pgsql \
        php${PHP_VERSION}-sqlite3 \
        php${PHP_VERSION}-redis \
        php${PHP_VERSION}-xml \
        php${PHP_VERSION}-zip; \
    # Drop distro defaults we replace or do not use.
    rm -f /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default; \
    rm -f /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf; \
    # The Ubuntu image ships a "ubuntu" user we do not need.
    userdel --remove ubuntu 2>/dev/null || true; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/* /var/log/apt /var/log/dpkg.log

# ---------------------------------------------------------------------------
# assets: Vite build (Tailwind + Vue)
# ---------------------------------------------------------------------------
FROM node:${NODE_VERSION}-alpine AS assets

ENV npm_config_update_notifier=false \
    npm_config_fund=false \
    npm_config_audit=false

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY vite.config.js vite.version.js tsconfig.json ./
# vite.version.js reads the app version from config/2fauth.php
COPY config/2fauth.php ./config/2fauth.php
COPY resources ./resources
RUN npm run build

# ---------------------------------------------------------------------------
# build: Composer dependencies
# ---------------------------------------------------------------------------
FROM base AS build

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends composer git unzip; \
    rm -rf /var/lib/apt/lists/*

ENV COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_NO_INTERACTION=1 \
    COMPOSER_HOME=/tmp/composer

WORKDIR /app

# Dependencies first so they are cached between code changes.
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist --no-progress

COPY . .
# Freshly built assets replace whatever public/build the repository holds.
RUN rm -rf public/build
COPY --from=assets /app/public/build ./public/build

RUN set -eux; \
    test -f public/build/manifest.json; \
    # Also runs `artisan package:discover` (composer.json post-autoload-dump).
    composer dump-autoload --optimize --classmap-authoritative --no-dev; \
    # Keep only what the runtime needs; secrets never go into the image.
    rm -rf .env .env.* node_modules tests docs docker docker-dev docker-prod Dockerfile \
        .dockerignore phpunit*.xml phpstan.neon Procfile app.json \
        public/hot storage/logs/* storage/oauth-*.key bootstrap/cache/*.php \
        database/database.sqlite; \
    ln -sfn ../storage/app/public public/storage

# ---------------------------------------------------------------------------
# runtime
# ---------------------------------------------------------------------------
FROM base AS runtime

ARG PHP_VERSION
ENV APP_ENV=production \
    APP_DEBUG=false \
    LOG_CHANNEL=stack \
    LOG_STACK=daily,stderr \
    WEBAUTHN_NAME=2FAuth \
    QUEUE_CONNECTION=sync

COPY --chmod=0644 docker-prod/etc/nginx/nginx.conf /etc/nginx/nginx.conf
COPY --chmod=0644 docker-prod/etc/nginx/conf.d/www.conf /etc/nginx/conf.d/www.conf
COPY --chmod=0644 docker-prod/etc/php-fpm.d/www.conf /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf
COPY --chmod=0644 docker-prod/php/php.ini /etc/php/${PHP_VERSION}/fpm/conf.d/99-2fauth.ini
COPY --chmod=0644 docker-prod/php/php.ini /etc/php/${PHP_VERSION}/cli/conf.d/99-2fauth.ini
COPY --chmod=0644 docker-prod/supervisord.conf /etc/supervisor/supervisord.conf
COPY --chmod=0755 docker-prod/entrypoint.sh /usr/local/bin/2fauth-entrypoint

# Application code: owned by root, so a compromised PHP process cannot change it.
COPY --from=build /app /var/www/html

RUN set -eux; \
    # Config must be readable by www-data whatever the host file modes are.
    chmod 0644 /etc/nginx/nginx.conf /etc/nginx/conf.d/www.conf /etc/supervisor/supervisord.conf \
        /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf /etc/php/${PHP_VERSION}/fpm/conf.d/99-2fauth.ini \
        /etc/php/${PHP_VERSION}/cli/conf.d/99-2fauth.ini; \
    # Run PHP-FPM unprivileged: pid and logs go to /tmp and stderr.
    sed -ri \
        -e 's#^;?\s*pid\s*=.*#pid = /tmp/php-fpm.pid#' \
        -e 's#^;?\s*error_log\s*=.*#error_log = /proc/self/fd/2#' \
        /etc/php/${PHP_VERSION}/fpm/php-fpm.conf; \
    ln -s /usr/sbin/php-fpm${PHP_VERSION} /usr/local/sbin/php-fpm; \
    cd /var/www/html; \
    # Code readable (not writable) by www-data regardless of host file modes.
    chmod -R a+rX,go-w /var/www/html; \
    # storage/ is the persistent volume: app data, icons, Passport keys and
    # (with SQLite) the database file all live under it.
    mkdir -p storage/app/public/icons storage/app/imagesLink storage/app/temp \
        storage/app/logos storage/app/iconPacks storage/database \
        storage/framework/cache/data storage/framework/sessions \
        storage/framework/views storage/logs bootstrap/cache; \
    chown -R www-data:www-data storage bootstrap/cache; \
    chmod -R u=rwX,g=rX,o= storage bootstrap/cache; \
    php -m | grep -qi 'zend opcache'

WORKDIR /var/www/html
USER www-data:www-data

EXPOSE 8080

STOPSIGNAL SIGTERM
ENTRYPOINT ["/usr/bin/tini", "--", "2fauth-entrypoint"]
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
