#!/bin/sh
set -eu

# These mirrored images ship explicit IPv6 listeners, which fail when the host
# boots with ipv6.disable=1. Preserve their IPv4 listeners and site settings.
sed -i '/^[[:space:]]*listen[[:space:]].*\[::\]/d' /etc/nginx/conf.d/*.conf
exec /docker-entrypoint.sh nginx -g 'daemon off;'
