#!/bin/sh
set -eu

owner=${GITHUB_OWNER:-bitplane}
awkdown_release=${AWKDOWN_RELEASE:-latest}
awkyaml_release=${AWKYAML_RELEASE:-latest}
awkuid_release=${AWKUID_RELEASE:-latest}

mkdir -p tools

release_url() {
    repo=$1
    release=$2
    asset=$3
    if [ "$release" = latest ]; then
        printf 'https://github.com/%s/%s/releases/latest/download/%s\n' "$owner" "$repo" "$asset"
    else
        printf 'https://github.com/%s/%s/releases/download/%s/%s\n' "$owner" "$repo" "$release" "$asset"
    fi
}

download() {
    repo=$1
    release=$2
    asset=$3
    url=$(release_url "$repo" "$release" "$asset")
    checksum_url=$(release_url "$repo" "$release" "$asset.sha256")

    echo "fetch $repo@$release: $asset"
    curl -fsSL "$url" -o "tools/$asset"
    curl -fsSL "$checksum_url" -o "tools/$asset.sha256"
    chmod +x "tools/$asset"

    if command -v sha256sum >/dev/null 2>&1; then
        expected=$(awk '{ print $1; exit }' "tools/$asset.sha256")
        actual=$(sha256sum "tools/$asset" | awk '{ print $1; exit }')
        if [ "$expected" != "$actual" ]; then
            echo "checksum mismatch for $asset" >&2
            exit 1
        fi
    fi
}

download awkdown "$awkdown_release" awkdown
download awkyaml "$awkyaml_release" awkyaml
download awkuid "$awkuid_release" awkuid
