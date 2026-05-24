#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
site=$root/out/bitplane.net
port=${PORT:-8081}
name=${NAME:-posix-pages-bitplane}
image=${NGINX_IMAGE:-quay.io/nginx/nginx-unprivileged:stable-alpine}
conf=$root/out/nginx-bitplane.conf

if [ ! -d "$site" ]; then
    echo "missing site output: $site" >&2
    echo "build it first, for example:" >&2
    echo "  posix-pages build -s ~/src/bitplane.net -d out/bitplane.net" >&2
    exit 1
fi

cat > "$conf" <<'EOF'
server {
    listen 8080;
    server_name _;
    absolute_redirect off;
    port_in_redirect off;
    root /usr/share/nginx/html;
    index index.html;
    charset utf-8;
    charset_types text/html text/css text/plain application/javascript application/json application/xml;

    location ~ ^(.+[^/])$ {
        if (-d $request_filename) {
            return 301 $1/;
        }
        try_files $uri.html $uri =404;
    }

    location / {
        try_files $uri $uri/index.html =404;
    }
}
EOF

if podman container exists "$name" >/dev/null 2>&1; then
    podman rm -f "$name" >/dev/null
fi

podman run --rm --name "$name" \
    -p "127.0.0.1:$port:8080" \
    -v "$site:/usr/share/nginx/html:ro,Z" \
    -v "$conf:/etc/nginx/conf.d/default.conf:ro,Z" \
    "$image"
