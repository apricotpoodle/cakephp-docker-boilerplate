#!/usr/bin/env bash
set -Eeuo pipefail

php_service_name="$(printenv PHP_SERVICE_NAME || true)"
lock_file="$(printenv PHPUNIT_LOCK_FILE || true)"
if [ -z "$php_service_name" ]; then php_service_name=gdaetf; fi
if [ -z "$lock_file" ]; then lock_file=/tmp/daetf2-phpunit.lock; fi

exec 9>"$lock_file"
if ! flock -n 9; then
    echo "Une autre suite PHPUnit est déjà en cours." >&2
    exit 2
fi

cleanup_phpunit_processes() {
    docker compose exec -T -u www-data "$php_service_name" \
        sh -lc 'pkill -TERM -f "[v]endor/bin/phpunit" 2>/dev/null || true' \
        >/dev/null 2>&1 || true
}

cleanup_on_signal() {
    cleanup_phpunit_processes
    exit 130
}

cleanup_phpunit_processes
trap cleanup_phpunit_processes EXIT
trap cleanup_on_signal INT TERM

docker compose exec -T \
    -e XDEBUG_MODE=off \
    -e APP_DEFAULT_LOCALE=fr_FR \
    -u www-data \
    "$php_service_name" \
    ./vendor/bin/phpunit "$@"
