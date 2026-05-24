#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
tmp=$root/test/tmp
site=$tmp/site
out=$tmp/_site

rm -rf "$tmp"
mkdir -p "$site/_layouts" "$site/_includes"

cat > "$site/_config.yml" <<'EOF'
title: POSIX Pages
EOF

cat > "$site/_includes/name.liquid" <<'EOF'
{{ include.name }}
EOF

cat > "$site/_layouts/default.html" <<'EOF'
<!doctype html>
<title>{{ page.title }} - {{ site.title }}</title>
<main>{{ content }}</main>
EOF

cat > "$site/index.md" <<'EOF'
---
layout: default
title: Home
---
# {{ page.title }}

Welcome to {{ site.title }}.
EOF

cat > "$site/about.html" <<'EOF'
---
layout: default
title: About
---
<p>{{ site.title }}</p>
EOF

cat > "$site/style.css" <<'EOF'
body { color: black; }
EOF

AWK=${AWK:-awk} AWKDOWN=${AWKDOWN:-../awkdown/build/awkdown} AWKYAML=${AWKYAML:-../awkyaml/build/awkyaml} AWKUID=${AWKUID:-../awkuid/build/awkuid} \
    sh "$root/bin/posix-pages" build -s "$site" -d "$out"

fail=0

assert_file() {
    if [ ! -f "$1" ]; then
        echo "missing: $1" >&2
        fail=1
    fi
}

assert_contains() {
    file=$1
    needle=$2
    if ! grep -F "$needle" "$file" >/dev/null 2>&1; then
        echo "missing text in $file: $needle" >&2
        fail=1
    fi
}

assert_file "$out/index.html"
assert_file "$out/about.html"
assert_file "$out/style.css"
assert_contains "$out/index.html" "<title>Home - POSIX Pages</title>"
assert_contains "$out/index.html" "<h1 id=\"home\">Home</h1>"
assert_contains "$out/index.html" "<p>Welcome to POSIX Pages.</p>"
assert_contains "$out/about.html" "<p>POSIX Pages</p>"
assert_contains "$out/style.css" "body { color: black; }"

if [ "$fail" -eq 0 ]; then
    echo "smoke: 1 passed, 0 failed"
fi
exit "$fail"
