# posix-pages

A small POSIX shell static site generator that wires together:

- `awkdown` for GitHub Flavored Markdown
- `awkyaml` for YAML front matter and config
- `awkuid` for Liquid templates

This is currently a vertical slice, not a complete GitHub Pages clone.

## Development

By default the build uses sibling repositories:

```sh
make test
```

Override tool paths when testing release artifacts:

```sh
make test AWKDOWN=./tools/awkdown AWKYAML=./tools/awkyaml AWKUID=./tools/awkuid
```

Or download the latest release assets first:

```sh
make tools
make test-tools
```

## Build A Site

```sh
AWKDOWN=../awkdown/build/awkdown \
AWKYAML=../awkyaml/build/awkyaml \
AWKUID=../awkuid/build/awkuid \
sh bin/posix-pages build -s path/to/site -d path/to/_site
```

Supported in this first pass:

- `_config.yml` as `site`
- page front matter as `page`
- Liquid rendering before Markdown
- `layout: name` via `_layouts/name.html`
- static file copying

## Preview bitplane.net

Build into `out/bitplane.net`, then serve it with nginx through Podman:

```sh
sh scripts/serve-bitplane.sh
```

Open `http://127.0.0.1:8081/`. Override the port with `PORT=...`.
Override the container image with `NGINX_IMAGE=...`; the default is the
unprivileged nginx image from Quay to avoid Docker Hub auth issues with Podman.
