#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
tmp=$root/test/tmp/jekyll
awk_bin=${AWK:-awk}
awkdown=${AWKDOWN:-../awkdown/build/awkdown}
awkyaml=${AWKYAML:-../awkyaml/build/awkyaml}
awkuid=${AWKUID:-../awkuid/build/awkuid}

passed=0
failed=0

reset_case() {
    name=$1
    site=$tmp/$name/site
    out=$tmp/$name/_site
    rm -rf "$tmp/$name"
    mkdir -p "$site"
}

run_build() {
    AWK=$awk_bin AWKDOWN=$awkdown AWKYAML=$awkyaml AWKUID=$awkuid \
        sh "$root/bin/posix-pages" build -s "$site" -d "$out"
}

pass() {
    passed=$((passed + 1))
}

fail() {
    failed=$((failed + 1))
    echo "FAIL jekyll: $1" >&2
}

assert_file() {
    if [ ! -f "$1" ]; then
        fail "$case_name missing $1"
        return 1
    fi
    return 0
}

assert_no_file() {
    if [ -e "$1" ]; then
        fail "$case_name unexpected $1"
        return 1
    fi
    return 0
}

assert_contains() {
    file=$1
    needle=$2
    if ! grep -F "$needle" "$file" >/dev/null 2>&1; then
        fail "$case_name missing text in $file: $needle"
        return 1
    fi
    return 0
}

case_basic_site() {
    case_name="basic site"
    reset_case basic-site
    cat > "$site/index.html" <<'EOF'
Basic Site
EOF
    run_build
    assert_contains "$out/index.html" "Basic Site" && pass
}

case_page_with_layout() {
    case_name="page with layout"
    reset_case page-layout
    mkdir -p "$site/_layouts"
    cat > "$site/_layouts/default.html" <<'EOF'
Page Layout: {{ content }}
EOF
    cat > "$site/index.html" <<'EOF'
---
layout: default
---
Basic Site with Layout
EOF
    run_build
    assert_contains "$out/index.html" "Page Layout: Basic Site with Layout" && pass
}

case_default_layout() {
    case_name="default layout"
    reset_case default-layout
    mkdir -p "$site/_layouts"
    cat > "$site/_layouts/default.html" <<'EOF'
Default Layout: {{ page.title }} {{ page.url }} {{ content }}
EOF
    cat > "$site/index.md" <<'EOF'
# Uses Default
EOF
    run_build
    assert_contains "$out/index.html" "Default Layout: Uses Default / <h1 id=\"uses-default\">Uses Default</h1>" && pass
}

case_markdown_page_with_layout() {
    case_name="markdown page with layout"
    reset_case markdown-layout
    mkdir -p "$site/_layouts"
    cat > "$site/_layouts/default.html" <<'EOF'
Page {{ page.title }}: {{ content }}
EOF
    cat > "$site/index.md" <<'EOF'
---
layout: default
title: Home
---
# Hello
EOF
    run_build
    assert_contains "$out/index.html" "Page Home: <h1 id=\"hello\">Hello</h1>" && pass
}

case_markdown_without_front_matter() {
    case_name="markdown without front matter"
    reset_case markdown-without-front-matter
    cat > "$site/index.md" <<'EOF'
# Basic Markdown Site
EOF
    run_build
    assert_contains "$out/index.html" "<h1 id=\"basic-markdown-site\">Basic Markdown Site</h1>" && pass
}

case_basic_post() {
    case_name="basic post"
    reset_case basic-post
    mkdir -p "$site/_posts"
    cat > "$site/_posts/2009-03-27-hackers.md" <<'EOF'
---
title: Hackers
---
My First Exploit
EOF
    run_build
    assert_contains "$out/2009/03/27/hackers.html" "<p>My First Exploit</p>" && pass
}

case_post_with_layout() {
    case_name="post with layout"
    reset_case post-layout
    mkdir -p "$site/_layouts" "$site/_posts"
    cat > "$site/_layouts/post.html" <<'EOF'
Post {{ page.title }}: {{ content }}
EOF
    cat > "$site/_posts/2009-03-27-wargames.md" <<'EOF'
---
title: Wargames
layout: post
---
The only winning move is not to play.
EOF
    run_build
    assert_contains "$out/2009/03/27/wargames.html" "Post Wargames: <p>The only winning move is not to play.</p>" && pass
}

case_pages_posts_counts() {
    case_name="pages and posts counts"
    reset_case pages-posts-counts
    mkdir -p "$site/_layouts" "$site/_posts" "$site/blog" "$site/category/_posts"
    cat > "$site/_layouts/page.html" <<'EOF'
Page {{ page.title }}: {{ content }}
EOF
    cat > "$site/_layouts/post.html" <<'EOF'
Post {{ page.title }}: {{ content }}
EOF
    cat > "$site/index.html" <<'EOF'
---
layout: page
---
Site contains {{ site.pages.size }} pages and {{ site.posts.size }} posts
EOF
    cat > "$site/blog/index.html" <<'EOF'
---
layout: page
---
blog category index page
EOF
    cat > "$site/_posts/2009-03-27-entry1.md" <<'EOF'
---
title: entry1
layout: post
---
content for entry1.
EOF
    cat > "$site/_posts/2009-04-27-entry2.md" <<'EOF'
---
title: entry2
layout: post
---
content for entry2.
EOF
    cat > "$site/category/_posts/2009-05-27-entry3.md" <<'EOF'
---
title: entry3
layout: post
---
content for entry3.
EOF
    cat > "$site/category/_posts/2009-06-27-entry4.md" <<'EOF'
---
title: entry4
layout: post
---
content for entry4.
EOF
    run_build
    ok=1
    assert_contains "$out/index.html" "Site contains 2 pages and 4 posts" || ok=0
    assert_contains "$out/blog/index.html" "blog category index page" || ok=0
    assert_contains "$out/2009/03/27/entry1.html" "Post entry1: <p>content for entry1.</p>" || ok=0
    assert_contains "$out/category/2009/05/27/entry3.html" "Post entry3: <p>content for entry3.</p>" || ok=0
    [ "$ok" -eq 1 ] && pass
}

case_static_files() {
    case_name="static files"
    reset_case static-files
    cat > "$site/about.html" <<'EOF'
No replacement {{ site.posts.size }}
EOF
    cat > "$site/another_file" <<'EOF'
plain
EOF
    run_build
    ok=1
    assert_contains "$out/about.html" 'No replacement {{ site.posts.size }}' || ok=0
    assert_contains "$out/another_file" "plain" || ok=0
    [ "$ok" -eq 1 ] && pass
}

case_include_relative() {
    case_name="include relative"
    reset_case include-relative
    cat > "$site/_log.md" <<'EOF'
Included **Markdown**
EOF
    cat > "$site/index.md" <<'EOF'
# Home

{% include_relative _log.md %}
EOF
    run_build
    assert_contains "$out/index.html" "<p>Included <strong>Markdown</strong></p>" && pass
}

case_layout_preserves_softbreaks() {
    case_name="layout preserves softbreaks"
    reset_case layout-preserves-softbreaks
    mkdir -p "$site/_layouts"
    cat > "$site/_layouts/default.html" <<'EOF'
{{ content }}
EOF
    cat > "$site/index.md" <<'EOF'
Get the code for particle systems, billboards and the generator tool
[here](https://example.com/)
EOF
    run_build
    assert_contains "$out/index.html" "generator tool
<a href=\"https://example.com/\">here</a>" && pass
}

case_unpublished_page() {
    case_name="unpublished page"
    reset_case unpublished-page
    cat > "$site/index.html" <<'EOF'
---
title: index
---
Published page
EOF
    cat > "$site/secret.html" <<'EOF'
---
published: false
---
Unpublished page
EOF
    run_build
    ok=1
    assert_file "$out/index.html" || ok=0
    assert_no_file "$out/secret.html" || ok=0
    [ "$ok" -eq 1 ] && pass
}

rm -rf "$tmp"

case_basic_site
case_page_with_layout
case_default_layout
case_markdown_page_with_layout
case_markdown_without_front_matter
case_basic_post
case_post_with_layout
case_pages_posts_counts
case_static_files
case_include_relative
case_layout_preserves_softbreaks
case_unpublished_page

echo "jekyll: $passed passed, $failed failed"
[ "$failed" -eq 0 ]
