#!/bin/sh
#
# 2FAuth production entrypoint.
#
# 1. Reads *_FILE secrets (Docker secrets), like the upstream image.
# 2. Refuses to start without APP_KEY.
# 3. Creates the SQLite file when DB_CONNECTION=sqlite.
# 4. Generates Passport keys into the storage volume on first start.
# 5. Runs migrations (and creates the Passport personal access client once)
#    when RUN_MIGRATIONS=true.
# 6. Warms Laravel's config, route, view and event caches.
# 7. Hands over to supervisord (nginx, PHP-FPM, scheduler).
set -eu

log() { echo "[2fauth] $*" >&2; }

file_env() {
    var="$1"; fileVar="${var}_FILE"
    eval "val=\${$var-}"; eval "file=\${$fileVar-}"
    if [ -n "$val" ] && [ -n "$file" ]; then
        log "both $var and $fileVar are set (but are exclusive)"; exit 1
    fi
    if [ -n "$file" ]; then
        [ -r "$file" ] || { log "cannot read $file"; exit 1; }
        export "$var=$(cat "$file")"
    fi
    unset "$fileVar"
}

for v in APP_KEY DB_DATABASE DB_USERNAME DB_PASSWORD DB_HOST MAIL_USERNAME MAIL_PASSWORD REDIS_PASSWORD; do
    file_env "$v"
done

if [ -z "${APP_KEY:-}" ]; then
    log "APP_KEY is not set. Use 32 random characters or: php artisan key:generate --show"
    exit 1
fi

cd /var/www/html

if [ "${DB_CONNECTION:-}" = "sqlite" ]; then
    : "${DB_DATABASE:=/var/www/html/storage/database/database.sqlite}"
    export DB_DATABASE
    case "$DB_DATABASE" in
        /var/www/html/storage/*) ;;
        *) log "warning: DB_DATABASE=$DB_DATABASE is outside the storage volume and will not persist" ;;
    esac
    if [ ! -f "$DB_DATABASE" ]; then
        log "creating SQLite database at $DB_DATABASE"
        mkdir -p "$(dirname "$DB_DATABASE")"
        touch "$DB_DATABASE"
    fi
fi

if [ ! -f storage/oauth-private.key ] || [ ! -f storage/oauth-public.key ]; then
    log "generating Passport keys in storage/"
    php artisan passport:keys --force --no-ansi
fi
php artisan 2fauth:fix-passport-key-permissions --no-ansi || log "warning: could not fix Passport key permissions"

if [ "${RUN_MIGRATIONS:-false}" = "true" ]; then
    php artisan migrate --force --no-ansi
    # Same personal access client 2fauth:install creates (needed for API tokens).
    if [ ! -f storage/.passport-client ]; then
        php artisan passport:client --personal --no-interaction --no-ansi \
            --name="${APP_NAME:-2FAuth}" --provider=users
        touch storage/.passport-client
    fi
fi

php artisan optimize --no-ansi

exec "$@"
